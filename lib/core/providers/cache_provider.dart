import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final cacheProvider = StateNotifierProvider<CacheNotifier, AsyncValue<String>>((ref) {
  return CacheNotifier()..calculateCache();
});

class CacheNotifier extends StateNotifier<AsyncValue<String>> {
  CacheNotifier() : super(const AsyncValue.loading());

  Future<void> calculateCache() async {
    state = const AsyncValue.loading();
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true, followLinks: false).forEach((FileSystemEntity entity) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }
      
      state = AsyncValue.data(_formatBytes(totalSize));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearCache() async {
    state = const AsyncValue.loading();
    try {
      final tempDir = await getTemporaryDirectory();
      
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true, followLinks: false).forEach((FileSystemEntity entity) {
          try {
            if (entity is File) {
              entity.deleteSync();
            } else if (entity is Directory) {
              entity.deleteSync(recursive: true);
            }
          } catch (_) {
            // Ignore files that are locked by the system or currently in use
          }
        });
      }
      
      await calculateCache();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0.00 МБ";
    final mb = bytes / (1024 * 1024);
    return "${mb.toStringAsFixed(2)} МБ";
  }
}