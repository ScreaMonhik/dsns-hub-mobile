import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../security/app_lock_provider.dart';
import '../../security/biometric_service.dart';

class AppLockOverlay extends ConsumerStatefulWidget {
  const AppLockOverlay({super.key});

  @override
  ConsumerState<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends ConsumerState<AppLockOverlay> {
  IconData _biometricIcon = Icons.fingerprint;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricIcon();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(appLockProvider) && ref.read(currentTokenProvider)?.isNotEmpty == true) {
        _attemptUnlock();
      }
    });
  }

  Future<void> _loadBiometricIcon() async {
    final icon = await BiometricService.getBiometricIcon();
    if (mounted) {
      setState(() {
        _biometricIcon = icon;
      });
    }
  }

  Future<void> _attemptUnlock() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    try {
      final success = await BiometricService.authenticate();
      if (success && mounted) {
        ref.read(appLockProvider.notifier).unlock();
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockProvider);
    final hasSession = ref.watch(currentTokenProvider)?.isNotEmpty == true;
    if (!isLocked || !hasSession) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Positioned.fill(
      child: Material(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Додаток заблоковано',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'В цілях безпеки сесію було призупинено',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: _isAuthenticating ? null : _attemptUnlock,
                icon: Icon(_biometricIcon, size: 28),
                label: const Text('РОЗБЛОКУВАТИ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isAuthenticating
                    ? null
                    : () => ref.read(authStateProvider.notifier).logout(),
                child: Text(
                  'Вийти з акаунта',
                  style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
