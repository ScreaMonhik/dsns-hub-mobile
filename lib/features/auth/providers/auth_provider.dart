import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/services/notification_service.dart';
import '../data/repositories/auth_repository.dart';

final currentTokenProvider = StateProvider<String?>((ref) => null);

final currentUserIdProvider = Provider<String?>((ref) {
  final token = ref.watch(currentTokenProvider);
  if (token == null || token.isEmpty) return null;
  
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    
    final payload = base64Url.normalize(parts[1]);
    final decoded = json.decode(utf8.decode(base64Url.decode(payload)));
    
    return decoded['id'] ?? decoded['sub']; 
  } catch (e) {
    return null;
  }
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(secureStorageProvider),
    ref,
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final AuthRepository _repository;
  final FlutterSecureStorage _storage;
  final Ref _ref;

  AuthNotifier(this._repository, this._storage, this._ref) : super(const AsyncValue.loading()) {
    _checkToken();
  }

  StreamSubscription<String>? _fcmTokenSub;

  @override
  void dispose() {
    _fcmTokenSub?.cancel();
    super.dispose();
  }

  Future<void> _syncFcmToken() async {
    try {
      final notificationService = _ref.read(notificationServiceProvider);
      await notificationService.requestPermission();
      
      final token = await notificationService.getToken();
      if (token != null) {
        await _repository.updateFcmToken(token);
      }

      _fcmTokenSub?.cancel();
      _fcmTokenSub = notificationService.onTokenRefresh.listen((newToken) {
        _repository.updateFcmToken(newToken);
      });
    } catch (_) {}
  }

  Future<void> _checkToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null && token.isNotEmpty) {
      _ref.read(currentTokenProvider.notifier).state = token;
      state = const AsyncValue.data(true);
      _syncFcmToken();
    } else {
      state = const AsyncValue.data(false);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final tokens = await _repository.login(email, password);
      await _storage.write(key: 'jwt_token', value: tokens['accessToken']);
      await _storage.write(key: 'refresh_token', value: tokens['refreshToken']);
      
      // Зберігаємо облікові дані для біометричного входу
      await _storage.write(key: 'biometric_email', value: email);
      await _storage.write(key: 'biometric_password', value: password);

      _ref.read(currentTokenProvider.notifier).state = tokens['accessToken'];
      state = const AsyncValue.data(true);
      _syncFcmToken();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        await _repository.logout(token);
      }
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'refresh_token');
    } catch (_) {
      // Ігноруємо системні краші стораджа
    }
    _ref.read(currentTokenProvider.notifier).state = null;
    state = const AsyncValue.data(false);
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? departmentId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        departmentId: departmentId,
      );
      state = const AsyncValue.data(false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}