import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/backup/domain/backup_envelope.dart';
import 'package:mood_tracker/features/backup/domain/import_mode.dart';

void main() {
  test('currentSchema is 1', () {
    expect(BackupEnvelope.currentSchema, 1);
  });

  test('value equality on identical envelopes', () {
    final a = BackupEnvelope(
      schema: 1,
      exportedAt: DateTime.utc(2026, 5, 18),
      appVersion: '1.0.0+1',
      entries: const [],
    );
    final b = BackupEnvelope(
      schema: 1,
      exportedAt: DateTime.utc(2026, 5, 18),
      appVersion: '1.0.0+1',
      entries: const [],
    );
    expect(a, b);
  });

  test('ImportMode has merge and replace', () {
    expect(ImportMode.values, [ImportMode.merge, ImportMode.replace]);
  });
}
