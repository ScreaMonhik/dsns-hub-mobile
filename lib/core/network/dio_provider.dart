import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';

final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:3000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      // Ніяких хардкодних contentType! Dio сам розбереться з FormData
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(currentTokenProvider);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401 && e.requestOptions.path != '/auth/login') {
          ref.read(authStateProvider.notifier).logout();
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