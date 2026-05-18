import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/reminders/presentation/widgets/permission_denied_card.dart';
import 'package:mood_tracker/features/reminders/presentation/widgets/reminder_time_picker_sheet.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget wrap(Widget child) => MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('PermissionDeniedCard renders title, body, and CTA', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(wrap(
      PermissionDeniedCard(onOpenSettings: () => tapped++),
    ));
    await tester.pump();
    expect(find.text('Notifications are turned off'), findsOneWidget);
    expect(find.textContaining('Enable notifications'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('ReminderTimePickerSheet exposes a show static', (tester) async {
    expect(ReminderTimePickerSheet.show, isA<Function>());
  });
}
