import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/settings/presentation/screens/about_screen.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    PackageInfo.setMockInitialValues(
      appName: 'mood_tracker',
      packageName: 'com.example.mood_tracker',
      version: '1.2.3',
      buildNumber: '7',
      buildSignature: '',
    );
  });

  testWidgets('renders app title and version', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        appPrefsProvider.overrideWithValue(AppPrefs(sp)),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AboutScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Mood Tracker'), findsOneWidget);
    expect(find.text('Version 1.2.3'), findsOneWidget);
    expect(find.text('View open-source licenses'), findsOneWidget);
  });
}
