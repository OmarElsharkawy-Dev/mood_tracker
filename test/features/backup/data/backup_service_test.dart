import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/features/backup/data/backup_service.dart';
import 'package:mood_tracker/features/backup/domain/import_mode.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';

class _MemRepo implements MoodEntryRepository {
  final Map<String, MoodEntry> _store = {};
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) =>
      Stream.value(_store.values.toList());
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (_store.values.toList(), null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry entry) async {
    _store[entry.id] = entry;
    return (entry, null);
  }
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry entry) async {
    _store[entry.id] = entry;
    return (entry, null);
  }
  @override
  Future<(Unit?, Failure?)> delete(String id) async {
    _store.remove(id);
    return (Unit.value, null);
  }
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      _store.containsKey(id) ? (_store[id], null) : (null, NotFoundFailure(id: id));
}

MoodEntry _entry(String id, {Mood mood = Mood.okay}) {
  final t = DateTime.utc(2026, 5, 17, 12);
  return MoodEntry(
    id: id, occurredAt: t, mood: mood, intensity: 5, note: null,
    tags: const [], sleepHours: null, energy: EnergyLevel.medium,
    createdAt: t, updatedAt: t,
  );
}

void main() {
  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_service_test');
  });
  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('exportAndShare writes JSON file with expected entries', () async {
    final repo = _MemRepo();
    await repo.create(_entry('a'));
    await repo.create(_entry('b'));
    String? sharedPath;
    final svc = BackupServiceImpl(
      repo: repo,
      appVersion: '1.0.0+1',
      tempDir: () async => tempDir,
      share: (path) async { sharedPath = path; },
      pickFile: () async => null,
    );
    final (filename, err) = await svc.exportAndShare();
    expect(err, isNull);
    expect(filename, isNotNull);
    expect(sharedPath, isNotNull);
    final file = File(sharedPath!);
    expect(await file.exists(), true);
    final decoded = json.decode(await file.readAsString()) as Map<String, dynamic>;
    expect(decoded['schema'], 1);
    expect((decoded['entries'] as List).length, 2);
  });

  test('pickAndImport(merge) skips duplicate IDs', () async {
    final repo = _MemRepo();
    await repo.create(_entry('a', mood: Mood.bad));
    final tmpFile = File('${tempDir.path}/in.json');
    await tmpFile.writeAsString(json.encode({
      'schema': 1,
      'exportedAt': DateTime.utc(2026).toIso8601String(),
      'appVersion': 'x',
      'entries': [
        {'id': 'a', 'occurredAt': 0, 'mood': 'great', 'intensity': 5, 'note': null, 'tags': <String>[], 'sleepHours': null, 'energy': 'medium', 'createdAt': 0, 'updatedAt': 0},
        {'id': 'b', 'occurredAt': 0, 'mood': 'good', 'intensity': 5, 'note': null, 'tags': <String>[], 'sleepHours': null, 'energy': 'medium', 'createdAt': 0, 'updatedAt': 0},
      ],
    }));
    final svc = BackupServiceImpl(
      repo: repo, appVersion: '1.0.0+1',
      tempDir: () async => tempDir,
      share: (_) async {},
      pickFile: () async => tmpFile,
    );
    final (count, err) = await svc.pickAndImport(ImportMode.merge);
    expect(err, isNull);
    expect(count, 1);
    final (all, _) = await repo.getAll();
    expect(all!.length, 2);
    expect(all.firstWhere((e) => e.id == 'a').mood, Mood.bad);
  });

  test('pickAndImport(replace) wipes existing then loads file', () async {
    final repo = _MemRepo();
    await repo.create(_entry('old1'));
    await repo.create(_entry('old2'));
    final tmpFile = File('${tempDir.path}/in.json');
    await tmpFile.writeAsString(json.encode({
      'schema': 1,
      'exportedAt': DateTime.utc(2026).toIso8601String(),
      'appVersion': 'x',
      'entries': [
        {'id': 'new1', 'occurredAt': 0, 'mood': 'good', 'intensity': 5, 'note': null, 'tags': <String>[], 'sleepHours': null, 'energy': 'medium', 'createdAt': 0, 'updatedAt': 0},
      ],
    }));
    final svc = BackupServiceImpl(
      repo: repo, appVersion: '1.0.0+1',
      tempDir: () async => tempDir,
      share: (_) async {},
      pickFile: () async => tmpFile,
    );
    final (count, err) = await svc.pickAndImport(ImportMode.replace);
    expect(err, isNull);
    expect(count, 1);
    final (all, _) = await repo.getAll();
    expect(all!.length, 1);
    expect(all.single.id, 'new1');
  });

  test('pickAndImport returns ValidationFailure on malformed JSON', () async {
    final repo = _MemRepo();
    final tmpFile = File('${tempDir.path}/in.json');
    await tmpFile.writeAsString('{this is not json');
    final svc = BackupServiceImpl(
      repo: repo, appVersion: '1.0.0+1',
      tempDir: () async => tempDir,
      share: (_) async {},
      pickFile: () async => tmpFile,
    );
    final (count, err) = await svc.pickAndImport(ImportMode.merge);
    expect(count, isNull);
    expect(err, isA<ValidationFailure>());
  });

  test('pickAndImport returns ValidationFailure when no file picked', () async {
    final repo = _MemRepo();
    final svc = BackupServiceImpl(
      repo: repo, appVersion: '1.0.0+1',
      tempDir: () async => tempDir,
      share: (_) async {},
      pickFile: () async => null,
    );
    final (count, err) = await svc.pickAndImport(ImportMode.merge);
    expect(count, isNull);
    expect(err, isA<ValidationFailure>());
  });
}
