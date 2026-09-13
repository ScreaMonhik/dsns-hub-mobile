import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/offline/download_manager.dart';
import '../../../../core/presentation/widgets/common_error_widget.dart';
import '../../../documents/data/models/document_models.dart';
import '../../../projects/data/models/project_models.dart';

class OfflineDownloadsScreen extends ConsumerWidget {
  const OfflineDownloadsScreen({super.key, required this.kind});

  final OfflineDownloadKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(offlineDownloadsProvider(kind));
    final title = kind == OfflineDownloadKind.document
        ? 'Завантажені документи'
        : 'Завантажені проєкти';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: downloads.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                'Ще немає файлів для офлайн-доступу',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return Dismissible(
                key: ValueKey('${item.kind.name}-${item.remoteId}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                ),
                onDismissed: (_) async {
                  await ref.read(downloadManagerProvider).remove(item.remoteId, item.kind);
                  ref.invalidate(offlineDownloadsProvider(kind));
                },
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(item.title),
                  subtitle: Text(_formatSize(item.fileSize)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, item),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => CommonErrorWidget(
          error: error.toString(),
          onRetry: () => ref.invalidate(offlineDownloadsProvider(kind)),
        ),
      ),
    );
  }

  void _open(BuildContext context, DownloadedFile item) {
    if (item.kind == OfflineDownloadKind.document) {
      context.push(
        '/documents/view',
        extra: DocumentModel(
          id: item.remoteId,
          title: item.title,
          fileUrl: item.remoteUrl,
        ),
      );
      return;
    }

    context.push(
      '/projects/${item.remoteId}/pdf',
      extra: ProjectModel(
        id: item.remoteId,
        title: item.title,
        fileUrl: item.remoteUrl,
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return 'PDF';
    final mb = bytes / (1024 * 1024);
    if (mb < 0.1) {
      return '${(bytes / 1024).toStringAsFixed(0)} КБ';
    }
    return '${mb.toStringAsFixed(1)} МБ';
  }
}
