import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../storage/secure_storage_provider.dart';

final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:3000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // Окремий інстанс Dio для оновлення токена, щоб не викликати нескінченний цикл interceptors
  final refreshDio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000'));

  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(currentTokenProvider);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Глобальна обробка Rate Limits
        if (e.response?.statusCode == 429) {
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: 'Забагато запитів. Зачекайте хвилину',
              type: DioExceptionType.badResponse,
            ),
          );
        }

        // Обробка протухшого токена
        if (e.response?.statusCode == 401 && e.requestOptions.path != '/auth/login' && e.requestOptions.path != '/auth/refresh') {
          final storage = ref.read(secureStorageProvider);
          final refreshToken = await storage.read(key: 'refresh_token');

          if (refreshToken != null) {
            try {
              final refreshResponse = await refreshDio.post('/auth/refresh', data: {
                'refreshToken': refreshToken,
              });

              final newAccessToken = refreshResponse.data['accessToken'] as String;
              final newRefreshToken = refreshResponse.data['refreshToken'] as String;

              await storage.write(key: 'jwt_token', value: newAccessToken);
              await storage.write(key: 'refresh_token', value: newRefreshToken);
              ref.read(currentTokenProvider.notifier).state = newAccessToken;

              // Повторюємо оригінальний запит
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await dio.fetch(e.requestOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
              // Якщо refresh теж повернув помилку (наприклад 401)
              ref.read(authStateProvider.notifier).logout();
              return handler.next(e);
            }
          } else {
            ref.read(authStateProvider.notifier).logout();
          }
        }
        return handler.next(e);
      },
    ),
  );

  dio.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    requestBody: false, // Не логуємо тіло, щоб консоль не зависла від байтів картинки
    responseHeader: false,
    responseBody: true,
    error: true,
  ));

  return dio;
});