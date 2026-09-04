import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';

final appLockProvider = StateNotifierProvider<AppLockNotifier, bool>((ref) {
  return AppLockNotifier(ref);
});

class AppLockNotifier extends StateNotifier<bool> {
  final Ref _ref;
  DateTime? _backgroundTime;
  final _lockTimeout = const Duration(minutes: 2); // Автоблокування через 2 хвилини

  AppLockNotifier(this._ref) : super(false) {
    _initializeLock();
  }

  void _initializeLock() {
    // Блокуємо додаток на старті, якщо користувач вже авторизований (холодний старт)
    Future.microtask(() {
      final token = _ref.read(currentTokenProvider);
      if (token != null && token.isNotEmpty) {
        state = true;
      }
    });
  }

  void onPaused() {
    _backgroundTime = DateTime.now();
  }

  void onResumed() {
    if (_backgroundTime != null) {
      final diff = DateTime.now().difference(_backgroundTime!);
      if (diff >= _lockTimeout) {
        state = true;
      }
      _backgroundTime = null;
    }
  }

  void unlock() {
    state = false;
  }
}