import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../data/models/project_models.dart';
import '../../data/repositories/project_repository.dart';

final projectSearchQueryProvider = StateProvider<String?>((ref) => null);

final projectDetailProvider = FutureProvider.family<ProjectModel, String>((ref, id) async {
  return ref.watch(projectRepositoryProvider).getProjectById(id);
});

final projectsPagingControllerProvider = StateProvider<PagingController<int, ProjectModel>?>((ref) => null);

final projectInteractionProvider = Provider<ProjectInteractionController>((ref) {
  return ProjectInteractionController(ref);
});

class ProjectInteractionController {
  ProjectInteractionController(this._ref);

  final Ref _ref;

  Future<void> vote(String projectId, String voteType) async {
    await _ref.read(projectRepositoryProvider).vote(projectId, voteType);
    await _refreshItem(projectId);
    _ref.invalidate(projectDetailProvider(projectId));
  }

  Future<void> addComment(String projectId, String content) async {
    await _ref.read(projectRepositoryProvider).addComment(projectId, content);
    await _refreshItem(projectId);
    _ref.invalidate(projectDetailProvider(projectId));
  }

  Future<void> _refreshItem(String projectId) async {
    try {
      final updated = await _ref.read(projectRepositoryProvider).getProjectById(projectId);
      _ref.read(projectsPagingControllerProvider)?.mapItems(
            (item) => item.id == projectId ? updated : item,
          );
    } catch (_) {}
  }
}
