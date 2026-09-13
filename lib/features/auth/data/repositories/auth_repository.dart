import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dsns_hub/core/network/dio_provider.dart';

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.forcePasswordChange = false,
  });

  final String accessToken;
  final String refreshToken;
  final bool forcePasswordChange;
}

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<AuthSession> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final user = response.data['user'];
      return AuthSession(
        accessToken: response.data['accessToken'] as String,
        refreshToken: response.data['refreshToken'] as String,
        forcePasswordChange: user is Map && user['forcePasswordChange'] == true,
      );
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

  Future<bool> fetchForcePasswordChange() async {
    final response = await _dio.get('/users/me');
    final data = response.data;
    return data is Map && data['forcePasswordChange'] == true;
  }

  Future<Map<String, String>> refresh(String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = response.data;
    if (data is! Map) {
      throw Exception('Не вдалося оновити сесію');
    }
    final accessToken = data['accessToken'];
    final newRefreshToken = data['refreshToken'];
    if (accessToken is! String ||
        newRefreshToken is! String ||
        accessToken.isEmpty ||
        newRefreshToken.isEmpty) {
      throw Exception('Не вдалося оновити сесію');
    }
    return {
      'accessToken': accessToken,
      'refreshToken': newRefreshToken,
    };
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

  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _dio.patch(
        '/auth/session/fcm-token',
        data: {'fcmToken': fcmToken},
      );
    } catch (_) {
      // Ігноруємо помилку, щоб не блокувати UI, якщо токен не оновився
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
          'departmentId': ?departmentId,
        },
      );
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 429) {
          throw Exception('Перевищено ліміт спроб реєстрації. Зачекайте хвилину.');
        }
        if (e.response?.statusCode == 403) {
          final data = e.response?.data;
          final message = (data is Map && data['message'] != null)
              ? data['message'].toString()
              : 'Відмова в реєстрації: некоректний email або користувач вже існує.';
          throw Exception(message);
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