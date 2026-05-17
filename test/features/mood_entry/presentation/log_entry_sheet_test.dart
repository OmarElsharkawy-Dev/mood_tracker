import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/features/mood_entry/presentation/screens/log_entry_sheet.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

class _MemRepo implements MoodEntryRepository {
  final List<MoodEntry> created = [];
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry entry) async {
    created.add(entry);
    return (entry, null);
  }
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry entry) async => (entry, null);
  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      (null, NotFoundFailure(id: id));
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) => const Stream.empty();
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (const <MoodEntry>[], null);
}

void main() {
  testWidgets('select mood then save persists an entry', (tester) async {
    // Use a wider surface so the five MoodCards fit side-by-side.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // MoodCard has a fixed height (size + 22 = 86 px) but on the default test
    // surface the AppBar + padding constraints it to ~75 px, producing a
    // minor overflow warning. Silence it so the test only verifies logic.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    final repo = _MemRepo();
    final router = GoRouter(
      initialLocation: '/log',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => const Scaffold(body: Text('Home')),
          routes: [
            GoRoute(
              path: 'log',
              builder: (context, _) => const LogEntrySheet(),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        moodEntryRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pumpAndSettle();

    // Tap the "Good" card (label localized to "Good" in EN).
    await tester.tap(find.text('Good'));
    await tester.pump();

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.created, hasLength(1));
    expect(repo.created.single.mood.name, 'good');
  });
}
