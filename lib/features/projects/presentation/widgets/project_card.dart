import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/project_models.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = project.createdAt != null 
        ? DateFormat('dd MMM yyyy').format(project.createdAt!.toLocal())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Ініціатива',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      dateText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  project.title ?? 'Без назви',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (project.description != null && project.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    project.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
                          icon: project.currentUserVote == 'UPVOTE' ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                          label: '${project.upvotes}',
                          onTap: onLike,
                          isActive: project.currentUserVote == 'UPVOTE',
                          activeColor: Colors.green.shade600,
                        ),
                        const SizedBox(width: 16),
                        _buildActionButton(
                          context: context,
                          icon: project.currentUserVote == 'DOWNVOTE' ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                          label: '${project.downvotes}',
                          onTap: onDislike,
                          isActive: project.currentUserVote == 'DOWNVOTE',
                          activeColor: Colors.red.shade600,
                        ),
                      ],
                    ),
                    _buildActionButton(
                      context: context,
                      icon: Icons.comment_outlined,
                      label: '${project.count?.comments ?? 0}',
                      onTap: onTap,
                      isActive: false,
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: displayColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(color: displayColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}