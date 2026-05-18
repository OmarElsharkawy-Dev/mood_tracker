import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../mood_entry/data/mood_entry_repository_provider.dart';
import 'backup_service.dart';

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
  return BackupServiceImpl(
    repo: repo,
    appVersion: _appVersionCache ?? 'unknown',
    tempDir: () async => getTemporaryDirectory(),
    share: (path) async {
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    },
    pickFile: () async {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      final path = result?.files.first.path;
      return path == null ? null : File(path);
    },
  );
});
