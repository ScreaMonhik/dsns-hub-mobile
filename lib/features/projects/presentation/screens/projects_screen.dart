import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/project_providers.dart';
import '../widgets/project_card.dart';
import '../../../profile/presentation/widgets/user_profile_button.dart';
import '../../../../core/presentation/widgets/shimmer_loading_list.dart';
import '../../../../core/presentation/widgets/common_error_widget.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(projectsListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(projectSearchQueryProvider.notifier).state = query.trim();
    });
  }

  Future<void> _onRefresh() async {
    ref.invalidate(projectsListProvider);
  }

  void _handleVote(BuildContext context, String projectId, String type) async {
    HapticFeedback.lightImpact();
    try {
      await ref.read(projectInteractionProvider).vote(projectId, type);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Проєкти'),
        actions: const [UserProfileButton()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Пошук проєктів...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: projectsState.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: _buildEmptyState(),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 100 + MediaQuery.paddingOf(context).bottom),
                    itemCount: projects.length + 1,
                    itemBuilder: (context, index) {
                      if (index == projects.length) {
                        return _buildBottomLoader();
                      }
                      
                      final project = projects[index];
                      return ProjectCard(
                        index: index,
                        project: project,
                        onTap: () => context.push('/projects/${project.id}'),
                        onLike: () => _handleVote(context, project.id, 'UPVOTE'),
                        onDislike: () => _handleVote(context, project.id, 'DOWNVOTE'),
                      );
                    },
                  ),
                );
              },
              loading: () => const ShimmerLoadingList(),
              error: (err, _) => CommonErrorWidget(
                error: err.toString(),
                onRetry: _onRefresh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomLoader() {
    final hasMore = ref.read(projectsListProvider.notifier).hasMore;
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Всі проєкти завантажено', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
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