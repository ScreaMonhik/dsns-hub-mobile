import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../offline/offline_cache.dart';

final cacheProvider = StateNotifierProvider<CacheNotifier, AsyncValue<String>>((ref) {
  return CacheNotifier(ref)..calculateCache();
});

class CacheNotifier extends StateNotifier<AsyncValue<String>> {
  CacheNotifier(this._ref) : super(const AsyncValue.loading());

  final Ref _ref;

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

      await DefaultCacheManager().emptyCache();
      await _ref.read(offlineCacheProvider).clear();
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
