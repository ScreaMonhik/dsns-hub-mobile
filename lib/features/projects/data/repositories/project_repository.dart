import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/offline/offline_cache.dart';
import '../../../../core/utils/isolate_json.dart';
import '../../../../core/utils/safe_file.dart';
import '../models/project_models.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(dioProvider), ref.watch(offlineCacheProvider));
});

class ProjectRepository {
  ProjectRepository(this._dio, this._cache);

  final Dio _dio;
  final OfflineCache _cache;

  Future<ProjectPaginatedResponse> getProjects({
    int page = 1,
    int limit = 10,
    String? search,
    String? departmentId,
  }) async {
    final cacheKey = 'projects:p=$page:l=$limit:s=${search ?? ''}:d=${departmentId ?? ''}';
    try {
      final response = await _dio.get('/projects', queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (departmentId != null) 'departmentId': departmentId,
      });
      await _cache.put(cacheKey, response.data);
      return await parseJsonMapInIsolate(response.data, ProjectPaginatedResponse.fromJson);
    } catch (error) {
      final cached = await _cache.get(cacheKey);
      if (cached != null) {
        return parseJsonMapInIsolate(cached, ProjectPaginatedResponse.fromJson);
      }
      rethrow;
    }
  }

  Future<ProjectModel> getProjectById(String id) async {
    final cacheKey = 'projects:id=$id';
    try {
      final response = await _dio.get('/projects/$id');
      await _cache.put(cacheKey, response.data);
      return await parseJsonMapInIsolate(response.data, ProjectModel.fromJson);
    } catch (error) {
      final cached = await _cache.get(cacheKey);
      if (cached != null) {
        return parseJsonMapInIsolate(cached, ProjectModel.fromJson);
      }
      rethrow;
    }
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
    final tempDir = await getTemporaryDirectory();
    final savePath = resolveTempSavePath(tempDir, fileName);
    final file = File(savePath);
    if (await file.exists()) {
      return savePath;
    }

    await _dio.download(
      fileUrl,
      savePath,
      options: Options(receiveTimeout: const Duration(minutes: 2)),
    );
    return savePath;
  }
}
