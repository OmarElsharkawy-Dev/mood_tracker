import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/backup/data/backup_service.dart';
import 'package:mood_tracker/features/backup/data/backup_service_provider.dart';
import 'package:mood_tracker/features/backup/domain/import_mode.dart';
import 'package:mood_tracker/features/backup/presentation/screens/backup_screen.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

class _FakeService implements BackupService {
  int exportCalls = 0;
  ImportMode? lastImportMode;
  @override
  Future<(String?, Failure?)> exportAndShare() async {
    exportCalls++;
    return ('out.json', null);
  }

  @override
  Future<(int?, Failure?)> pickAndImport(ImportMode mode) async {
    lastImportMode = mode;
    return (5, null);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders Export + Import buttons', (tester) async {
    final svc = _FakeService();
    await tester.pumpWidget(ProviderScope(
      overrides: [backupServiceProvider.overrideWithValue(svc)],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BackupScreen(),
      ),
    ));
    await tester.pump();
    expect(find.text('Export to file'), findsOneWidget);
    expect(find.text('Import from file'), findsOneWidget);
  });

  testWidgets('tapping Export calls service', (tester) async {
    final svc = _FakeService();
    await tester.pumpWidget(ProviderScope(
      overrides: [backupServiceProvider.overrideWithValue(svc)],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BackupScreen(),
      ),
    ));
    await tester.pump();
    await tester.tap(find.text('Export to file'));
    await tester.pumpAndSettle();
    expect(svc.exportCalls, 1);
  });
}
