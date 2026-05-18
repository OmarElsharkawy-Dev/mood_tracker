import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/navigation/app_routes.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppPrefs> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final sp = await SharedPreferences.getInstance();
  final prefs = AppPrefs(sp);
  final router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.today,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Today'))),
      ),
    ],
  );

  await tester.pumpWidget(ProviderScope(
    overrides: [appPrefsProvider.overrideWithValue(prefs)],
    child: MaterialApp.router(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  ));
  await tester.pumpAndSettle();
  return prefs;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('first page renders, Next advances, Get started completes',
      (tester) async {
    final prefs = await _pump(tester);

    // Page 0
    expect(find.text('Track how you feel'), findsOneWidget);

    // Tap Next → page 1
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Tap a face'), findsOneWidget);

    // Tap Next → page 2 (last)
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your data stays here'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);

    // Tap Get started → completes + navigates to Today
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(prefs.onboardingCompleted, isTrue);
  });

  testWidgets('Skip completes and navigates to Today', (tester) async {
    final prefs = await _pump(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(prefs.onboardingCompleted, isTrue);
  });
}
