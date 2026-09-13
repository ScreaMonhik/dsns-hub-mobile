import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/offline/offline_cache.dart';
import '../../../../core/utils/isolate_json.dart';
import '../../../../core/utils/safe_file.dart';
import '../models/document_models.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.watch(dioProvider), ref.watch(offlineCacheProvider));
});

class DocumentRepository {
  DocumentRepository(this._dio, this._cache);

  final Dio _dio;
  final OfflineCache _cache;

  Future<DocumentPaginatedResponse> getDocuments({
    int page = 1,
    int limit = 10,
    String? search,
    String? departmentId,
  }) async {
    final cacheKey = 'documents:p=$page:l=$limit:s=${search ?? ''}:d=${departmentId ?? ''}';
    try {
      final response = await _dio.get('/documents', queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (departmentId != null) 'departmentId': departmentId,
      });
      await _cache.put(cacheKey, response.data);
      return await parseJsonMapInIsolate(response.data, DocumentPaginatedResponse.fromJson);
    } catch (error) {
      final cached = await _cache.get(cacheKey);
      if (cached != null) {
        return parseJsonMapInIsolate(cached, DocumentPaginatedResponse.fromJson);
      }
      rethrow;
    }
  }

  Future<DocumentModel> getDocumentById(String id) async {
    final cacheKey = 'documents:id=$id';
    try {
      final response = await _dio.get('/documents/$id');
      await _cache.put(cacheKey, response.data);
      return await parseJsonMapInIsolate(response.data, DocumentModel.fromJson);
    } catch (error) {
      final cached = await _cache.get(cacheKey);
      if (cached != null) {
        return parseJsonMapInIsolate(cached, DocumentModel.fromJson);
      }
      rethrow;
    }
  }

  Future<String> downloadDocumentToTemp(String fileUrl, String fileName) async {
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
