import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/history/presentation/screens/entry_detail_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/mood_entry/presentation/screens/log_entry_sheet.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/today/presentation/screens/today_screen.dart';
import '../di/infrastructure_providers.dart';
import 'app_routes.dart';

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}

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
                  pageBuilder: (context, _) => const MaterialPage(
                    fullscreenDialog: true,
                    child: LogEntrySheet(),
                  ),
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
              builder: (context, _) => const _PlaceholderScreen('Calendar'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.insights,
              builder: (context, _) => const _PlaceholderScreen('Insights'),
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
    final destinations = const [
      _NavDest(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Today'),
      _NavDest(icon: Icons.list_alt_outlined, selectedIcon: Icons.list_alt, label: 'History'),
      _NavDest(icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today, label: 'Calendar'),
      _NavDest(icon: Icons.show_chart_outlined, selectedIcon: Icons.show_chart, label: 'Insights'),
      _NavDest(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
    ];
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _NavDest {
  const _NavDest(
      {required this.icon, required this.selectedIcon, required this.label});
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
