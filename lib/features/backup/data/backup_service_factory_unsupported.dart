import '../../mood_entry/domain/repositories/mood_entry_repository.dart';
import 'backup_service.dart';

BackupService createBackupService({
  required MoodEntryRepository repo,
  required String appVersion,
}) {
  throw UnsupportedError('No BackupService available on this platform.');
}
