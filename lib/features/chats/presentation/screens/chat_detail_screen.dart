import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/chat_providers.dart';
import '../../data/models/chat_models.dart';
import '../../../../core/presentation/widgets/auth_network_image.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  const ChatDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(chatMessagesProvider(widget.groupId).notifier).loadMore();
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    ref.read(chatMessagesProvider(widget.groupId).notifier).sendMessage(text);
    _controller.clear();
  }

  void _showDeleteDialog(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити повідомлення?'),
        content: const Text('Цю дію неможливо скасувати.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Скасувати')),
          TextButton(
            onPressed: () {
              ref.read(chatMessagesProvider(widget.groupId).notifier).deleteMessage(messageId);
              Navigator.pop(context);
            },
            child: const Text('Видалити', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(chatMessagesProvider(widget.groupId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final groupsState = ref.watch(chatsListProvider);
    final theme = Theme.of(context);
    
    final groupName = groupsState.value?.where((g) => g.id == widget.groupId).firstOrNull?.name ?? 'Чат';

    return Scaffold(
      appBar: AppBar(
        title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
        titleSpacing: 0,
      ),
      body: Column(
              children: [
                Expanded(
                  child: messagesState.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return const Center(child: Text('Немає повідомлень'));
                      }
                      
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true, // Newest at the bottom
                        padding: const EdgeInsets.only(top: 16, bottom: 16),
                        itemCount: messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            final hasMore = ref.read(chatMessagesProvider(widget.groupId).notifier).hasMore;
                            return hasMore 
                                ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
                                : const SizedBox.shrink();
                          }

                          final msg = messages[index];
                          final isMe = currentUserId != null && msg.senderId == currentUserId;
                          
                          // Mark as read if not me and no my receipt exists
                          if (!isMe && currentUserId != null) {
                            final isReadByMe = msg.readReceipts.any((r) => r.userId == currentUserId);
                            if (!isReadByMe) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ref.read(chatMessagesProvider(widget.groupId).notifier).markAsRead([msg.id]);
                              });
                            }
                          }
                          
                          final isReadByOthers = msg.readReceipts.any((r) => r.userId != msg.senderId);
                          
                          // Grouping logic for bubble styles and spacing
                          // reverse: true means index 0 is the newest message
                          final bool isTop = index == messages.length - 1 || messages[index + 1].senderId != msg.senderId;
                          final bool isBottom = index == 0 || messages[index - 1].senderId != msg.senderId;

                          return GestureDetector(
                            onLongPress: isMe && !msg.isDeleted ? () => _showDeleteDialog(msg.id) : null,
                            child: Container(
                              margin: EdgeInsets.only(
                                top: isTop ? 16 : 2,
                                bottom: index == 0 ? 12 : 0,
                                left: 16,
                                right: 16,
                              ),
                              child: Row(
                                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isMe) ...[
                                    if (isBottom)
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: theme.colorScheme.primaryContainer,
                                        child: msg.sender?.avatarUrl != null
                                            ? ClipOval(
                                                child: AuthNetworkImage(
                                                  imageUrl: msg.sender!.avatarUrl!,
                                                  width: 32,
                                                  height: 32,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Text(
                                                msg.sender?.firstName.isNotEmpty == true 
                                                    ? msg.sender!.firstName[0] 
                                                    : '?',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.onPrimaryContainer,
                                                ),
                                              ),
                                      )
                                    else
                                      const SizedBox(width: 32), // Space placeholder for avatar
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Container(
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(isMe ? 18 : (isTop ? 18 : 6)),
                                          topRight: Radius.circular(!isMe ? 18 : (isTop ? 18 : 6)),
                                          bottomLeft: Radius.circular(isMe ? 18 : 6),
                                          bottomRight: Radius.circular(!isMe ? 18 : 6),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (!isMe && isTop && msg.sender != null) ...[
                                            Text(
                                              '${msg.sender!.firstName} ${msg.sender!.lastName}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                          Wrap(
                                            alignment: WrapAlignment.end,
                                            crossAxisAlignment: WrapCrossAlignment.end,
                                            children: [
                                              Text(
                                                msg.isDeleted ? '[Повідомлення видалено]' : msg.content,
                                                style: TextStyle(
                                                  fontStyle: msg.isDeleted ? FontStyle.italic : FontStyle.normal,
                                                  color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 1),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      DateFormat('HH:mm').format(msg.createdAt.toLocal()),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isMe 
                                                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.7) 
                                                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                                      ),
                                                    ),
                                                    if (isMe) ...[
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        isReadByOthers ? Icons.done_all : Icons.check,
                                                        size: 14,
                                                        color: isReadByOthers 
                                                          ? theme.colorScheme.onPrimary 
                                                          : theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Помилка: $err')),
                  ),
                ),
                SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Повідомлення...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}