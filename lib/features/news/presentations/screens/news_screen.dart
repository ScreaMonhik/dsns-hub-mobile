import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/news_models.dart';
import 'package:dsns_hub/core/presentation/widgets/filter_choice_chip.dart';
import '../providers/news_providers.dart';
import '../widgets/news_card.dart';
import '../../../profile/presentation/widgets/user_profile_button.dart';
import '../../../auth/providers/auth_provider.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(newsListProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    // Invalidate the provider to force a complete reload
    ref.invalidate(newsListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final newsState = ref.watch(newsListProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новини'),
        actions: const [UserProfileButton()],
      ),
      body: Column(
        children: [
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
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          try {
                            await ref.read(newsInteractionProvider).vote(article.id, 'UPVOTE');
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                            }
                          }
                        },
                        onDislike: () async {
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error.toString()),
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
                      ref.read(selectedCategoryProvider.notifier).state = null;
                    }
                  },
                ),
                ...categories.map((category) {
                  final isSelected = selectedCategoryId == category.id;
                  return FilterChoiceChip(
                    label: category.name,
                    isSelected: isSelected,
                    onSelected: () {
                      if (!isSelected) {
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Сталася помилка при завантаженні новин',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Спробувати ще раз'),
            ),
          ],
        ),
      ),
    );
  }
}