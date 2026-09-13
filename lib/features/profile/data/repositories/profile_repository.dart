import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/data/models/auth_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

class NotificationPreferences {
  const NotificationPreferences({
    this.notifyNews,
    this.notifyPolls,
    this.notifyPollDeadlines,
    this.notifyDocuments,
    this.notifyProjects,
    this.notifyChats,
  });

  final bool? notifyNews;
  final bool? notifyPolls;
  final bool? notifyPollDeadlines;
  final bool? notifyDocuments;
  final bool? notifyProjects;
  final bool? notifyChats;

  Map<String, bool> toJson() => {
        if (notifyNews != null) 'notifyNews': notifyNews!,
        if (notifyPolls != null) 'notifyPolls': notifyPolls!,
        if (notifyPollDeadlines != null) 'notifyPollDeadlines': notifyPollDeadlines!,
        if (notifyDocuments != null) 'notifyDocuments': notifyDocuments!,
        if (notifyProjects != null) 'notifyProjects': notifyProjects!,
        if (notifyChats != null) 'notifyChats': notifyChats!,
      };
}

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<UserProfile> getMe() async {
    final response = await _dio.get('/users/me');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile> updatePreferences(NotificationPreferences prefs) async {
    final response = await _dio.patch(
      '/users/me',
      data: prefs.toJson(),
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> uploadAvatar(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    final fileName = filePath.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();

    String subType = 'jpeg';
    if (extension == 'png') {
      subType = 'png';
    } else if (extension == 'webp') {
      subType = 'webp';
    } else if (extension == 'jpg') {
      subType = 'jpeg';
    }

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: MediaType('image', subType),
      ),
    });

    final response = await _dio.patch(
      '/users/me/avatar',
      data: formData,
    );

    return response.data['avatarUrl'] as String;
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _dio.patch(
        '/users/me/password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        final message = (data is Map && data['message'] != null)
            ? (data['message'] is List ? data['message'].join('\n') : data['message'])
            : 'Помилка валідації пароля';
        throw Exception(message.toString());
      }
      throw Exception('Помилка з\'єднання з сервером');
    } catch (e) {
      throw Exception('Невідома помилка: $e');
    }
  }
}
