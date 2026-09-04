import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/news_models.dart';
import 'package:dsns_hub/core/presentation/widgets/filter_choice_chip.dart';
import '../providers/news_providers.dart';
import '../widgets/news_card.dart';
import '../../../profile/presentation/widgets/user_profile_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/presentation/widgets/shimmer_loading_list.dart';
import '../../../../core/presentation/widgets/common_error_widget.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
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
      ref.read(newsListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(newsSearchQueryProvider.notifier).state = query.trim();
    });
  }

  Future<void> _onRefresh() async {
    ref.invalidate(newsListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final newsState = ref.watch(newsListProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final theme = Theme.of(context);

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
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
            child: newsState.when(
              data: (articles) {
                if (articles.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 100 + MediaQuery.paddingOf(context).bottom),
                    itemCount: articles.length + 1, // +1 for loading indicator at the bottom
                    itemBuilder: (context, index) {
                      if (index == articles.length) {
                        return _buildBottomLoader();
                      }
                      
                      final article = articles[index];
                      return NewsCard(
                        article: article,
                        currentUserId: currentUserId,
                        onTap: () => context.push('/news/${article.id}'),
                        onLike: () async {
                          HapticFeedback.lightImpact();
                          try {
                            await ref.read(newsInteractionProvider).vote(article.id, 'UPVOTE');
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                            }
                          }
                        },
                        onDislike: () async {
                          HapticFeedback.lightImpact();
                          try {
                            await ref.read(newsInteractionProvider).vote(article.id, 'DOWNVOTE');
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                            }
                          }
                        },
                        onCommentTap: () {
                          // Переходимо до новини і одразу скролимо до коментарів
                          context.push('/news/${article.id}?comments=true');
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const ShimmerLoadingList(),
              error: (error, stack) => CommonErrorWidget(
                error: error.toString(),
                onRetry: _onRefresh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return FutureBuilder<List<NewsCategory>>(
      future: ref.watch(newsCategoriesProvider),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final categories = snapshot.data!;
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
      },
    );
  }

  Widget _buildBottomLoader() {
    final hasMore = ref.read(newsListProvider.notifier).hasMore;
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Ви переглянули всі новини', style: TextStyle(color: Colors.grey)),
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
          Icon(Icons.newspaper, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Немає новин',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _onRefresh,
            child: const Text('Оновити'),
          ),
        ],
      ),
    );
  }
}