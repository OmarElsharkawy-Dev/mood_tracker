import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../mood_entry/domain/repositories/mood_entry_repository.dart';
import 'backup_service.dart';
import 'backup_service_native.dart';

BackupService createBackupService({
  required MoodEntryRepository repo,
  required String appVersion,
}) {
  return BackupServiceImpl(
    repo: repo,
    appVersion: appVersion,
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
}
