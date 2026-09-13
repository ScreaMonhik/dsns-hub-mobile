import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/offline/offline_cache.dart';
import '../../../../core/utils/isolate_json.dart';
import '../models/news_models.dart';

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository(ref.watch(dioProvider), ref.watch(offlineCacheProvider));
});

class NewsRepository {
  NewsRepository(this._dio, this._cache);

  final Dio _dio;
  final OfflineCache _cache;

  Future<NewsPaginatedResponse> getNews({
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? status,
    String? departmentId,
    String? search,
  }) async {
    final cacheKey = 'news:p=$page:l=$limit:c=${categoryId ?? ''}:s=${search ?? ''}:st=${status ?? ''}:d=${departmentId ?? ''}';
    try {
      final response = await _dio.get('/news', queryParameters: {
        'page': page,
        'limit': limit,
        if (categoryId != null) 'categoryId': categoryId,
        if (status != null) 'status': status,
        if (departmentId != null) 'departmentId': departmentId,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      await _cache.put(cacheKey, response.data);
      return await parseJsonMapInIsolate(response.data, NewsPaginatedResponse.fromJson);
    } catch (error) {
      final cached = await _cache.get(cacheKey);
      if (cached != null) {
        return parseJsonMapInIsolate(cached, NewsPaginatedResponse.fromJson);
      }
      rethrow;
    }
  }

  Future<NewsArticle> getNewsById(String id) async {
    final cacheKey = 'news:id=$id';
    try {
      final response = await _dio.get('/news/$id');
      await _cache.put(cacheKey, response.data);
      return await parseJsonMapInIsolate(response.data, NewsArticle.fromJson);
    } catch (error) {
      final cached = await _cache.get(cacheKey);
      if (cached != null) {
        return parseJsonMapInIsolate(cached, NewsArticle.fromJson);
      }
      rethrow;
    }
  }

  Future<List<NewsCategory>> getCategories() async {
    const cacheKey = 'news:categories';
    try {
      final response = await _dio.get('/news/categories');
      final data = response.data is List ? response.data : response.data['data'];
      await _cache.put(cacheKey, data);
      return await parseJsonListInIsolate(data, NewsCategory.fromJson);
    } catch (error) {
      final cached = await _cache.get(cacheKey);
      if (cached != null) {
        return parseJsonListInIsolate(cached, NewsCategory.fromJson);
      }
      rethrow;
    }
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
