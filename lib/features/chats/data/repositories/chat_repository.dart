import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../models/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(dioProvider));
});

class ChatRepository {
  final Dio _dio;

  ChatRepository(this._dio);

  Future<List<ChatGroup>> getGroups() async {
    final response = await _dio.get('/chat/groups');
    final data = response.data as List;
    return data.map((json) => ChatGroup.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessage>> getMessages(String groupId) async {
    final response = await _dio.get('/chat/groups/$groupId/messages');
    final history = ChatHistoryResponse.fromJson(response.data);
    return history.data;
  }
}