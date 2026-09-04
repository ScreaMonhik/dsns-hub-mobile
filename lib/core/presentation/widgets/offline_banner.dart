import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../providers/connectivity_provider.dart';

class GlobalOfflineBanner extends ConsumerWidget {
  const GlobalOfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityProvider);

    return connectivityState.when(
      data: (results) {
        final isOffline = results.contains(ConnectivityResult.none) || results.isEmpty;
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isOffline
              ? Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: const SafeArea(
                    bottom: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Відсутнє підключення до мережі',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}