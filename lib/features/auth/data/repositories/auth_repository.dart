import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dsns_hub/core/network/dio_provider.dart';

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<String> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      return response.data['accessToken'] as String;
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        // Намагаємось дістати повідомлення про помилку від бекенду (напр. NestJS)
        final message = (data is Map && data['message'] != null)
            ? (data['message'] is List ? data['message'][0] : data['message'])
            : 'Неправильний email або пароль';
        
        throw Exception(message.toString());
      }
      throw Exception('Помилка з\'єднання з сервером');
    } catch (e) {
      throw Exception('Невідома помилка: $e');
    }
  }
}