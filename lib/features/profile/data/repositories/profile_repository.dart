import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/data/models/auth_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<UserProfile> getMe() async {
    final response = await _dio.get('/users/me');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> uploadAvatar(String filePath) async {
    // 1. Примусово читаємо файл у пам'ять, щоб уникнути проблеми з 0-байт потоком
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    
    final fileName = filePath.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    
    // 2. Встановлюємо правильний MIME-тип
    String subType = 'jpeg';
    if (extension == 'png') {
      subType = 'png';
    } else if (extension == 'webp') {
      subType = 'webp';
    } else if (extension == 'jpg') {
      subType = 'jpeg';
    }

    // 3. Створюємо FormData використовуючи байти
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
}