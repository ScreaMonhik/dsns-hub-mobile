import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/security/device_integrity.dart';
import '../../../core/security/jwt_utils.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/services/notification_service.dart';
import '../data/repositories/auth_repository.dart';

final currentTokenProvider = StateProvider<String?>((ref) => null);

final forcePasswordChangeProvider = StateProvider<bool>((ref) => false);

final currentUserIdProvider = Provider<String?>((ref) {
  final token = ref.watch(currentTokenProvider);
  if (token == null || token.isEmpty) return null;
  return JwtUtils.userId(token);
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

  Future<void> _syncForcePasswordFlag() async {
    try {
      final force = await _repository.fetchForcePasswordChange();
      await setForcePasswordChange(force);
    } catch (_) {}
  }

  void _syncFcmTokenIfAllowed() {
    if (_ref.read(forcePasswordChangeProvider)) {
      return;
    }
    _syncFcmToken();
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

  Future<void> _persistTokens(
    String accessToken,
    String refreshToken, {
    bool? forcePasswordChange,
  }) async {
    await _storage.write(key: 'jwt_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    if (forcePasswordChange != null) {
      await setForcePasswordChange(forcePasswordChange);
    }
    _ref.read(currentTokenProvider.notifier).state = accessToken;
  }

  Future<void> setForcePasswordChange(bool value) async {
    await _storage.write(key: 'force_password_change', value: value ? '1' : '0');
    _ref.read(forcePasswordChangeProvider.notifier).state = value;
  }

  Future<void> _clearSessionKeys() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'force_password_change');
    await _storage.delete(key: 'biometric_email');
    await _storage.delete(key: 'biometric_password');
    _ref.read(forcePasswordChangeProvider.notifier).state = false;
  }

  Future<bool> _refreshSession(String refreshToken) async {
    try {
      final tokens = await _repository.refresh(refreshToken);
      await _persistTokens(tokens['accessToken']!, tokens['refreshToken']!);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkToken() async {
    try {
      if (DeviceIntegrity.instance.isCompromised) {
        await DeviceIntegrity.instance.wipeTokens();
        _ref.read(currentTokenProvider.notifier).state = null;
        state = const AsyncValue.data(false);
        return;
      }

      await _storage.delete(key: 'biometric_password');

      final token = await _storage.read(key: 'jwt_token');

      if (token != null && token.isNotEmpty && !JwtUtils.isExpired(token)) {
        _ref.read(currentTokenProvider.notifier).state = token;
        final forceFlag = await _storage.read(key: 'force_password_change');
        _ref.read(forcePasswordChangeProvider.notifier).state = forceFlag == '1';
        state = const AsyncValue.data(true);
        _syncForcePasswordFlag();
        _syncFcmTokenIfAllowed();
        return;
      }

      // Access протух — на логін. Refresh лишаємо для входу через Face ID / Touch ID.
      if (token != null && token.isNotEmpty) {
        await _storage.delete(key: 'jwt_token');
      }

      _ref.read(currentTokenProvider.notifier).state = null;
      state = const AsyncValue.data(false);
    } catch (_) {
      _ref.read(currentTokenProvider.notifier).state = null;
      state = const AsyncValue.data(false);
    }
  }

  Future<void> login(String email, String password) async {
    if (DeviceIntegrity.instance.isCompromised) {
      state = AsyncValue.error(
        Exception('Пристрій скомпрометовано. Вхід заборонено.'),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncValue.loading();
    try {
      final session = await _repository.login(email, password);
      await _persistTokens(
        session.accessToken,
        session.refreshToken,
        forcePasswordChange: session.forcePasswordChange,
      );
      await _storage.write(key: 'biometric_email', value: email.trim());
      await _storage.delete(key: 'biometric_password');
      state = const AsyncValue.data(true);
      _syncFcmTokenIfAllowed();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginWithBiometrics() async {
    if (DeviceIntegrity.instance.isCompromised) {
      throw Exception('Пристрій скомпрометовано. Вхід заборонено.');
    }
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('Збереженої сесії немає. Увійдіть за паролем');
    }

    final confirmed = await BiometricService.authenticate(
      biometricOnly: true,
      localizedReason: 'Увійдіть у DSNS Hub за допомогою біометрії',
    );
    if (!confirmed) return;

    state = const AsyncValue.loading();
    try {
      final refreshed = await _refreshSession(refreshToken);
      if (!refreshed) {
        await _storage.delete(key: 'refresh_token');
        throw Exception('Сесія закінчилась. Увійдіть за паролем');
      }
      state = const AsyncValue.data(true);
      _syncForcePasswordFlag();
      _syncFcmTokenIfAllowed();
    } catch (e, st) {
      _ref.read(currentTokenProvider.notifier).state = null;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        await _repository.logout(token);
      }
    } catch (_) {
      // Ігноруємо мережеві помилки логауту
    }
    try {
      await _clearSessionKeys();
    } catch (_) {
      // Ігноруємо системні краші стораджа
    }
    _fcmTokenSub?.cancel();
    _fcmTokenSub = null;
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

class BiometricLoginOffer {
  const BiometricLoginOffer({
    required this.available,
    this.email,
  });

  final bool available;
  final String? email;
}

final biometricLoginOfferProvider = FutureProvider<BiometricLoginOffer>((ref) async {
  ref.watch(authStateProvider);

  final storage = ref.read(secureStorageProvider);
  final refreshToken = await storage.read(key: 'refresh_token');
  final email = await storage.read(key: 'biometric_email');
  final canUseBiometrics = await BiometricService.isBiometricLoginAvailable();

  return BiometricLoginOffer(
    available: canUseBiometrics && refreshToken != null && refreshToken.isNotEmpty,
    email: email,
  );
});

