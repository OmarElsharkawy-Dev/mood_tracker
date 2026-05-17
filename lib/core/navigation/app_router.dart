import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/history/presentation/screens/entry_detail_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/mood_entry/presentation/screens/log_entry_sheet.dart';
import '../../features/today/presentation/screens/today_screen.dart';
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
              builder: (context, _) => const _PlaceholderScreen('Settings'),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '${AppRoutes.entryDetail}/:id',
        builder: (_, state) =>
            EntryDetailScreen(entryId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            pageBuilder: (_, state) => MaterialPage(
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
    const destinations = [
      _NavDest(icon: Icons.home_outlined, selectedIcon: Icons.home, labelKey: 'Today'),
      _NavDest(icon: Icons.list_alt_outlined, selectedIcon: Icons.list_alt, labelKey: 'History'),
      _NavDest(icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today, labelKey: 'Calendar'),
      _NavDest(icon: Icons.show_chart_outlined, selectedIcon: Icons.show_chart, labelKey: 'Insights'),
      _NavDest(icon: Icons.settings_outlined, selectedIcon: Icons.settings, labelKey: 'Settings'),
    ];
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.labelKey,
            ),
        ],
      ),
    );
  }
}

class _NavDest {
  const _NavDest({
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;
}
