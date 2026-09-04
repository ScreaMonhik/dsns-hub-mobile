import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/project_providers.dart';
import '../../data/models/project_models.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      await ref.read(projectInteractionProvider).addComment(widget.projectId, text);
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleVote(String type) async {
    HapticFeedback.lightImpact();
    try {
      await ref.read(projectInteractionProvider).vote(widget.projectId, type);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectDetailProvider(widget.projectId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('Деталі проєкту')),
      body: projectState.when(
        data: (project) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title ?? 'Без назви',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, height: 1.3),
                      ),
                      const SizedBox(height: 16),
                      if (project.author != null)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              backgroundImage: project.author!.avatarUrl != null ? NetworkImage(project.author!.avatarUrl!) : null,
                              child: project.author!.avatarUrl == null
                                  ? Text(project.author!.firstName?.isNotEmpty == true ? project.author!.firstName![0].toUpperCase() : '?',
                                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontSize: 12))
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${project.author!.firstName ?? 'Гість'} ${project.author!.lastName ?? ''}'.trim(),
                              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      Text(
                        project.description ?? 'Опис відсутній',
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      if (project.fileUrl != null && project.fileUrl!.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: () => context.push('/projects/${project.id}/pdf', extra: project),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Переглянути документ проєкту'),
                            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildInteractionButton(
                            icon: project.currentUserVote == 'UPVOTE' ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                            label: '${project.upvotes}',
                            isActive: project.currentUserVote == 'UPVOTE',
                            activeColor: Colors.green.shade600,
                            onTap: () => _handleVote('UPVOTE'),
                          ),
                          const SizedBox(width: 16),
                          _buildInteractionButton(
                            icon: project.currentUserVote == 'DOWNVOTE' ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                            label: '${project.downvotes}',
                            isActive: project.currentUserVote == 'DOWNVOTE',
                            activeColor: Colors.red.shade600,
                            onTap: () => _handleVote('DOWNVOTE'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Обговорення', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (project.comments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(child: Text('Немає коментарів. Будьте першим!')),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: project.comments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) => _buildCommentTile(project.comments[index], theme),
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
        error: (error, _) => Center(child: Text('Помилка: $error')),
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
            Text(label, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: displayColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(ProjectComment comment, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: comment.author?.avatarUrl != null ? NetworkImage(comment.author!.avatarUrl!) : null,
          child: comment.author?.avatarUrl == null 
            ? Text(comment.author?.firstName?.isNotEmpty == true ? comment.author!.firstName![0].toUpperCase() : '?',
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold))
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
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${comment.author?.firstName ?? 'Гість'} ${comment.author?.lastName ?? ''}'.trim(),
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(comment.content ?? '', style: theme.textTheme.bodyMedium?.copyWith(height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  comment.createdAt != null ? DateFormat('dd MMM HH:mm').format(comment.createdAt!.toLocal()) : '',
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
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
                    hintText: 'Додати коментар...',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                child: IconButton(
                  icon: _isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
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