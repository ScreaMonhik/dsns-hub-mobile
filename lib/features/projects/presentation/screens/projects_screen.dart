import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../core/offline/download_actions.dart';
import '../../../../core/offline/download_manager.dart';
import '../../../../core/presentation/widgets/common_error_widget.dart';
import '../../../../core/presentation/widgets/search_with_downloads_bar.dart';
import '../../../../core/presentation/widgets/shimmer_loading_list.dart';
import '../../../profile/presentation/widgets/user_profile_button.dart';
import '../../data/models/project_models.dart';
import '../../data/repositories/project_repository.dart';
import '../providers/project_providers.dart';
import '../widgets/project_card.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late final PagingController<int, ProjectModel> _pagingController;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, ProjectModel>(
      getNextPageKey: (state) {
        if (state.lastPageIsEmpty) return null;
        final lastItems = state.pages?.last;
        if (lastItems != null && lastItems.length < 10) return null;
        return state.nextIntPageKey;
      },
      fetchPage: (pageKey) async {
        final response = await ref.read(projectRepositoryProvider).getProjects(
              page: pageKey,
              limit: 10,
              search: ref.read(projectSearchQueryProvider),
            );
        return response.data;
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectsPagingControllerProvider.notifier).state = _pagingController;
    });
  }

  @override
  void dispose() {
    if (ref.read(projectsPagingControllerProvider) == _pagingController) {
      ref.read(projectsPagingControllerProvider.notifier).state = null;
    }
    _searchController.dispose();
    _debounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(projectSearchQueryProvider.notifier).state = query.trim();
      _pagingController.refresh();
    });
  }

  void _handleVote(BuildContext context, String projectId, String type) async {
    HapticFeedback.lightImpact();
    try {
      await ref.read(projectInteractionProvider).vote(projectId, type);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Проєкти'),
        actions: const [UserProfileButton()],
      ),
      body: Column(
        children: [
          SearchWithDownloadsBar(
            controller: _searchController,
            hintText: 'Пошук проєктів...',
            onChanged: _onSearchChanged,
            downloadsTooltip: 'Завантажені проєкти',
            onDownloadsTap: () => context.push('/projects/offline'),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _pagingController.refresh(),
              child: PagingListener(
                controller: _pagingController,
                builder: (context, state, fetchNextPage) => PagedListView<int, ProjectModel>(
                  state: state,
                  fetchNextPage: fetchNextPage,
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 100 + MediaQuery.paddingOf(context).bottom),
                  builderDelegate: PagedChildBuilderDelegate<ProjectModel>(
                    firstPageProgressIndicatorBuilder: (_) => const ShimmerLoadingList(),
                    firstPageErrorIndicatorBuilder: (_) => CommonErrorWidget(
                      error: state.error?.toString() ?? 'Помилка завантаження',
                      onRetry: _pagingController.refresh,
                    ),
                    noItemsFoundIndicatorBuilder: (_) => _buildEmptyState(),
                    itemBuilder: (context, project, index) => ProjectCard(
                      index: index,
                      project: project,
                      onTap: () => context.push('/projects/${project.id}'),
                      onLike: () => _handleVote(context, project.id, 'UPVOTE'),
                      onDislike: () => _handleVote(context, project.id, 'DOWNVOTE'),
                      onLongPress: project.fileUrl == null
                          ? null
                          : () => showDownloadPopup(
                                context: context,
                                ref: ref,
                                remoteId: project.id,
                                kind: OfflineDownloadKind.project,
                                title: project.title ?? 'Проєкт',
                                remoteUrl: project.fileUrl,
                              ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Проєкти не знайдені',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
