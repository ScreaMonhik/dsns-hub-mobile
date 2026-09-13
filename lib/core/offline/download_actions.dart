import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/utils/app_snackbar.dart';
import 'download_manager.dart';

Future<void> showDownloadPopup({
  required BuildContext context,
  required WidgetRef ref,
  required String remoteId,
  required OfflineDownloadKind kind,
  required String title,
  required String? remoteUrl,
}) async {
  if (remoteUrl == null || remoteUrl.isEmpty) {
    AppSnackBar.showError(context, 'Файл відсутній');
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Завантажити'),
          subtitle: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () async {
            Navigator.pop(sheetContext);
            await downloadAndNotify(
              context: context,
              ref: ref,
              remoteId: remoteId,
              kind: kind,
              title: title,
              remoteUrl: remoteUrl,
            );
          },
        ),
      );
    },
  );
}

Future<void> downloadAndNotify({
  required BuildContext context,
  required WidgetRef ref,
  required String remoteId,
  required OfflineDownloadKind kind,
  required String title,
  required String remoteUrl,
  String? localPath,
}) async {
  try {
    final manager = ref.read(downloadManagerProvider);
    if (localPath != null) {
      await manager.persistExisting(
        remoteId: remoteId,
        kind: kind,
        title: title,
        remoteUrl: remoteUrl,
        localPath: localPath,
      );
    } else {
      await manager.download(
        remoteId: remoteId,
        kind: kind,
        title: title,
        remoteUrl: remoteUrl,
      );
    }
    ref.invalidate(offlineDownloadsProvider(kind));
    if (context.mounted) {
      AppSnackBar.showSuccess(context, 'Файл збережено для офлайн-доступу');
    }
  } catch (_) {
    if (context.mounted) {
      AppSnackBar.showError(context, 'Не вдалося завантажити файл');
    }
  }
}
