import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dsns_hub/core/network/dio_provider.dart';

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, String>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      return {
        'accessToken': response.data['accessToken'] as String,
        'refreshToken': response.data['refreshToken'] as String,
      };
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 403) {
          throw Exception('Ваш обліковий запис заблоковано. Зверніться до адміністратора');
        }
        if (e.response?.statusCode == 429) {
          throw Exception('Забагато запитів. Зачекайте хвилину');
        }
        final data = e.response?.data;
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

  Future<void> logout(String accessToken) async {
    try {
      await _dio.post(
        '/auth/logout',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } catch (_) {
      // Ігноруємо помилки при логауті (наприклад, якщо токен вже недійсний)
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? departmentId,
  }) async {
    try {
      await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          if (departmentId != null) 'departmentId': departmentId,
        },
      );
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 429) {
          throw Exception('Перевищено ліміт спроб реєстрації. Зачекайте хвилину.');
        }
        if (e.response?.statusCode == 403) {
          throw Exception('Відмова в реєстрації: некоректний email або користувач вже існує.');
        }
        final data = e.response?.data;
        final message = (data is Map && data['message'] != null)
            ? (data['message'] is List ? data['message'].join('\n') : data['message'])
            : 'Помилка валідації введених даних.';
        
        throw Exception(message.toString());
      }
      throw Exception('Помилка з\'єднання з сервером');
    } catch (e) {
      throw Exception('Невідома помилка: $e');
    }
  }
}