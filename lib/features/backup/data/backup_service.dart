import '../../../core/error/failure.dart';
import '../domain/import_mode.dart';

abstract class BackupService {
  Future<(String?, Failure?)> exportAndShare();
  Future<(int?, Failure?)> pickAndImport(ImportMode mode);
}
