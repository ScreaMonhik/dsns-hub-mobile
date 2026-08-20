import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/document_models.dart';
import '../../data/repositories/document_repository.dart';
import '../../../auth/providers/auth_provider.dart';

final documentSearchQueryProvider = StateProvider<String?>((ref) => null);

class DocumentsListNotifier extends AsyncNotifier<List<DocumentModel>> {
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetching = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<DocumentModel>> build() async {
    final token = ref.watch(currentTokenProvider);
    if (token == null || token.isEmpty) return [];

    _currentPage = 1;
    final searchQuery = ref.watch(documentSearchQueryProvider);
    return _fetchPage(1, search: searchQuery);
  }

  Future<List<DocumentModel>> _fetchPage(int page, {String? search}) async {
    final repository = ref.read(documentRepositoryProvider);
    final response = await repository.getDocuments(
      page: page, 
      limit: 10,
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
    final searchQuery = ref.read(documentSearchQueryProvider);
    
    try {
      final newDocs = await _fetchPage(_currentPage, search: searchQuery);
      final currentDocs = state.value ?? [];
      
      state = AsyncValue.data([...currentDocs, ...newDocs]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;
    }
  }
}

final documentsListProvider = AsyncNotifierProvider<DocumentsListNotifier, List<DocumentModel>>(
  () => DocumentsListNotifier(),
);