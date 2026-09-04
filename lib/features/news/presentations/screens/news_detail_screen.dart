import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/news_providers.dart';
import '../widgets/tiptap_renderer.dart';
import '../../data/models/news_models.dart';
import '../../../../core/presentation/widgets/auth_network_image.dart';
import '../../../auth/providers/auth_provider.dart';

class NewsDetailScreen extends ConsumerStatefulWidget {
  final String newsId;
  final bool scrollToComments;

  const NewsDetailScreen({
    super.key, 
    required this.newsId,
    this.scrollToComments = false,
  });

  @override
  ConsumerState<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends ConsumerState<NewsDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentsSectionKey = GlobalKey();
  
  bool _hasScrolled = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      await ref.read(newsInteractionProvider).addComment(widget.newsId, text);
      _commentController.clear();
      FocusScope.of(context).unfocus();
      
      // Скрол до кінця після додавання коментаря
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsState = ref.watch(newsDetailProvider(widget.newsId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Новина'),
      ),
      body: newsState.when(
        data: (article) {
          // Автоскрол до коментарів при переході
          if (widget.scrollToComments && !_hasScrolled) {
            _hasScrolled = true; // Set immediately to prevent repeated triggers
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Add a delay to allow dynamic content (TipTap, Images) to fully render and calculate exact layout height
              Future.delayed(const Duration(milliseconds: 600), () {
                if (_commentsSectionKey.currentContext != null && mounted) {
                  Scrollable.ensureVisible(
                    _commentsSectionKey.currentContext!,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    alignment: 0.05, // Align slightly below the top edge of the screen
                  );
                }
              });
            });
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Категорія та Дата (без автора)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (article.category != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                article.category?.name ?? 'Без категорії',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          Text(
                            article.createdAt != null 
                                ? DateFormat('dd MMMM yyyy, HH:mm').format(article.createdAt!.toLocal())
                                : 'Дата не вказана',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        article.title ?? 'Без назви',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (article.imageUrl != null && article.imageUrl!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AuthNetworkImage(
                            imageUrl: article.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Рендерер JSON від TipTap
                      if (article.content != null)
                        TipTapRenderer(jsonContent: article.content!),
                      
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Панель дій (Лайки / Дизлайки)
                      Row(
                        children: [
                          _buildInteractionButton(
                            icon: article.currentUserVote == 'UPVOTE' 
                                ? Icons.thumb_up 
                                : Icons.thumb_up_alt_outlined,
                            label: '${article.upvotes > 0 ? article.upvotes : (article.count?.likes ?? 0)}',
                            isActive: article.currentUserVote == 'UPVOTE',
                            activeColor: Colors.green.shade600,
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              try {
                                await ref.read(newsInteractionProvider).vote(article.id, 'UPVOTE');
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                                }
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          _buildInteractionButton(
                            icon: article.currentUserVote == 'DOWNVOTE' 
                                ? Icons.thumb_down 
                                : Icons.thumb_down_alt_outlined,
                            label: '${article.downvotes > 0 ? article.downvotes : (article.count?.dislikes ?? 0)}',
                            isActive: article.currentUserVote == 'DOWNVOTE',
                            activeColor: Colors.red.shade600,
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              try {
                                await ref.read(newsInteractionProvider).vote(article.id, 'DOWNVOTE');
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                                }
                              }
                            },
                          ),
                          const Spacer(),
                          Icon(Icons.comment_outlined, size: 20, color: theme.colorScheme.outline),
                          const SizedBox(width: 8),
                          Text(
                            '${article.count?.comments ?? 0}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Блок коментарів
                      Container(
                        key: _commentsSectionKey,
                        child: Text(
                          'Коментарі',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (article.comments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(
                            child: Text(
                              'Немає коментарів. Будьте першим!',
                              style: TextStyle(color: theme.colorScheme.outline),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: article.comments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) => _buildCommentTile(article.comments[index], theme),
                        ),
                    ],
                  ),
                ),
              ),
              _buildCommentInput(theme),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Помилка: $error')),
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
    required Color activeColor,
  }) {
    final theme = Theme.of(context);
    final displayColor = isActive ? activeColor : theme.colorScheme.onSurfaceVariant;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: displayColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(NewsComment comment, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: comment.author?.avatarUrl != null 
            ? NetworkImage(comment.author!.avatarUrl!) 
            : null,
          child: comment.author?.avatarUrl == null 
            ? Text(
                comment.author?.firstName?.isNotEmpty == true ? comment.author!.firstName![0].toUpperCase() : '?',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
              )
            : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${comment.author?.firstName ?? 'Гість'} ${comment.author?.lastName ?? ''}'.trim(),
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comment.content ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  comment.createdAt != null 
                      ? DateFormat('dd MMM HH:mm').format(comment.createdAt!.toLocal())
                      : '',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                  decoration: InputDecoration(
                    hintText: 'Написати коментар...',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: _isSubmitting ? null : _submitComment,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}