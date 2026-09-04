import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../security/app_lock_provider.dart';
import '../../security/biometric_service.dart';

class AppLockOverlay extends ConsumerStatefulWidget {
  const AppLockOverlay({super.key});

  @override
  ConsumerState<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends ConsumerState<AppLockOverlay> {
  IconData _biometricIcon = Icons.fingerprint;

  @override
  void initState() {
    super.initState();
    _loadBiometricIcon();
    // Пробуємо автоматично розблокувати при появі екрану
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(appLockProvider)) {
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
    final success = await BiometricService.authenticate();
    if (success && mounted) {
      ref.read(appLockProvider.notifier).unlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockProvider);
    if (!isLocked) return const SizedBox.shrink();

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
                onPressed: _attemptUnlock,
                icon: Icon(_biometricIcon, size: 28),
                label: const Text('РОЗБЛОКУВАТИ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}