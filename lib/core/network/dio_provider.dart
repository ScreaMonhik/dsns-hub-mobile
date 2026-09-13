import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../config/app_config.dart';
import '../config/maintenance.dart';
import '../security/certificate_pinning.dart';
import '../storage/secure_storage_provider.dart';

const _retriedExtraKey = 'dsns_retried';

final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  // Окремий інстанс Dio для оновлення токена, щоб не викликати нескінченний цикл interceptors
  final refreshDio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

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
        if (isMaintenanceResponse(e)) {
          MaintenanceStore.instance.apply(
            enabled: true,
            message: maintenanceMessageFromError(e),
          );
          return handler.next(e);
        }

        final errorCode = e.response?.data is Map ? e.response?.data['code'] : null;
        if (e.response?.statusCode == 403 && errorCode == 'FORCE_PASSWORD_CHANGE') {
          ref.read(authStateProvider.notifier).setForcePasswordChange(true);
          return handler.next(e);
        }

        if (e.response?.statusCode == 429) {
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: 'Забагато запитів. Зачекайте хвилину',
              type: DioExceptionType.badResponse,
            ),
          );
        }

        final path = e.requestOptions.path;
        final alreadyRetried = e.requestOptions.extra[_retriedExtraKey] == true;
        final isAuthPath = path == '/auth/login' || path == '/auth/refresh';

        if (e.response?.statusCode == 401 && !isAuthPath && !alreadyRetried) {
          final storage = ref.read(secureStorageProvider);
          final refreshToken = await storage.read(key: 'refresh_token');

          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final refreshResponse = await refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
              );

              final data = refreshResponse.data;
              if (data is! Map) {
                throw StateError('Invalid refresh payload');
              }
              final newAccessToken = data['accessToken'];
              final newRefreshToken = data['refreshToken'];
              if (newAccessToken is! String ||
                  newRefreshToken is! String ||
                  newAccessToken.isEmpty ||
                  newRefreshToken.isEmpty) {
                throw StateError('Invalid refresh tokens');
              }

              await storage.write(key: 'jwt_token', value: newAccessToken);
              await storage.write(key: 'refresh_token', value: newRefreshToken);
              ref.read(currentTokenProvider.notifier).state = newAccessToken;

              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              e.requestOptions.extra[_retriedExtraKey] = true;
              final retryResponse = await dio.fetch(e.requestOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
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

  applyCertificatePinning(dio);
  applyCertificatePinning(refreshDio);

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
      ),
    );
  }

  return dio;
});
