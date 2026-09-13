import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../network/dio_provider.dart';
import '../utils/safe_file.dart';
import 'app_database.dart';
import 'offline_cache.dart';

enum OfflineDownloadKind { document, project }

class DownloadedFile {
  const DownloadedFile({
    required this.remoteId,
    required this.kind,
    required this.title,
    required this.filePath,
    required this.remoteUrl,
    required this.fileSize,
    required this.downloadedAt,
  });

  final String remoteId;
  final OfflineDownloadKind kind;
  final String title;
  final String filePath;
  final String remoteUrl;
  final int fileSize;
  final DateTime downloadedAt;

  bool get fileExists => File(filePath).existsSync();
}

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  return DownloadManager(ref.watch(appDatabaseProvider), ref.watch(dioProvider));
});

final offlineDownloadsProvider = FutureProvider.family<List<DownloadedFile>, OfflineDownloadKind>((ref, kind) {
  return ref.watch(downloadManagerProvider).list(kind);
});

class DownloadManager {
  DownloadManager(this._db, this._dio);

  final AppDatabase _db;
  final Dio _dio;

  Future<Directory> _kindDirectory(OfflineDownloadKind kind) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}offline_pdfs${Platform.pathSeparator}${kind.name}');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<DownloadedFile?> find(String remoteId, OfflineDownloadKind kind) async {
    final row = await (_db.select(_db.offlineDownloads)
          ..where((tbl) => tbl.remoteId.equals(remoteId) & tbl.kind.equals(kind.name)))
        .getSingleOrNull();
    if (row == null) return null;
    return _fromRow(row);
  }

  Future<bool> isDownloaded(String remoteId, OfflineDownloadKind kind) async {
    final item = await find(remoteId, kind);
    return item != null && item.fileExists;
  }

  Future<List<DownloadedFile>> list(OfflineDownloadKind kind) async {
    final rows = await (_db.select(_db.offlineDownloads)
          ..where((tbl) => tbl.kind.equals(kind.name))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.downloadedAt)]))
        .get();
    return rows.map(_fromRow).where((item) => item.fileExists).toList();
  }

  Future<DownloadedFile> download({
    required String remoteId,
    required OfflineDownloadKind kind,
    required String title,
    required String remoteUrl,
  }) async {
    final existing = await find(remoteId, kind);
    if (existing != null && existing.fileExists) {
      return existing;
    }

    final dir = await _kindDirectory(kind);
    final remoteName = remoteUrl.split('/').last;
    final savePath = resolveDocumentsSavePath(dir, '${remoteId}_$remoteName');

    await _dio.download(
      remoteUrl,
      savePath,
      options: Options(receiveTimeout: const Duration(minutes: 2)),
    );

    final size = await File(savePath).length();
    return _upsert(
      remoteId: remoteId,
      kind: kind,
      title: title,
      remoteUrl: remoteUrl,
      filePath: savePath,
      fileSize: size,
    );
  }

  Future<DownloadedFile> persistExisting({
    required String remoteId,
    required OfflineDownloadKind kind,
    required String title,
    required String remoteUrl,
    required String localPath,
  }) async {
    final source = File(localPath);
    if (!source.existsSync()) {
      return download(
        remoteId: remoteId,
        kind: kind,
        title: title,
        remoteUrl: remoteUrl,
      );
    }

    final existing = await find(remoteId, kind);
    if (existing != null && existing.fileExists) {
      return existing;
    }

    final dir = await _kindDirectory(kind);
    final remoteName = remoteUrl.split('/').last;
    final savePath = resolveDocumentsSavePath(dir, '${remoteId}_$remoteName');
    if (source.path != savePath) {
      await source.copy(savePath);
    }

    final size = await File(savePath).length();
    return _upsert(
      remoteId: remoteId,
      kind: kind,
      title: title,
      remoteUrl: remoteUrl,
      filePath: savePath,
      fileSize: size,
    );
  }

  Future<void> remove(String remoteId, OfflineDownloadKind kind) async {
    final existing = await find(remoteId, kind);
    if (existing != null) {
      final file = File(existing.filePath);
      if (file.existsSync()) {
        await file.delete();
      }
    }
    await (_db.delete(_db.offlineDownloads)
          ..where((tbl) => tbl.remoteId.equals(remoteId) & tbl.kind.equals(kind.name)))
        .go();
  }

  Future<DownloadedFile> _upsert({
    required String remoteId,
    required OfflineDownloadKind kind,
    required String title,
    required String remoteUrl,
    required String filePath,
    required int fileSize,
  }) async {
    final downloadedAt = DateTime.now().toUtc();
    await _db.into(_db.offlineDownloads).insertOnConflictUpdate(
          OfflineDownloadsCompanion.insert(
            remoteId: remoteId,
            kind: kind.name,
            title: title,
            filePath: filePath,
            remoteUrl: remoteUrl,
            fileSize: Value(fileSize),
            downloadedAt: downloadedAt,
          ),
        );
    return DownloadedFile(
      remoteId: remoteId,
      kind: kind,
      title: title,
      filePath: filePath,
      remoteUrl: remoteUrl,
      fileSize: fileSize,
      downloadedAt: downloadedAt,
    );
  }

  DownloadedFile _fromRow(OfflineDownload row) {
    return DownloadedFile(
      remoteId: row.remoteId,
      kind: OfflineDownloadKind.values.byName(row.kind),
      title: row.title,
      filePath: row.filePath,
      remoteUrl: row.remoteUrl,
      fileSize: row.fileSize,
      downloadedAt: row.downloadedAt,
    );
  }
}
