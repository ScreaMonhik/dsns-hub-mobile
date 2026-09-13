import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../core/providers/cache_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../widgets/change_password_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cacheState = ref.watch(cacheProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Налаштування')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Оформлення',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('Системна')),
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Світла')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Темна')),
            ],
            selected: {ref.watch(themeProvider)},
            onSelectionChanged: (selection) {
              ref.read(themeProvider.notifier).setTheme(selection.first);
            },
          ),
          const SizedBox(height: 28),
          Text(
            'Сповіщення',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.notifications_outlined, color: theme.colorScheme.primary),
            title: const Text('Налаштування сповіщень'),
            subtitle: const Text('Новини, опитування, документи та чати'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/settings/notifications'),
          ),
          const SizedBox(height: 16),
          Text(
            'Дані',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: cacheState.isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.onSurfaceVariant),
            title: const Text('Очистити кеш'),
            subtitle: Text(
              cacheState.when(
                data: (size) => 'Тимчасові файли та відповіді API ($size)',
                loading: () => 'Обчислення...',
                error: (_, __) => 'Не вдалося оцінити розмір',
              ),
            ),
            onTap: cacheState.isLoading
                ? null
                : () async {
                    await ref.read(cacheProvider.notifier).clearCache();
                    if (context.mounted) {
                      AppSnackBar.showSuccess(context, 'Кеш очищено');
                    }
                  },
          ),
          const SizedBox(height: 16),
          Text(
            'Безпека',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.lock_reset, color: theme.colorScheme.primary),
            title: const Text('Змінити пароль'),
            subtitle: const Text('Оновлення пароля облікового запису'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showChangePasswordSheet(context),
          ),
        ],
      ),
    );
  }
}
