import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/network/dio_provider.dart';
import '../models/document_models.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.watch(dioProvider));
});

class DocumentRepository {
  final Dio _dio;

  DocumentRepository(this._dio);

  Future<DocumentPaginatedResponse> getDocuments({
    int page = 1,
    int limit = 10,
    String? search,
    String? departmentId,
  }) async {
    final response = await _dio.get('/documents', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (departmentId != null) 'departmentId': departmentId,
    });

    return DocumentPaginatedResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DocumentModel> getDocumentById(String id) async {
    final response = await _dio.get('/documents/$id');
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> downloadDocumentToTemp(String fileUrl, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/$fileName';
      
      // Перевіряємо чи файл вже завантажено, щоб не качати двічі
      final file = File(savePath);
      if (await file.exists()) {
        return savePath;
      }

      // Завантажуємо файл. Dio автоматично додасть Bearer токен через наші interceptors
      await _dio.download(fileUrl, savePath);
      return savePath;
    } catch (e) {
      throw Exception('Не вдалося завантажити документ: $e');
    }
  }
}