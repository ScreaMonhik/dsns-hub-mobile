import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/news_models.dart';
import 'tiptap_renderer.dart';
import '../../../../core/presentation/widgets/auth_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NewsCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onCommentTap;
  final String? currentUserId;
  final int index;

  const NewsCard({
    super.key,
    required this.article,
    required this.onTap,
    required this.onLike,
    required this.onDislike,
    required this.onCommentTap,
    this.currentUserId,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: AuthNetworkImage(
                  imageUrl: article.imageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (article.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            article.category?.name ?? 'Без категорії',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Text(
                        article.createdAt != null 
                            ? DateFormat('dd MMM yyyy, HH:mm').format(article.createdAt!.toLocal())
                            : 'Дата не вказана',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article.title ?? 'Без назви',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Using TipTap extractor to display clean text
                  if (article.content != null && article.content!.isNotEmpty)
                    Text(
                      TipTapHelper.extractPlainText(article.content!),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildActionButton(
                            context: context,
                            activeIcon: Icons.thumb_up,
                            inactiveIcon: Icons.thumb_up_alt_outlined,
                            label: '${article.upvotes > 0 ? article.upvotes : (article.count?.likes ?? 0)}',
                            onTap: onLike,
                            isActive: article.currentUserVote == 'UPVOTE',
                            activeColor: Colors.green.shade600,
                          ),
                          const SizedBox(width: 16),
                          _buildActionButton(
                            context: context,
                            activeIcon: Icons.thumb_down,
                            inactiveIcon: Icons.thumb_down_alt_outlined,
                            label: '${article.downvotes > 0 ? article.downvotes : (article.count?.dislikes ?? 0)}',
                            onTap: onDislike,
                            isActive: article.currentUserVote == 'DOWNVOTE',
                            activeColor: Colors.red.shade600,
                          ),
                        ],
                      ),
                      _buildActionButton(
                        context: context,
                        activeIcon: Icons.comment,
                        inactiveIcon: Icons.comment_outlined,
                        label: '${article.count?.comments ?? 0}',
                        onTap: onCommentTap,
                        isActive: false,
                        activeColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )).animate(delay: (index % 10 * 50).ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
    required Color activeColor,
  }) {
    final theme = Theme.of(context);
    final displayColor = isActive ? activeColor : theme.colorScheme.onSurfaceVariant;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(inactiveIcon, size: 22, color: theme.colorScheme.onSurfaceVariant),
                if (isActive)
                  Icon(activeIcon, size: 22, color: activeColor)
                      .animate()
                      .scale(
                        begin: const Offset(0.0, 0.0),
                        end: const Offset(1.0, 1.0),
                        duration: 350.ms,
                        curve: Curves.easeOutBack, // Легке вистрибування контуру
                      )
                      .fade(duration: 150.ms),
              ],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: displayColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate(key: ValueKey('${activeIcon.codePoint}_$isActive')).scale(
      begin: const Offset(0.9, 0.9), // Стискання кнопки при натисканні
      end: const Offset(1.0, 1.0),
      duration: 200.ms,
      curve: Curves.easeOut,
    );
  }
}