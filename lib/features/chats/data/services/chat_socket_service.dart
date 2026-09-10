import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_models.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/config/app_config.dart';

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final service = ChatSocketService(ref);
  ref.onDispose(() => service.disconnect());
  return service;
});

class ChatSocketService {
  final Ref _ref;
  IO.Socket? _socket;
  String? _connectedToken;

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
    final token = _ref.read(currentTokenProvider);
    if (token == null || token.isEmpty) {
      disconnect();
      return;
    }

    if (_socket != null && _socket!.connected && _connectedToken == token) {
      return;
    }

    disconnect();
    _connectedToken = token;

    _socket = IO.io(
      '${AppConfig.apiBaseUrl}/chat',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );

    _socket!.connect();

    _socket!.on('newMessage', (data) {
      final message = _parseMessage(data);
      if (message != null) _messageController.add(message);
    });

    _socket!.on('messageUpdated', (data) {
      final message = _parseMessage(data);
      if (message != null) _messageUpdatedController.add(message);
    });

    _socket!.on('messageDeleted', (data) {
      final message = _parseMessage(data);
      if (message != null) _messageDeletedController.add(message);
    });

    _socket!.on('messagesRead', (data) {
      final payload = _asStringKeyMap(data);
      if (payload != null) _messagesReadController.add(payload);
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
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    _socket?.emit('sendMessage', {'groupId': groupId, 'content': trimmed});
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

  Map<String, dynamic>? _asStringKeyMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  ChatMessage? _parseMessage(dynamic data) {
    final json = _asStringKeyMap(data);
    if (json == null) return null;
    try {
      return ChatMessage.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectedToken = null;
  }
}
