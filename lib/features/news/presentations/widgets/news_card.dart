import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/news_models.dart';
import 'tiptap_renderer.dart';
import '../../../../core/presentation/widgets/auth_network_image.dart';

class NewsCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onCommentTap;
  final String? currentUserId;

  const NewsCard({
    super.key,
    required this.article,
    required this.onTap,
    required this.onLike,
    required this.onDislike,
    required this.onCommentTap,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                            article.category!.name,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(article.createdAt.toLocal()),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Using TipTap extractor to display clean text
                  Text(
                    TipTapHelper.extractPlainText(article.content),
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
                            icon: article.votes.any((v) => v.voteType == 'UPVOTE' && v.userId == currentUserId) 
                                ? Icons.thumb_up 
                                : Icons.thumb_up_alt_outlined,
                            label: '${article.upvotes > 0 ? article.upvotes : (article.count?.likes ?? 0)}',
                            onTap: onLike,
                            isActive: article.votes.any((v) => v.voteType == 'UPVOTE' && v.userId == currentUserId),
                            activeColor: Colors.green.shade600,
                          ),
                          const SizedBox(width: 16),
                          _buildActionButton(
                            context: context,
                            icon: article.votes.any((v) => v.voteType == 'DOWNVOTE' && v.userId == currentUserId) 
                                ? Icons.thumb_down 
                                : Icons.thumb_down_alt_outlined,
                            label: '${article.downvotes > 0 ? article.downvotes : (article.count?.dislikes ?? 0)}',
                            onTap: onDislike,
                            isActive: article.votes.any((v) => v.voteType == 'DOWNVOTE' && v.userId == currentUserId),
                            activeColor: Colors.red.shade600,
                          ),
                        ],
                      ),
                      _buildActionButton(
                        context: context,
                        icon: Icons.comment_outlined,
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
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isActive 
              ? activeColor.withValues(alpha: 0.1) 
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: isActive 
              ? Border.all(color: activeColor.withValues(alpha: 0.3)) 
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              size: 20, 
              color: displayColor,
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
    );
  }
}