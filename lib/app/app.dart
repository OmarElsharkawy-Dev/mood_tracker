import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../core/l10n/locale_notifier.dart';
import '../core/navigation/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_notifier.dart';

class MoodTrackerApp extends ConsumerWidget {
  const MoodTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (_, child) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        themeMode: mode,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      ),
    );
  }
}
