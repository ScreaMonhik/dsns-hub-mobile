import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/chat_socket_service.dart';
import '../../../auth/providers/auth_provider.dart';

final currentUserIdProvider = Provider<String?>((ref) {
  final token = ref.watch(currentTokenProvider);
  if (token == null || token.isEmpty) return null;
  
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    
    final payload = base64Url.normalize(parts[1]);
    final decoded = json.decode(utf8.decode(base64Url.decode(payload)));
    
    return decoded['id'] ?? decoded['sub']; 
  } catch (e) {
    return null;
  }
});

final chatMembersProvider = FutureProvider.family<List<ChatMember>, String>((ref, groupId) async {
  return ref.watch(chatRepositoryProvider).getGroupMembers(groupId);
});

final chatsListProvider = AsyncNotifierProvider<ChatsListNotifier, List<ChatGroup>>(
  () => ChatsListNotifier(),
);

class ChatsListNotifier extends AsyncNotifier<List<ChatGroup>> {
  StreamSubscription? _newMessageSub;

  @override
  Future<List<ChatGroup>> build() async {
    final token = ref.watch(currentTokenProvider);
    final socket = ref.watch(chatSocketServiceProvider);
    
    if (token == null || token.isEmpty) {
      socket.disconnect();
      return [];
    }

    await socket.connect();

    _newMessageSub?.cancel();
    _newMessageSub = socket.onNewMessage.listen((msg) {
      _updateLastMessage(msg);
    });

    ref.onDispose(() => _newMessageSub?.cancel());

    final groups = await ref.watch(chatRepositoryProvider).getGroups();
    
    groups.sort((a, b) {
      final aDate = a.messages.isNotEmpty ? a.messages.first.createdAt : a.createdAt;
      final bDate = b.messages.isNotEmpty ? b.messages.first.createdAt : b.createdAt;
      return bDate.compareTo(aDate);
    });
    
    return groups;
  }

  void _updateLastMessage(ChatMessage message) {
    if (state.value == null) return;
    final groups = [...state.value!];
    
    final index = groups.indexWhere((g) => g.id == message.groupId);
    if (index != -1) {
      final group = groups[index];
      final currentUserId = ref.read(currentUserIdProvider);
      final isMine = currentUserId != null && message.senderId == currentUserId;
      
      groups[index] = group.copyWith(
        messages: [message],
        unreadCount: isMine ? group.unreadCount : group.unreadCount + 1,
      );
      
      final updatedGroup = groups.removeAt(index);
      groups.insert(0, updatedGroup);
      
      state = AsyncValue.data(groups);
    }
  }

  void clearUnreadCount(String groupId) {
    if (state.value == null) return;
    final groups = [...state.value!];
    final index = groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      groups[index] = groups[index].copyWith(unreadCount: 0);
      state = AsyncValue.data(groups);
    }
  }

  Future<void> updateGroupAvatar(String groupId, String filePath) async {
    try {
      final newAvatarUrl = await ref.read(chatRepositoryProvider).uploadGroupAvatar(groupId, filePath);
      if (state.value != null) {
        final groups = [...state.value!];
        final index = groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          groups[index] = groups[index].copyWith(avatarUrl: newAvatarUrl);
          state = AsyncValue.data(groups);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}

final chatMessagesProvider = AsyncNotifierProviderFamily<ChatMessagesNotifier, List<ChatMessage>, String>(
  () => ChatMessagesNotifier(),
);

class ChatMessagesNotifier extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  StreamSubscription? _subNew;
  StreamSubscription? _subUpdate;
  StreamSubscription? _subDelete;
  StreamSubscription? _subRead;

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetching = false;
  final Set<String> _pendingReadReceipts = {};

  bool get hasMore => _hasMore;

  @override
  Future<List<ChatMessage>> build(String arg) async {
    final token = ref.watch(currentTokenProvider);
    final socket = ref.watch(chatSocketServiceProvider);
    
    if (token == null || token.isEmpty) {
      return [];
    }

    await socket.connect();
    socket.joinRoom(arg);

    _setupSocketListeners(socket);
    
    _currentPage = 1;
    final response = await ref.watch(chatRepositoryProvider).getMessages(arg, page: _currentPage);
    _hasMore = response.meta.page < response.meta.lastPage;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatsListProvider.notifier).clearUnreadCount(arg);
    });

    return response.data.reversed.toList();
  }

  void _setupSocketListeners(ChatSocketService socket) {
    _subNew?.cancel();
    _subUpdate?.cancel();
    _subDelete?.cancel();
    _subRead?.cancel();

    _subNew = socket.onNewMessage.listen((msg) {
      if (msg.groupId == arg && state.value != null) {
        state = AsyncValue.data([msg, ...state.value!]);
        final currentUserId = ref.read(currentUserIdProvider);
        if (currentUserId != null && msg.senderId != currentUserId) {
          markAsRead([msg.id]);
        }
      }
    });

    _subUpdate = socket.onMessageUpdated.listen((msg) {
      if (msg.groupId == arg && state.value != null) {
        final msgs = state.value!.map((m) => m.id == msg.id ? msg : m).toList();
        state = AsyncValue.data(msgs);
      }
    });

    _subDelete = socket.onMessageDeleted.listen((msg) {
      if (msg.groupId == arg && state.value != null) {
        final msgs = state.value!.map((m) => m.id == msg.id ? msg : m).toList();
        state = AsyncValue.data(msgs);
      }
    });

    _subRead = socket.onMessagesRead.listen((data) {
      if (data['groupId'] == arg && state.value != null) {
        final messageIds = List<String>.from(data['messageIds'] ?? []);
        final readByUserId = data['readByUserId'] as String;
        
        final msgs = state.value!.map((m) {
          if (messageIds.contains(m.id)) {
            final newReceipt = ChatReadReceipt(userId: readByUserId, readAt: DateTime.now());
            return m.copyWith(readReceipts: [...m.readReceipts, newReceipt]);
          }
          return m;
        }).toList();
        
        state = AsyncValue.data(msgs);
      }
    });

    ref.onDispose(() {
      _subNew?.cancel();
      _subUpdate?.cancel();
      _subDelete?.cancel();
      _subRead?.cancel();
    });
  }
  
  Future<void> loadMore() async {
    if (!_hasMore || _isFetching) return;

    _isFetching = true;
    _currentPage++;
    
    try {
      final response = await ref.read(chatRepositoryProvider).getMessages(arg, page: _currentPage);
      _hasMore = response.meta.page < response.meta.lastPage;
      
      final currentMessages = state.value ?? [];
      state = AsyncValue.data([...currentMessages, ...response.data.reversed.toList()]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;
    }
  }

  void sendMessage(String content) {
    ref.read(chatSocketServiceProvider).sendMessage(arg, content);
  }

  void deleteMessage(String messageId) {
    ref.read(chatSocketServiceProvider).deleteMessage(messageId);
  }

  void markAsRead(List<String> messageIds) {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;
    
    final unreadIds = messageIds.where((id) => !_pendingReadReceipts.contains(id)).toList();
    if (unreadIds.isEmpty) return;
    
    _pendingReadReceipts.addAll(unreadIds);
    ref.read(chatSocketServiceProvider).markAsRead(arg, unreadIds);
  }
}