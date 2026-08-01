import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dsns_hub/features/auth/providers/auth_provider.dart';

// Provider for Secure Storage
final Provider<FlutterSecureStorage> secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:3000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  final secureStorage = ref.read(secureStorageProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // УВАГА: Переконайтеся, що ключ 'jwt_token' збігається з тим, 
        // який ви використовуєте при збереженні токена під час логіну!
        final token = await secureStorage.read(key: 'jwt_token');

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Автоматичний логаут при простроченому або недійсному токені
          ref.read(authStateProvider.notifier).logout();
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});