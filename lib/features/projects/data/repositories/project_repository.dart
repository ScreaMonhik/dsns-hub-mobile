import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/network/dio_provider.dart';
import '../models/project_models.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(dioProvider));
});

class ProjectRepository {
  final Dio _dio;

  ProjectRepository(this._dio);

  Future<ProjectPaginatedResponse> getProjects({
    int page = 1,
    int limit = 10,
    String? search,
    String? departmentId,
  }) async {
    final response = await _dio.get('/projects', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (departmentId != null) 'departmentId': departmentId,
    });

    return ProjectPaginatedResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProjectModel> getProjectById(String id) async {
    final response = await _dio.get('/projects/$id');
    return ProjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> vote(String projectId, String voteType) async {
    try {
      await _dio.post(
        '/projects/$projectId/vote',
        data: {'voteType': voteType},
      );
    } catch (e) {
      throw Exception('Помилка голосування. Спробуйте ще раз.');
    }
  }

  Future<void> addComment(String projectId, String content) async {
    try {
      await _dio.post(
        '/projects/$projectId/comments',
        data: {'content': content},
      );
    } catch (e) {
      throw Exception('Не вдалося додати коментар.');
    }
  }

  Future<String> downloadProjectPdf(String fileUrl, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/$fileName';
      
      final file = File(savePath);
      if (await file.exists()) {
        return savePath;
      }

      await _dio.download(fileUrl, savePath);
      return savePath;
    } catch (e) {
      throw Exception('Не вдалося завантажити PDF: $e');
    }
  }
}