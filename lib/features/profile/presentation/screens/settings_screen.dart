import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/utils/app_snackbar.dart';
import '../../../../core/providers/cache_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../widgets/change_password_sheet.dart';
import '../../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _passwordSheetOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _passwordSheetOpened || !ref.read(forcePasswordChangeProvider)) {
        return;
      }
      _passwordSheetOpened = true;
      showChangePasswordSheet(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cacheState = ref.watch(cacheProvider);
    final forcePasswordChange = ref.watch(forcePasswordChangeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Налаштування')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (forcePasswordChange) ...[
            Card(
              color: theme.colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(Icons.warning_amber, color: theme.colorScheme.onErrorContainer),
                title: Text(
                  'Потрібно змінити тимчасовий пароль',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
                subtitle: Text(
                  'Інші розділи будуть доступні після оновлення пароля.',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
                onTap: () => showChangePasswordSheet(context),
              ),
            ),
            const SizedBox(height: 20),
          ],
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
            onTap: forcePasswordChange ? null : () => context.push('/profile/settings/notifications'),
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
                error: (_, _) => 'Не вдалося оцінити розмір',
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
