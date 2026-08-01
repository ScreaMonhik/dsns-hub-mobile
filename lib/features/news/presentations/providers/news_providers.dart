import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/news_models.dart';
import '../../data/repositories/news-repository.dart';

// Provider для детальної інформації про новину
final newsDetailProvider = FutureProvider.family<NewsArticle, String>((ref, id) async {
  final repository = ref.watch(newsRepositoryProvider);
  return repository.getNewsById(id);
});

// AsyncNotifier для списку новин з підтримкою пагінації
class NewsListNotifier extends AsyncNotifier<List<NewsArticle>> {
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetching = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<NewsArticle>> build() async {
    _currentPage = 1;
    return _fetchPage(1);
  }

  Future<List<NewsArticle>> _fetchPage(int page) async {
    final repository = ref.read(newsRepositoryProvider);
    final response = await repository.getNews(page: page, limit: 10);
    
    _hasMore = response.meta.page < response.meta.lastPage;
    return response.data;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isFetching) return;

    _isFetching = true;
    _currentPage++;
    
    try {
      final newArticles = await _fetchPage(_currentPage);
      final currentArticles = state.value ?? [];
      
      state = AsyncValue.data([...currentArticles, ...newArticles]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;
    }
  }
}

final newsListProvider = AsyncNotifierProvider<NewsListNotifier, List<NewsArticle>>(
  () => NewsListNotifier(),
);