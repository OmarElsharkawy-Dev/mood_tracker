import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../mood_entry/data/mood_entry_repository_provider.dart';
import 'backup_service.dart';
import 'backup_service_factory.dart';

String? _appVersionCache;

Future<void> primeAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    _appVersionCache = '${info.version}+${info.buildNumber}';
  } catch (_) {
    _appVersionCache = 'unknown';
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  return createBackupService(
    repo: repo,
    appVersion: _appVersionCache ?? 'unknown',
  );
});
