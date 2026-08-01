import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/chat_providers.dart';
import '../../../../core/presentation/widgets/auth_network_image.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsState = ref.watch(chatsListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Чати', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: chatsState.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(child: Text('У вас ще немає чатів'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(chatsListProvider),
            child: ListView.separated(
              itemCount: groups.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final group = groups[index];
                final lastMsg = group.messages.isNotEmpty ? group.messages.first : null;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: group.avatarUrl != null
                        ? ClipOval(
                            child: AuthNetworkImage(
                              imageUrl: group.avatarUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(group.name[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: lastMsg != null
                      ? Text(
                          lastMsg.isDeleted ? '[Повідомлення видалено]' : lastMsg.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontStyle: lastMsg.isDeleted ? FontStyle.italic : FontStyle.normal,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                      : const Text('Немає повідомлень', style: TextStyle(fontStyle: FontStyle.italic)),
                  trailing: lastMsg != null
                      ? Text(
                          DateFormat('HH:mm').format(lastMsg.createdAt.toLocal()),
                          style: Theme.of(context).textTheme.labelSmall,
                        )
                      : null,
                  onTap: () => context.push('/chats/${group.id}'),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Помилка: $err')),
      ),
    );
  }
}