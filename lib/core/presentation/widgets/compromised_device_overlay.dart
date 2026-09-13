import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../security/device_integrity.dart';

final deviceIntegrityProvider = ChangeNotifierProvider<DeviceIntegrity>((ref) {
  return DeviceIntegrity.instance;
});

class CompromisedDeviceOverlay extends ConsumerWidget {
  const CompromisedDeviceOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compromised = ref.watch(deviceIntegrityProvider).isCompromised;
    if (!compromised) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Positioned.fill(
      child: Material(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gpp_bad_outlined, size: 80, color: theme.colorScheme.error),
                const SizedBox(height: 24),
                Text(
                  'Пристрій скомпрометовано',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  'Виявлено root, jailbreak або інші ознаки втручання. Сесію видалено, вхід заблоковано.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
