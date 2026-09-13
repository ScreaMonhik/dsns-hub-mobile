import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/utils/app_snackbar.dart';
import '../../data/repositories/profile_repository.dart';
import '../../providers/profile_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Налаштування сповіщень')),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Дані відсутні'));
          }

          Future<void> update(NotificationPreferences prefs) async {
            try {
              await ref.read(profileProvider.notifier).updateNotificationPrefs(prefs);
            } catch (e) {
              if (context.mounted) {
                AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Оберіть лише ті події, про які хочете отримувати push. Тривоги ДСНС завжди доставляються.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text('Новини', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Нові публікації'),
                subtitle: const Text('Push, коли з’являється новина'),
                value: profile.notifyNews,
                onChanged: (value) => update(NotificationPreferences(notifyNews: value)),
              ),
              const SizedBox(height: 12),
              Text('Опитування', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Нові опитування'),
                subtitle: const Text('Коли публікують нове опитування'),
                value: profile.notifyPolls,
                onChanged: (value) => update(NotificationPreferences(notifyPolls: value)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Дедлайни опитувань'),
                subtitle: const Text('Нагадування перед завершенням'),
                value: profile.notifyPollDeadlines,
                onChanged: (value) => update(NotificationPreferences(notifyPollDeadlines: value)),
              ),
              const SizedBox(height: 12),
              Text('Документи та проєкти', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Нові документи'),
                subtitle: const Text('Оновлення бібліотеки документів'),
                value: profile.notifyDocuments,
                onChanged: (value) => update(NotificationPreferences(notifyDocuments: value)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Нові проєкти'),
                subtitle: const Text('Коли з’являється новий проєкт'),
                value: profile.notifyProjects,
                onChanged: (value) => update(NotificationPreferences(notifyProjects: value)),
              ),
              const SizedBox(height: 12),
              Text('Чати', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Повідомлення в чатах'),
                subtitle: const Text('Push про нові повідомлення'),
                value: profile.notifyChats,
                onChanged: (value) => update(NotificationPreferences(notifyChats: value)),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Помилка: $err')),
      ),
    );
  }
}
