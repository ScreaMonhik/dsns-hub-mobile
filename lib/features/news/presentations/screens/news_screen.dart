import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:dsns_hub/core/presentation/widgets/filter_choice_chip.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/presentation/widgets/common_error_widget.dart';
import '../../../../core/presentation/widgets/feature_disabled_view.dart';
import '../../../../core/presentation/widgets/shimmer_loading_list.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../profile/presentation/widgets/user_profile_button.dart';
import '../../data/models/news_models.dart';
import '../../data/repositories/news-repository.dart';
import '../providers/news_providers.dart';
import '../widgets/news_card.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late final PagingController<int, NewsArticle> _pagingController;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, NewsArticle>(
      getNextPageKey: (state) {
        if (state.lastPageIsEmpty) return null;
        final lastItems = state.pages?.last;
        if (lastItems != null && lastItems.length < 10) return null;
        return state.nextIntPageKey;
      },
      fetchPage: (pageKey) async {
        final response = await ref.read(newsRepositoryProvider).getNews(
              page: pageKey,
              limit: 10,
              categoryId: ref.read(selectedCategoryProvider),
              search: ref.read(newsSearchQueryProvider),
            );
        return response.data;
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(newsPagingControllerProvider.notifier).state = _pagingController;
    });
  }

  @override
  void dispose() {
    if (ref.read(newsPagingControllerProvider) == _pagingController) {
      ref.read(newsPagingControllerProvider.notifier).state = null;
    }
    _searchController.dispose();
    _debounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(newsSearchQueryProvider.notifier).state = query.trim();
      _pagingController.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(featureFlagsProvider).newsEnabled) {
      return const FeatureDisabledView(title: 'Новини');
    }

    ref.listen(selectedCategoryProvider, (_, __) => _pagingController.refresh());
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новини'),
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
                hintText: 'Пошук новин...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          _buildCategoryFilter(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _pagingController.refresh(),
              child: PagingListener(
                controller: _pagingController,
                builder: (context, state, fetchNextPage) => PagedListView<int, NewsArticle>(
                  state: state,
                  fetchNextPage: fetchNextPage,
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 100 + MediaQuery.paddingOf(context).bottom),
                  builderDelegate: PagedChildBuilderDelegate<NewsArticle>(
                    firstPageProgressIndicatorBuilder: (_) => const ShimmerLoadingList(),
                    firstPageErrorIndicatorBuilder: (_) => CommonErrorWidget(
                      error: state.error?.toString() ?? 'Помилка завантаження',
                      onRetry: _pagingController.refresh,
                    ),
                    noItemsFoundIndicatorBuilder: (_) => _buildEmptyState(),
                    newPageErrorIndicatorBuilder: (_) => TextButton(
                      onPressed: fetchNextPage,
                      child: const Text('Повторити завантаження'),
                    ),
                    itemBuilder: (context, article, index) => NewsCard(
                      index: index,
                      article: article,
                      currentUserId: currentUserId,
                      onTap: () => context.push('/news/${article.id}'),
                      onLike: () async {
                        HapticFeedback.lightImpact();
                        try {
                          await ref.read(newsInteractionProvider).vote(article.id, 'UPVOTE');
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      onDislike: () async {
                        HapticFeedback.lightImpact();
                        try {
                          await ref.read(newsInteractionProvider).vote(article.id, 'DOWNVOTE');
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      onCommentTap: () => context.push('/news/${article.id}?comments=true'),
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

  Widget _buildCategoryFilter() {
    final categories = ref.watch(newsCategoriesProvider).valueOrNull;
    if (categories == null || categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedCategoryId = ref.watch(selectedCategoryProvider);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            FilterChoiceChip(
              label: 'Усі',
              isSelected: selectedCategoryId == null,
              onSelected: () {
                if (selectedCategoryId != null) {
                  HapticFeedback.lightImpact();
                  ref.read(selectedCategoryProvider.notifier).state = null;
                }
              },
            ),
            ...categories.map((category) {
              final isSelected = selectedCategoryId == category.id;
              return FilterChoiceChip(
                label: category.name ?? 'Без назви',
                isSelected: isSelected,
                onSelected: () {
                  if (!isSelected) {
                    HapticFeedback.lightImpact();
                    ref.read(selectedCategoryProvider.notifier).state = category.id;
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Немає новин',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _pagingController.refresh,
            child: const Text('Оновити'),
          ),
        ],
      ),
    );
  }
}
