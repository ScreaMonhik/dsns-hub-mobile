import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/news_models.dart';
import '../../data/repositories/news-repository.dart';
import '../../../auth/providers/auth_provider.dart';

// Provider для детальної інформації про новину
final newsDetailProvider = FutureProvider.family<NewsArticle, String>((ref, id) async {
  final repository = ref.watch(newsRepositoryProvider);
  return repository.getNewsById(id);
});

// Провайдер для списку категорій
final Provider<Future<List<NewsCategory>>> newsCategoriesProvider = Provider((ref) {
  final token = ref.watch(currentTokenProvider);
  if (token == null || token.isEmpty) return Future.value([]);
  return ref.watch(newsRepositoryProvider).getCategories();
});

// Провайдер для збереження обраної категорії (null = Усі новини)
final StateProvider<String?> selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Провайдер для збереження пошукового запиту
final StateProvider<String?> newsSearchQueryProvider = StateProvider<String?>((ref) => null);

// AsyncNotifier для списку новин з підтримкою пагінації та фільтрації
class NewsListNotifier extends AsyncNotifier<List<NewsArticle>> {
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetching = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<NewsArticle>> build() async {
    // Якщо токен пропав (логаут), повертаємо пустий список
    final token = ref.watch(currentTokenProvider);
    if (token == null || token.isEmpty) return [];

    _currentPage = 1;
    final categoryId = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(newsSearchQueryProvider);
    return _fetchPage(1, categoryId: categoryId, search: searchQuery);
  }

  Future<List<NewsArticle>> _fetchPage(int page, {String? categoryId, String? search}) async {
    final repository = ref.read(newsRepositoryProvider);
    final response = await repository.getNews(
      page: page, 
      limit: 10,
      categoryId: categoryId,
      search: search,
    );
    
    if (response.meta != null) {
      _hasMore = response.meta!.page < response.meta!.lastPage;
    } else {
      _hasMore = response.data.length >= 10;
    }
    
    return response.data;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isFetching) return;

    _isFetching = true;
    _currentPage++;
    final categoryId = ref.read(selectedCategoryProvider);
    final searchQuery = ref.read(newsSearchQueryProvider);
    
    try {
      final newArticles = await _fetchPage(_currentPage, categoryId: categoryId, search: searchQuery);
      final currentArticles = state.value ?? [];
      
      state = AsyncValue.data([...currentArticles, ...newArticles]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;
    }
  }
}

// Провайдер для взаємодії з новинами (лайки, дизлайки, додавання коментарів)
final Provider<NewsInteractionController> newsInteractionProvider = Provider<NewsInteractionController>((ref) {
  return NewsInteractionController(ref);
});

class NewsInteractionController {
  final Ref _ref;

  NewsInteractionController(this._ref);

  Future<void> vote(String newsId, String voteType) async {
    try {
      await _ref.read(newsRepositoryProvider).vote(newsId, voteType);
      _ref.invalidate(newsListProvider);
      _ref.invalidate(newsDetailProvider(newsId));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> addComment(String newsId, String content) async {
    try {
      await _ref.read(newsRepositoryProvider).addComment(newsId, content);
      _ref.invalidate(newsListProvider);
      _ref.invalidate(newsDetailProvider(newsId));
    } catch (e) {
      throw Exception('Не вдалося додати коментар: $e');
    }
  }
}

final newsListProvider = AsyncNotifierProvider<NewsListNotifier, List<NewsArticle>>(
  () => NewsListNotifier(),
);