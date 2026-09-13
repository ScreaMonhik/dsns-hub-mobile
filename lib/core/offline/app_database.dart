import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class ApiCacheEntries extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}

class OfflineDownloads extends Table {
  TextColumn get remoteId => text()();
  TextColumn get kind => text()();
  TextColumn get title => text()();
  TextColumn get filePath => text()();
  TextColumn get remoteUrl => text()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  DateTimeColumn get downloadedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {remoteId, kind};
}

@DriftDatabase(tables: [ApiCacheEntries, OfflineDownloads])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'dsns_hub_offline');
}
