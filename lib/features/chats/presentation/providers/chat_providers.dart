import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/chat_socket_service.dart';
import '../../../../core/storage/secure_storage_provider.dart';

// Provider for Current User ID from JWT
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final token = await storage.read(key: 'jwt_token');
  if (token == null || token.isEmpty) return null;
  
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    
    final payload = base64Url.normalize(parts[1]);
    final decoded = json.decode(utf8.decode(base64Url.decode(payload)));
    
    // Fallback to 'sub' if 'id' is not present, depending on backend JWT structure
    return decoded['id'] ?? decoded['sub']; 
  } catch (e) {
    return null;
  }
});

// Provider for Chat List
final chatsListProvider = AsyncNotifierProvider<ChatsListNotifier, List<ChatGroup>>(
  () => ChatsListNotifier(),
);

class ChatsListNotifier extends AsyncNotifier<List<ChatGroup>> {
  StreamSubscription? _newMessageSub;

  @override
  Future<List<ChatGroup>> build() async {
    final socket = ref.watch(chatSocketServiceProvider);
    await socket.connect();

    _newMessageSub?.cancel();
    _newMessageSub = socket.onNewMessage.listen((msg) {
      _updateLastMessage(msg);
    });

    ref.onDispose(() => _newMessageSub?.cancel());

    return ref.watch(chatRepositoryProvider).getGroups();
  }

  void _updateLastMessage(ChatMessage message) {
    if (state.value == null) return;
    final groups = [...state.value!];
    
    final index = groups.indexWhere((g) => g.id == message.groupId);
    if (index != -1) {
      final group = groups[index];
      groups[index] = group.copyWith(messages: [message]);
      
      // Move updated group to top
      final updatedGroup = groups.removeAt(index);
      groups.insert(0, updatedGroup);
      
      state = AsyncValue.data(groups);
    }
  }
}

// Provider for Chat Messages History
final chatMessagesProvider = AsyncNotifierProviderFamily<ChatMessagesNotifier, List<ChatMessage>, String>(
  () => ChatMessagesNotifier(),
);

class ChatMessagesNotifier extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  StreamSubscription? _subNew;
  StreamSubscription? _subUpdate;
  StreamSubscription? _subDelete;

  @override
  Future<List<ChatMessage>> build(String arg) async {
    final socket = ref.watch(chatSocketServiceProvider);
    await socket.connect();
    socket.joinRoom(arg);

    _setupSocketListeners(socket);

    final messages = await ref.watch(chatRepositoryProvider).getMessages(arg);
    // Reverse for UI (newest at bottom requires reversed list in ListView)
    return messages.reversed.toList();
  }

  void _setupSocketListeners(ChatSocketService socket) {
    _subNew?.cancel();
    _subUpdate?.cancel();
    _subDelete?.cancel();

    _subNew = socket.onNewMessage.listen((msg) {
      if (msg.groupId == arg && state.value != null) {
        state = AsyncValue.data([msg, ...state.value!]);
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

    ref.onDispose(() {
      _subNew?.cancel();
      _subUpdate?.cancel();
      _subDelete?.cancel();
    });
  }

  void sendMessage(String content) {
    ref.read(chatSocketServiceProvider).sendMessage(arg, content);
  }

  void deleteMessage(String messageId) {
    ref.read(chatSocketServiceProvider).deleteMessage(messageId);
  }
}