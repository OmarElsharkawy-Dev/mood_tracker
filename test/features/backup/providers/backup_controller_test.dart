import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/features/backup/data/backup_service.dart';
import 'package:mood_tracker/features/backup/data/backup_service_provider.dart';
import 'package:mood_tracker/features/backup/domain/import_mode.dart';
import 'package:mood_tracker/features/backup/providers/backup_controller.dart';

class _FakeService implements BackupService {
  (String?, Failure?) exportResult = ('file.json', null);
  (int?, Failure?) importResult = (3, null);
  ImportMode? lastMode;

  @override
  Future<(String?, Failure?)> exportAndShare() async => exportResult;
  @override
  Future<(int?, Failure?)> pickAndImport(ImportMode mode) async {
    lastMode = mode;
    return importResult;
  }
}

void main() {
  test('initial state is idle', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(backupControllerProvider), const BackupState.idle());
  });

  test('export() returns success with filename', () async {
    final svc = _FakeService();
    final c = ProviderContainer(overrides: [
      backupServiceProvider.overrideWithValue(svc),
    ]);
    addTearDown(c.dispose);
    await c.read(backupControllerProvider.notifier).export();
    final state = c.read(backupControllerProvider);
    expect(state, isA<BackupStateSuccessExport>());
    expect((state as BackupStateSuccessExport).filename, 'file.json');
  });

  test('import(replace) forwards mode to service', () async {
    final svc = _FakeService();
    final c = ProviderContainer(overrides: [
      backupServiceProvider.overrideWithValue(svc),
    ]);
    addTearDown(c.dispose);
    await c.read(backupControllerProvider.notifier).import(ImportMode.replace);
    expect(svc.lastMode, ImportMode.replace);
    final state = c.read(backupControllerProvider);
    expect(state, isA<BackupStateSuccessImport>());
    expect((state as BackupStateSuccessImport).count, 3);
  });

  test('export() failure yields error state', () async {
    final svc = _FakeService()
      ..exportResult = (null, IOFailure(debugMessage: 'oops'));
    final c = ProviderContainer(overrides: [
      backupServiceProvider.overrideWithValue(svc),
    ]);
    addTearDown(c.dispose);
    await c.read(backupControllerProvider.notifier).export();
    final state = c.read(backupControllerProvider);
    expect(state, isA<BackupStateError>());
  });
}
