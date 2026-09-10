import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final cacheProvider = StateNotifierProvider<CacheNotifier, AsyncValue<String>>((ref) {
  return CacheNotifier()..calculateCache();
});

class CacheNotifier extends StateNotifier<AsyncValue<String>> {
  CacheNotifier() : super(const AsyncValue.loading());

  Future<int> _directorySize(Directory dir) async {
    var totalSize = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          totalSize += await entity.length();
        } catch (_) {}
      }
    }
    return totalSize;
  }

  Future<void> calculateCache() async {
    state = const AsyncValue.loading();
    try {
      final tempDir = await getTemporaryDirectory();
      final totalSize = tempDir.existsSync() ? await _directorySize(tempDir) : 0;
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
        await for (final entity in tempDir.list(followLinks: false)) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
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
