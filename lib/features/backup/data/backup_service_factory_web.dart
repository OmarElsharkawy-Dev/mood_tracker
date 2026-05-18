import '../../mood_entry/domain/repositories/mood_entry_repository.dart';
import 'backup_service.dart';
import 'backup_service_web.dart';

BackupService createBackupService({
  required MoodEntryRepository repo,
  required String appVersion,
}) {
  return const WebBackupService();
}
