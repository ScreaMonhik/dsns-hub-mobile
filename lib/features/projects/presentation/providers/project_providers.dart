import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/project_models.dart';
import '../../data/repositories/project_repository.dart';
import '../../../auth/providers/auth_provider.dart';

final projectSearchQueryProvider = StateProvider<String?>((ref) => null);

final projectDetailProvider = FutureProvider.family<ProjectModel, String>((ref, id) async {
  return ref.watch(projectRepositoryProvider).getProjectById(id);
});

class ProjectsListNotifier extends AsyncNotifier<List<ProjectModel>> {
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetching = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<ProjectModel>> build() async {
    final token = ref.watch(currentTokenProvider);
    if (token == null || token.isEmpty) return [];

    _currentPage = 1;
    final searchQuery = ref.watch(projectSearchQueryProvider);
    return _fetchPage(1, search: searchQuery);
  }

  Future<List<ProjectModel>> _fetchPage(int page, {String? search}) async {
    final repository = ref.read(projectRepositoryProvider);
    final response = await repository.getProjects(
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
    final searchQuery = ref.read(projectSearchQueryProvider);
    
    try {
      final newProjects = await _fetchPage(_currentPage, search: searchQuery);
      final currentProjects = state.value ?? [];
      state = AsyncValue.data([...currentProjects, ...newProjects]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;
    }
  }
}

final projectsListProvider = AsyncNotifierProvider<ProjectsListNotifier, List<ProjectModel>>(
  () => ProjectsListNotifier(),
);

final projectInteractionProvider = Provider<ProjectInteractionController>((ref) {
  return ProjectInteractionController(ref);
});

class ProjectInteractionController {
  final Ref _ref;

  ProjectInteractionController(this._ref);

  Future<void> vote(String projectId, String voteType) async {
    await _ref.read(projectRepositoryProvider).vote(projectId, voteType);
    _ref.invalidate(projectsListProvider);
    _ref.invalidate(projectDetailProvider(projectId));
  }

  Future<void> addComment(String projectId, String content) async {
    await _ref.read(projectRepositoryProvider).addComment(projectId, content);
    _ref.invalidate(projectsListProvider);
    _ref.invalidate(projectDetailProvider(projectId));
  }
}