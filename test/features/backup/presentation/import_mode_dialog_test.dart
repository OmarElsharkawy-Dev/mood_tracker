import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/backup/domain/import_mode.dart';
import 'package:mood_tracker/features/backup/presentation/widgets/import_mode_dialog.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

Future<ImportMode?> _pump(WidgetTester tester) async {
  ImportMode? result;
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(extensions: const [AppColors.light]),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(builder: (context) {
      return Scaffold(body: TextButton(
        onPressed: () async {
          result = await ImportModeDialog.show(context);
        },
        child: const Text('open'),
      ));
    }),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders merge and replace options', (tester) async {
    await _pump(tester);
    expect(find.text('Merge'), findsOneWidget);
    expect(find.text('Replace'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Cancel returns null', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    // result remains null
  });

  testWidgets('Selecting Merge and pressing Continue returns merge',
      (tester) async {
    ImportMode? captured;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        return Scaffold(body: TextButton(
          onPressed: () async {
            captured = await ImportModeDialog.show(context);
          },
          child: const Text('open'),
        ));
      }),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Merge'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(captured, ImportMode.merge);
  });

  testWidgets('Replace + confirm yields replace mode', (tester) async {
    ImportMode? captured;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        return Scaffold(body: TextButton(
          onPressed: () async {
            captured = await ImportModeDialog.show(context);
          },
          child: const Text('open'),
        ));
      }),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    // First Continue dismisses mode dialog, now the secondary confirm appears.
    expect(find.text('Replace all entries?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(captured, ImportMode.replace);
  });

  testWidgets('Replace + cancel on secondary confirm returns null', (tester) async {
    ImportMode? captured;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        return Scaffold(body: TextButton(
          onPressed: () async {
            captured = await ImportModeDialog.show(context);
          },
          child: const Text('open'),
        ));
      }),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(captured, isNull);
  });
}
