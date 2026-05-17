import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('opens at schema version 1', () async {
    expect(db.schemaVersion, 1);
  });

  test('migration creates indexes', () async {
    // Touching customSelect triggers Drift's open-on-demand which runs onCreate.
    final entries = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type='index' "
      "AND name IN ('idx_entries_occurred_at','idx_entry_tags_tag_id')",
    ).get();
    expect(entries.length, 2);
  });
}
