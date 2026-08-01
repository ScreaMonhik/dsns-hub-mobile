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
  }) async {
    final response = await _dio.get('/news', queryParameters: {
      'page': page,
      'limit': limit,
      if (categoryId != null) 'categoryId': categoryId,
      if (status != null) 'status': status,
      if (departmentId != null) 'departmentId': departmentId,
    });

    return NewsPaginatedResponse.fromJson(response.data);
  }

  Future<NewsArticle> getNewsById(String id) async {
    final response = await _dio.get('/news/$id');
    return NewsArticle.fromJson(response.data);
  }

  Future<void> vote(String newsId, String voteType) async {
    await _dio.post(
      '/news/$newsId/vote',
      data: {'voteType': voteType},
    );
  }

  Future<void> addComment(String newsId, String content) async {
    await _dio.post(
      '/news/$newsId/comments',
      data: {'content': content},
    );
  }
}