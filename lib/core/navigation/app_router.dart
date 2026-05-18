import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/backup/presentation/screens/backup_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/history/presentation/screens/entry_detail_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/mood_entry/domain/enums/mood.dart';
import '../../features/mood_entry/presentation/screens/log_entry_sheet.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/reminders/presentation/screens/reminders_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/statistics/presentation/screens/insights_screen.dart';
import '../../features/today/presentation/screens/today_screen.dart';
import '../di/infrastructure_providers.dart';
import '../l10n/context_l10n_extension.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.today,
    redirect: (context, state) {
      final completed = ref.read(appPrefsProvider).onboardingCompleted;
      final atOnboarding = state.uri.path == AppRoutes.onboarding;
      if (!completed && !atOnboarding) return AppRoutes.onboarding;
      if (completed && atOnboarding) return AppRoutes.today;
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.today,
              builder: (context, _) => const TodayScreen(),
              routes: [
                GoRoute(
                  path: 'log',
                  pageBuilder: (context, state) {
                    final raw = state.uri.queryParameters['mood'];
                    Mood? initial;
                    if (raw != null) {
                      for (final m in Mood.values) {
                        if (m.name == raw) {
                          initial = m;
                          break;
                        }
                      }
                    }
                    return MaterialPage(
                      fullscreenDialog: true,
                      child: LogEntrySheet(initialMood: initial),
                    );
                  },
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.history,
              builder: (context, _) => const HistoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.calendar,
              builder: (context, _) => const CalendarScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.insights,
              builder: (context, _) => const InsightsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, _) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'about',
                  builder: (context, _) => const AboutScreen(),
                ),
                GoRoute(
                  path: 'backup',
                  builder: (context, _) => const BackupScreen(),
                ),
                GoRoute(
                  path: 'reminders',
                  builder: (context, _) => const RemindersScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.entryDetail}/:id',
        builder: (context, state) =>
            EntryDetailScreen(entryId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            pageBuilder: (context, state) => MaterialPage(
              fullscreenDialog: true,
              child: LogEntrySheet(editEntryId: state.pathParameters['id']),
            ),
          ),
        ],
      ),
    ],
  );
});

class _MainShell extends StatelessWidget {
  const _MainShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: l10n.navHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l10n.navCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart_outlined),
            selectedIcon: const Icon(Icons.show_chart),
            label: l10n.navInsights,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
