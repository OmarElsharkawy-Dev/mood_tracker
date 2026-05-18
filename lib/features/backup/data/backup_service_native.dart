import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/error/failure.dart';
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/repositories/mood_entry_repository.dart';
import '../domain/backup_envelope.dart';
import '../domain/import_mode.dart';
import 'backup_codec.dart';
import 'backup_service.dart';

typedef ShareFn = Future<void> Function(String filePath);
typedef PickFileFn = Future<File?> Function();
typedef TempDirFn = Future<Directory> Function();

class BackupServiceImpl implements BackupService {
  BackupServiceImpl({
    required this.repo,
    required this.appVersion,
    required this.tempDir,
    required this.share,
    required this.pickFile,
  });

  final MoodEntryRepository repo;
  final String appVersion;
  final TempDirFn tempDir;
  final ShareFn share;
  final PickFileFn pickFile;

  @override
  Future<(String?, Failure?)> exportAndShare() async {
    try {
      final (entries, err) = await repo.getAll();
      if (err != null) return (null, err);
      final env = BackupEnvelope(
        schema: BackupEnvelope.currentSchema,
        exportedAt: DateTime.now().toUtc(),
        appVersion: appVersion,
        entries: entries ?? const [],
      );
      final dir = await tempDir();
      final today = DateTime.now().toUtc();
      final yyyy = today.year.toString().padLeft(4, '0');
      final mm = today.month.toString().padLeft(2, '0');
      final dd = today.day.toString().padLeft(2, '0');
      final filename = 'mood_tracker_export_$yyyy-$mm-$dd.json';
      final file = File('${dir.path}/$filename');
      await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(envelopeToJson(env)));
      await share(file.path);
      return (filename, null);
    } catch (e) {
      return (null, _ioFailure(e));
    }
  }

  @override
  Future<(int?, Failure?)> pickAndImport(ImportMode mode) async {
    try {
      final file = await pickFile();
      if (file == null) {
        return (null, _validationFailure('backupErrorPickCanceled'));
      }
      final raw = await file.readAsString();
      late final BackupEnvelope env;
      try {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        env = envelopeFromJson(decoded);
      } on BackupFormatException catch (e) {
        return (null, _validationFailure(e.messageKey));
      } catch (_) {
        return (null, _validationFailure('backupErrorParseFailed'));
      }

      if (mode == ImportMode.replace) {
        final (existing, err) = await repo.getAll();
        if (err != null) return (null, err);
        for (final e in existing ?? const <MoodEntry>[]) {
          await repo.delete(e.id);
        }
      }

      var imported = 0;
      final (existingNow, _) = await repo.getAll();
      final existingIds =
          (existingNow ?? const <MoodEntry>[]).map((e) => e.id).toSet();
      for (final e in env.entries) {
        if (mode == ImportMode.merge && existingIds.contains(e.id)) continue;
        final (_, err) = await repo.create(e);
        if (err == null) imported++;
      }
      return (imported, null);
    } catch (e) {
      return (null, _ioFailure(e));
    }
  }

  Failure _validationFailure(String key) =>
      ValidationFailure(fieldErrors: {'backup': key});

  Failure _ioFailure(Object e) => IOFailure(debugMessage: e.toString());
}
