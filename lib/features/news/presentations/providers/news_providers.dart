import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../auth/providers/auth_provider.dart';
import '../../data/models/news_models.dart';
import '../../data/repositories/news-repository.dart';

final newsDetailProvider = FutureProvider.family<NewsArticle, String>((ref, id) async {
  final repository = ref.watch(newsRepositoryProvider);
  return repository.getNewsById(id);
});

final newsCategoriesProvider = FutureProvider<List<NewsCategory>>((ref) async {
  final token = ref.watch(currentTokenProvider);
  if (token == null || token.isEmpty) return [];
  return ref.watch(newsRepositoryProvider).getCategories();
});

final StateProvider<String?> selectedCategoryProvider = StateProvider<String?>((ref) => null);
final StateProvider<String?> newsSearchQueryProvider = StateProvider<String?>((ref) => null);

final newsPagingControllerProvider = StateProvider<PagingController<int, NewsArticle>?>((ref) => null);

final Provider<NewsInteractionController> newsInteractionProvider = Provider<NewsInteractionController>((ref) {
  return NewsInteractionController(ref);
});

class NewsInteractionController {
  NewsInteractionController(this._ref);

  final Ref _ref;

  Future<void> vote(String newsId, String voteType) async {
    try {
      await _ref.read(newsRepositoryProvider).vote(newsId, voteType);
      await _refreshItem(newsId);
      _ref.invalidate(newsDetailProvider(newsId));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> addComment(String newsId, String content) async {
    try {
      await _ref.read(newsRepositoryProvider).addComment(newsId, content);
      await _refreshItem(newsId);
      _ref.invalidate(newsDetailProvider(newsId));
    } catch (e) {
      throw Exception('Не вдалося додати коментар: $e');
    }
  }

  Future<void> _refreshItem(String newsId) async {
    try {
      final updated = await _ref.read(newsRepositoryProvider).getNewsById(newsId);
      _ref.read(newsPagingControllerProvider)?.mapItems(
            (item) => item.id == newsId ? updated : item,
          );
    } catch (_) {}
  }
}
