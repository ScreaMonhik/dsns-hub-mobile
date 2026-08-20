import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_models.dart';
import '../../../auth/providers/auth_provider.dart';

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final service = ChatSocketService(ref);
  ref.onDispose(() => service.disconnect());
  return service;
});

class ChatSocketService {
  final Ref _ref;
  IO.Socket? _socket;

  final _messageController = StreamController<ChatMessage>.broadcast();
  final _messageUpdatedController = StreamController<ChatMessage>.broadcast();
  final _messageDeletedController = StreamController<ChatMessage>.broadcast();
  final _messagesReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _exceptionController = StreamController<String>.broadcast();

  Stream<ChatMessage> get onNewMessage => _messageController.stream;
  Stream<ChatMessage> get onMessageUpdated => _messageUpdatedController.stream;
  Stream<ChatMessage> get onMessageDeleted => _messageDeletedController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _messagesReadController.stream;
  Stream<String> get onException => _exceptionController.stream;

  ChatSocketService(this._ref);

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = _ref.read(currentTokenProvider);
    
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

    _socket!.on('exception', (data) {
      if (data != null && data['message'] != null) {
        _exceptionController.add(data['message'].toString());
      }
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