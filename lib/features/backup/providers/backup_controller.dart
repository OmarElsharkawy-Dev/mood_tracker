import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../data/backup_service_provider.dart';
import '../domain/import_mode.dart';

@immutable
sealed class BackupState {
  const BackupState();
  const factory BackupState.idle() = BackupStateIdle;
  const factory BackupState.working() = BackupStateWorking;
  const factory BackupState.successExport(String filename) =
      BackupStateSuccessExport;
  const factory BackupState.successImport(int count) = BackupStateSuccessImport;
  const factory BackupState.error(Failure failure) = BackupStateError;
}

class BackupStateIdle extends BackupState {
  const BackupStateIdle();
  @override
  bool operator ==(Object other) => other is BackupStateIdle;
  @override
  int get hashCode => 0;
}

class BackupStateWorking extends BackupState {
  const BackupStateWorking();
  @override
  bool operator ==(Object other) => other is BackupStateWorking;
  @override
  int get hashCode => 1;
}

class BackupStateSuccessExport extends BackupState {
  const BackupStateSuccessExport(this.filename);
  final String filename;
  @override
  bool operator ==(Object other) =>
      other is BackupStateSuccessExport && other.filename == filename;
  @override
  int get hashCode => filename.hashCode;
}

class BackupStateSuccessImport extends BackupState {
  const BackupStateSuccessImport(this.count);
  final int count;
  @override
  bool operator ==(Object other) =>
      other is BackupStateSuccessImport && other.count == count;
  @override
  int get hashCode => count.hashCode;
}

class BackupStateError extends BackupState {
  const BackupStateError(this.failure);
  final Failure failure;
  @override
  bool operator ==(Object other) =>
      other is BackupStateError && other.failure == failure;
  @override
  int get hashCode => failure.hashCode;
}

class BackupController extends Notifier<BackupState> {
  @override
  BackupState build() => const BackupState.idle();

  Future<void> export() async {
    state = const BackupState.working();
    final svc = ref.read(backupServiceProvider);
    final (filename, err) = await svc.exportAndShare();
    if (err != null) {
      state = BackupState.error(err);
    } else {
      state = BackupState.successExport(filename!);
    }
  }

  Future<void> import(ImportMode mode) async {
    state = const BackupState.working();
    final svc = ref.read(backupServiceProvider);
    final (count, err) = await svc.pickAndImport(mode);
    if (err != null) {
      state = BackupState.error(err);
    } else {
      state = BackupState.successImport(count!);
    }
  }
}

final backupControllerProvider =
    NotifierProvider<BackupController, BackupState>(BackupController.new);
