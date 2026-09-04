import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_models.dart';
import '../../../../core/network/dio_provider.dart'; // Вкажіть правильний шлях до вашого клієнта

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return NewsRepository(dio);
});

class NewsRepository {
  final Dio _dio;

  NewsRepository(this._dio);

  Future<NewsPaginatedResponse> getNews({
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? status,
    String? departmentId,
    String? search,
  }) async {
    final response = await _dio.get('/news', queryParameters: {
      'page': page,
      'limit': limit,
      if (categoryId != null) 'categoryId': categoryId,
      if (status != null) 'status': status,
      if (departmentId != null) 'departmentId': departmentId,
      if (search != null && search.isNotEmpty) 'search': search,
    });

    return NewsPaginatedResponse.fromJson(response.data);
  }

  Future<NewsArticle> getNewsById(String id) async {
    final response = await _dio.get('/news/$id');
    return NewsArticle.fromJson(response.data);
  }

  Future<List<NewsCategory>> getCategories() async {
    final response = await _dio.get('/news/categories');
    // Обробляємо як прямий масив, так і обгорнутий у поле 'data'
    final data = response.data is List ? response.data : response.data['data'];
    return (data as List).map((json) => NewsCategory.fromJson(json)).toList();
  }

  Future<void> vote(String newsId, String voteType) async {
    try {
      await _dio.post(
        '/news/$newsId/vote',
        data: {'voteType': voteType},
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        final message = (data is Map && data['message'] != null)
            ? (data['message'] is List ? data['message'].join(', ') : data['message'])
            : 'Помилка валідації сервера';
        throw Exception(message.toString());
      }
      throw Exception('Помилка з\'єднання: ${e.message}');
    }
  }

  Future<void> addComment(String newsId, String content) async {
    try {
      await _dio.post(
        '/news/$newsId/comments',
        data: {'content': content},
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        final message = (data is Map && data['message'] != null)
            ? (data['message'] is List ? data['message'].join(', ') : data['message'])
            : 'Помилка валідації сервера';
        throw Exception(message.toString());
      }
      throw Exception('Помилка з\'єднання: ${e.message}');
    }
  }
}