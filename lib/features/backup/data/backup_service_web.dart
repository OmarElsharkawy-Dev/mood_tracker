import '../../../core/error/failure.dart';
import '../domain/import_mode.dart';
import 'backup_service.dart';

/// Web build can't write to a filesystem or open a native share sheet,
/// so backup is reported as unsupported with a translatable message key.
class WebBackupService implements BackupService {
  const WebBackupService();

  @override
  Future<(String?, Failure?)> exportAndShare() async {
    return (null, _unsupported());
  }

  @override
  Future<(int?, Failure?)> pickAndImport(ImportMode mode) async {
    return (null, _unsupported());
  }

  Failure _unsupported() =>
      ValidationFailure(fieldErrors: {'backup': 'backupErrorPlatformUnsupported'});
}
