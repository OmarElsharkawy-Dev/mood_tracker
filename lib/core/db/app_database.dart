import 'package:drift/drift.dart';

import 'connection/connection.dart' as impl;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Entries, Tags, EntryTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.openConnection());

  /// In-memory constructor for tests.
  // ignore: use_super_parameters
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE INDEX idx_entries_occurred_at ON entries(occurred_at)');
          await customStatement(
              'CREATE INDEX idx_entry_tags_tag_id ON entry_tags(tag_id)');
        },
      );
}
