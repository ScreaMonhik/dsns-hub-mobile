import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/chat_providers.dart';
import '../../../../core/presentation/widgets/auth_network_image.dart';
import '../../../profile/presentation/widgets/user_profile_button.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsState = ref.watch(chatsListProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Чати', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: const [UserProfileButton()],
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
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (lastMsg != null)
                        Text(
                          DateFormat('HH:mm').format(lastMsg.createdAt.toLocal()),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: group.unreadCount > 0 ? Theme.of(context).colorScheme.primary : null,
                            fontWeight: group.unreadCount > 0 ? FontWeight.bold : null,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: lastMsg != null
                            ? RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: TextStyle(
                                    fontStyle: lastMsg.isDeleted ? FontStyle.italic : FontStyle.normal,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    if (!lastMsg.isDeleted)
                                      if (currentUserId != null && lastMsg.senderId == currentUserId)
                                        TextSpan(
                                          text: 'Ви: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        )
                                      else if (lastMsg.sender != null)
                                        TextSpan(
                                          text: '${lastMsg.sender!.firstName}: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                    TextSpan(text: lastMsg.isDeleted ? '[Повідомлення видалено]' : lastMsg.content),
                                  ],
                                ),
                              )
                            : const Text('Немає повідомлень', style: TextStyle(fontStyle: FontStyle.italic)),
                      ),
                      if (group.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${group.unreadCount}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
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