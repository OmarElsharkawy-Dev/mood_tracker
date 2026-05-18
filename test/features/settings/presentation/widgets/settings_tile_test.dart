import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/settings/presentation/widgets/settings_tile.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders title and subtitle', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: const Scaffold(
        body: SettingsTile(title: 'Theme', subtitle: 'System'),
      ),
    ));
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
  });

  testWidgets('fires onTap when enabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: SettingsTile(
          title: 'Theme',
          onTap: () => taps++,
        ),
      ),
    ));
    await tester.tap(find.byType(SettingsTile));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('ignores onTap when disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: SettingsTile(
          title: 'Reminders',
          enabled: false,
          onTap: () => taps++,
        ),
      ),
    ));
    await tester.tap(find.byType(SettingsTile));
    await tester.pump();
    expect(taps, 0);
  });
}
