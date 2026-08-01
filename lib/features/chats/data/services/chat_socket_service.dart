import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../core/network/dio_provider.dart';
import '../models/chat_models.dart';

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final service = ChatSocketService(storage);
  ref.onDispose(() => service.disconnect());
  return service;
});

class ChatSocketService {
  final FlutterSecureStorage _storage;
  IO.Socket? _socket;

  // Streams for real-time events
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _messageUpdatedController = StreamController<ChatMessage>.broadcast();
  final _messageDeletedController = StreamController<ChatMessage>.broadcast();
  final _messagesReadController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ChatMessage> get onNewMessage => _messageController.stream;
  Stream<ChatMessage> get onMessageUpdated => _messageUpdatedController.stream;
  Stream<ChatMessage> get onMessageDeleted => _messageDeletedController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _messagesReadController.stream;

  ChatSocketService(this._storage);

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _storage.read(key: 'jwt_token');
    
    _socket = IO.io(
      'http://10.0.2.2:3000/chat',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.on('newMessage', (data) {
      if (data != null) _messageController.add(ChatMessage.fromJson(data));
    });

    _socket!.on('messageUpdated', (data) {
      if (data != null) _messageUpdatedController.add(ChatMessage.fromJson(data));
    });

    _socket!.on('messageDeleted', (data) {
      if (data != null) _messageDeletedController.add(ChatMessage.fromJson(data));
    });

    _socket!.on('messagesRead', (data) {
      if (data != null) _messagesReadController.add(Map<String, dynamic>.from(data));
    });
  }

  void joinRoom(String groupId) {
    _socket?.emit('joinRoom', {'groupId': groupId});
  }

  void sendMessage(String groupId, String content) {
    _socket?.emit('sendMessage', {'groupId': groupId, 'content': content});
  }

  void editMessage(String messageId, String newContent) {
    _socket?.emit('editMessage', {'messageId': messageId, 'newContent': newContent});
  }

  void deleteMessage(String messageId) {
    _socket?.emit('deleteMessage', {'messageId': messageId});
  }

  void markAsRead(String groupId, List<String> messageIds) {
    if (messageIds.isEmpty) return;
    _socket?.emit('markAsRead', {'groupId': groupId, 'messageIds': messageIds});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}