import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final offlineCacheProvider = Provider<OfflineCache>((ref) {
  return OfflineCache(ref.watch(appDatabaseProvider));
});

class OfflineCache {
  OfflineCache(this._db);

  final AppDatabase _db;

  Future<void> put(String key, Object? data) async {
    await _db.into(_db.apiCacheEntries).insertOnConflictUpdate(
          ApiCacheEntriesCompanion.insert(
            cacheKey: key,
            payload: jsonEncode(data),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<Object?> get(String key) async {
    final row = await (_db.select(_db.apiCacheEntries)
          ..where((tbl) => tbl.cacheKey.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    return jsonDecode(row.payload);
  }

  Future<void> clear() {
    return _db.delete(_db.apiCacheEntries).go();
  }
}
