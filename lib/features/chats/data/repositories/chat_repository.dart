import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
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

  Future<ChatHistoryResponse> getMessages(String groupId, {int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      '/chat/groups/$groupId/messages',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return ChatHistoryResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ChatMember>> getGroupMembers(String groupId) async {
    final response = await _dio.get('/chat/groups/$groupId/members');
    final data = response.data as List;
    return data.map((json) => ChatMember.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<String> uploadGroupAvatar(String groupId, String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    
    final fileName = filePath.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    
    String subType = 'jpeg';
    if (extension == 'png') {
      subType = 'png';
    } else if (extension == 'webp') {
      subType = 'webp';
    }

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: MediaType('image', subType),
      ),
    });

    final response = await _dio.post(
      '/chat/groups/$groupId/avatar',
      data: formData,
    );
    
    return response.data['url'] as String;
  }
}