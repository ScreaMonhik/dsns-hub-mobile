import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';

final appLockProvider = StateNotifierProvider<AppLockNotifier, bool>((ref) {
  return AppLockNotifier(ref);
});

class AppLockNotifier extends StateNotifier<bool> {
  final Ref _ref;
  DateTime? _backgroundTime;
  final _lockTimeout = const Duration(minutes: 2);

  AppLockNotifier(this._ref) : super(false) {
    _initializeLock();
    _ref.listen<String?>(currentTokenProvider, (previous, next) {
      if (next == null || next.isEmpty) {
        state = false;
        _backgroundTime = null;
      }
    });
  }

  void _initializeLock() {
    Future.microtask(() {
      final token = _ref.read(currentTokenProvider);
      if (token != null && token.isNotEmpty) {
        state = true;
      }
    });
  }

  void onPaused() {
    if (_ref.read(currentTokenProvider)?.isNotEmpty == true) {
      _backgroundTime = DateTime.now();
    }
  }

  void onResumed() {
    if (_backgroundTime != null) {
      final diff = DateTime.now().difference(_backgroundTime!);
      if (diff >= _lockTimeout && _ref.read(currentTokenProvider)?.isNotEmpty == true) {
        state = true;
      }
      _backgroundTime = null;
    }
  }

  void unlock() {
    state = false;
  }
}
