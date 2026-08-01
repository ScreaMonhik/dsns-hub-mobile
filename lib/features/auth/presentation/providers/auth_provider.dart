import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_provider.dart';

enum AuthState { initial, authenticated, unauthenticated }

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(AuthState.initial) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: 'jwt');
    
    if (token != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  Future<void> loginUser(String token) async {
    final storage = _ref.read(secureStorageProvider);
    await storage.write(key: 'jwt', value: token);
    state = AuthState.authenticated;
  }

  Future<void> logout() async {
    final storage = _ref.read(secureStorageProvider);
    await storage.delete(key: 'jwt');
    state = AuthState.unauthenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});