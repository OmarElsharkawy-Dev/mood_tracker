# Project Memory — Mood Tracker

Context bundle for human collaborators and AI assistants picking up this repo cold. Read alongside the spec ([`docs/superpowers/specs/2026-05-17-mood-tracker-design.md`](docs/superpowers/specs/2026-05-17-mood-tracker-design.md)) and the active phase plan under [`docs/superpowers/plans/`](docs/superpowers/plans/).

**Maintenance rule:** This file is updated at the end of every working session — newest entries at the top of the **Session log** below. The status, file map, and decision sections are kept current as material state changes. If you're starting a session, scan the latest log entry first to see what's fresh.

## Session log

### 2026-05-18 — Phase 3 ship + memory-policy change

- Phase 3 (Calendar + cross-tab filter) landed in 15 commits on `main` (top: `634e90b`). 47 new tests, full suite at **122/122 passing**, `flutter analyze` clean.
- Shipped: `features/search/` (EntryFilter + EntryFilterController + allTagsProvider + FilterSheet modal with subcomponents), `features/calendar/` (YearMonth + DayMoodSummary + SelectedMonthController + calendar/day-summaries providers + CalendarMonth/DayCell/DaySheet widgets + CalendarScreen), `MoodEntryRepositoryImpl._applyQuery` honoring `EntryQuery`, History search icon + `ActiveFilterBanner` + no-matches state, 17 new EN+ES ARB key pairs.
- Cross-tab filter is the headline architectural addition: one `entryFilterProvider` consumed by both `historyProvider` and `calendarEntriesProvider`.
- Docs hygiene: Phase 3 plan checkboxes ticked, README + this file + cross-session memory refreshed, `project_phase3_complete` memory added.
- **Process change:** This file is now updated every session, not just at phase boundaries. Session log section added.
- Next up: Phase 4 (Statistics & charts with `fl_chart`) — designed in master spec §10 but not yet brainstormed.

### 2026-05-18 — Phase 2 ship

- Phase 2 (Settings + Onboarding + Spanish) landed in 16 commits (15 implementation + 1 post-review polish at `800886d`). Test suite reached 75/75 passing.
- Shipped: `features/settings/` (theme/language/reminders-stub/about + modal pickers), `features/onboarding/` (3-page first-run flow with CustomPainter illustrations + GoRouter `redirect:` gate), full `app_es.arb`, `package_info_plus` dep.
- Post-review polish replaced `CircularProgressIndicator` loading states with `Skeletonizer`, localized bottom-nav labels via `context.l10n`, and switched `SettingsController` setters to `ref.invalidateSelf()` instead of force-unwrapping `state.value!`.

### 2026-05-17 — Phase 1 ship

- Phase 1 (foundation + first vertical slice) landed in 28 implementation commits + 1 follow-up `MoodCard` overflow fix. Test suite reached 54/54 passing.
- Shipped: full `core/` infrastructure (theme tokens, l10n pipeline EN-only, GoRouter shell, Drift schema, Failure/Result, prefs, GetIt+Riverpod DI, shared widgets including `MoodFace` `CustomPainter` with 5 goldens), `features/mood_entry/` (log + edit), `features/history/` (list + detail + delete), `features/today/` (quick-log + recent + FAB), app bootstrap, integration smoke test.
- Notable env quirk discoveries: Flutter 3.41.9 removed `synthetic-package` from `l10n.yaml` (l10n outputs now land in `lib/l10n/`, gitignored); `custom_lint` bumped to `^0.7.6` for `riverpod_lint` compatibility; `skeletonizer` bumped to `2.1.3` for Flutter 3.41.9 Canvas API.

## What the project is

A local-only Flutter mood tracker. Journal-style entries (mood + intensity + note + tags + sleep hours + energy level) persisted to a single SQLite database via Drift. The whole thing is a learning playground exercising Feature-First Clean Architecture, Riverpod, GoRouter, l10n, theming, and TDD end-to-end.

No accounts. No cloud. English + Spanish (both LTR).

## Current status

Phases 1, 2, and 3 shipped (Phase 1 on 2026-05-17, Phases 2 and 3 on 2026-05-18). What works today:

- `core/` infrastructure — theme tokens, l10n pipeline (EN + ES), GoRouter shell with first-run redirect, Drift schema, Failure/Result, prefs, GetIt+Riverpod DI.
- `features/mood_entry/` — log + edit journal-style entries (mood, intensity, note, tags, sleep hours, energy).
- `features/history/` — list + entry detail + delete + skeleton loader + empty state, search icon, active-filter banner, no-matches state.
- `features/today/` — greeting + quick-log row + recent entries + FAB.
- `features/settings/` — Appearance (theme picker), Language (en/es picker), Reminders (disabled stub), About (version + `showLicensePage`).
- `features/onboarding/` — 3-page first-run flow with `CustomPainter` illustrations and GoRouter `redirect:` gated on `AppPrefs.onboardingCompleted`.
- `features/search/` — shared `EntryFilterController` (Notifier&lt;EntryFilter&gt;), `allTagsProvider` derived from entries, modal `FilterSheet` with draft-state-then-Apply UX, subcomponents (`MoodRangeSlider`, `DateRangeField`, `TagFilterChips`).
- `features/calendar/` — `YearMonth` + `DayMoodSummary` value objects, `SelectedMonthController`, derived `calendarEntriesProvider` + `daySummariesProvider`, 6×7 `CalendarMonth` grid + `CalendarDayCell` (with ×N badge + today highlight) + `CalendarDaySheet`, `CalendarScreen` with prev/next/jump-to-today nav. Filter from `features/search/` shapes the dots too — cross-tab.
- Full Spanish translations across all phases (~90 keys mirrored).

`flutter analyze` reports 0 issues; `flutter test` passes 122/122 (including 5 `MoodFace` goldens).

Phases 4-5 are designed in the master spec but not yet planned in detail. Phase 4 = Statistics & charts (`fl_chart`); Phase 5 = Reminders (`flutter_local_notifications`) + JSON export/import.

## Hard rules to honor

- **No `Co-Authored-By` trailer in any commit.** The user explicitly overrode the global default; do not add it back.
- **Every commit must keep `flutter analyze` at 0 issues and `flutter test` passing.**
- **No hardcoded strings in UI** — use `context.l10n.<key>`. New keys go in `lib/l10n/app_en.arb` first.
- **No hardcoded colors** — use `context.appColors` (an `AppColors` `ThemeExtension`).
- **No hardcoded routes** — use `AppRoutes` constants and `AppRoutes.entryDetailFor(id)` helpers.
- **Imports** sorted alphabetically: package imports first, blank line, then project imports.
- **`const` constructors everywhere** they fit; **`final` locals** by default.

## Non-obvious decisions

- **Mood faces are programmatic `CustomPainter`s** in `lib/core/widgets/mood_face.dart` — never SVG/PNG assets and never emoji. The painter interpolates mouth curvature between awful (deep frown) and great (wide smile), and accepts a `strength` parameter that's wired for future intensity-overlay work but always `1.0` in Phase 1.
- **Drift row classes use `@DataClassName('EntryRow')`, `'TagRow'`, `'EntryTagRow'`** so the generated row types don't collide with the domain `Tag` entity. Companion names follow Drift's default (`EntriesCompanion`, `TagsCompanion`, `EntryTagsCompanion`).
- **Tags are normalized** in their own table with an `entry_tags` join — chosen over a denormalized JSON column because the whole point of using Drift was relational queryability.
- **Errors are returned, not thrown.** Repositories return `(T?, Failure?)` tuples; the sealed `Failure` hierarchy (`DatabaseFailure`, `NotFoundFailure`, `ValidationFailure`, `IOFailure`, `UnknownFailure`) is mapped to localized strings by `ErrorView`.
- **DI is hybrid.** GetIt registers infrastructure singletons (`AppDatabase`, `AppPrefs`, `SharedPreferences`) at bootstrap; Riverpod providers wrap them so tests can override at the Riverpod layer.
- **Form state lives outside widgets.** `LogEntryFormState` is a plain Dart class with validators + `canSubmit` + `toEntity`. The `LogEntryController` (`AutoDisposeFamilyAsyncNotifier<LogEntryFormState, String?>`) holds it; the sheet widget is a thin composer.
- **`SettingsController.setTheme` / `setLocale` call `ref.invalidateSelf()`** after the underlying provider mutation rather than manually reconstructing `SettingsViewModel`. This avoids a `state.value!` force-unwrap that crashes if the setter is called before the initial `build()` completes. Trade-off: callers must `await ref.read(settingsControllerProvider.future)` to read the post-mutation value, but the controller stays simpler and future-proof for new fields.
- **Locale picker labels use native names** (`English`, `Español`) via `nativeNameFor(Locale)` in `lib/core/l10n/native_name.dart`, NOT localized-by-current-locale names. This is intentional so users picking a language they don't speak aren't locked out by the current locale's label.
- **Onboarding illustrations are `CustomPainter`s** that reuse `MoodFace` for the embedded face icons. Paint colors come from `context.appColors.primary` so they re-paint on theme switch.
- **First-run redirect** lives in the GoRouter `redirect:` callback in `app_router.dart` — gated on `AppPrefs.onboardingCompleted` (synchronous read after SP cache hits). `/onboarding` is a top-level route OUTSIDE the `StatefulShellRoute`, so the bottom nav doesn't show during onboarding.
- **`MoodEntryRepositoryImpl._applyQuery`** is the single private helper that translates an `EntryQuery` into a chain of Drift `.where(...)` predicates. Multiple `.where(...)` calls on the same `SimpleSelectStatement` AND together — Drift composes them automatically. Tag filtering uses `isInQuery` against an `entry_tags` subselect; text search is `LIKE '%text%'` against the `note` column (case-insensitive for ASCII by default).
- **Cross-tab filter** is one provider (`entryFilterProvider`, a `Notifier<EntryFilter>`) consumed by both `historyProvider` and `calendarEntriesProvider`. Setting a filter in History instantly reshapes the Calendar dots too. The filter is in-memory only — no persistence — so a fresh app launch starts with `EntryFilter.empty`.
- **`EntryFilter.copyWith`** uses an `_unset` sentinel `Object` so `copyWith(text: null)` clears the field instead of being treated as "no change". Same pattern any future Phase 4/5 view-models with nullable fields should use.
- **Calendar month grid** is a 6×7 (42-cell) `GridView.count` with non-current-month cells faded to 0.4 opacity and non-tappable. The single-dot rendering (vs. multi-dot or mini-face) was decided in Phase 1 brainstorming; multi-entry days get a small `×N` badge in the top-right of the cell.

## Environment quirks we hit during Phase 1 + 2

- **Flutter 3.41.9 removed `synthetic-package: true`** from `l10n.yaml`. The generated `app_localizations.dart` lands directly in `lib/l10n/` (not under `.dart_tool/flutter_gen/`). Both files are gitignored and the project imports them via the direct path `package:mood_tracker/l10n/app_localizations.dart`.
- **`custom_lint`** had to be bumped from `^0.6.4` → `^0.7.6` to resolve a transitive `rxdart` conflict with `riverpod_lint`.
- **`skeletonizer`** had to be bumped from `1.4.3` → `2.1.3` for Flutter 3.41.9's `Canvas` API.
- **`RadioListTile` is deprecated** in Flutter 3.41.9 (replaced by `Radio` + `RadioGroup`). The `ThemePickerSheet` and `LanguagePickerSheet` use a file-scope `// ignore_for_file: deprecated_member_use` directive because the deprecation surfaces 8 real warnings each. Migrate to the new API in a future polish pass.
- **`package_info_plus: ^8.0.2`** is required for the About screen's version display. Resolves to `8.3.1` at lock time.

## Testing patterns

- **Disable Google Fonts network fetching in widget tests** via `GoogleFonts.config.allowRuntimeFetching = false` in `setUpAll` — otherwise tests try real HTTP requests for Lora/Raleway.
- **Drift's `.watch()` stream keeps FakeAsync timers alive** indefinitely, so `pumpAndSettle` will hang when a screen subscribes via `StreamProvider`. The integration smoke test in `test/widget_test.dart` uses a fake repo with `Stream.value(const [])` instead — the real Drift integration is covered separately in `test/features/mood_entry/data/mood_entry_repository_impl_test.dart`.
- **Widget tests that render the `MoodCard` row** need a larger viewport (`tester.view.physicalSize = const Size(1080, 1920)`) and a teardown to restore it.
- **Golden tests for `MoodFace`** live at `test/core/widgets/goldens/`. Regenerate with `flutter test --update-goldens test/core/widgets/mood_face_test.dart` only when the painter intentionally changes.

## Phase roadmap

Each phase ships against the master spec and gets its own plan in `docs/superpowers/plans/`. Phase-specific scope refinements (when needed) live alongside the master spec in `docs/superpowers/specs/`.

1. **Phase 1 — Foundation + first vertical slice** *(complete 2026-05-17)* — `core/`, `mood_entry`, `history`, `today`, app wiring.
2. **Phase 2 — Settings, onboarding, Spanish translations** *(complete 2026-05-18)* — settings tab + onboarding flow + first-run redirect + `app_es.arb`.
3. **Phase 3 — Calendar view + cross-tab filter** *(complete 2026-05-18)* — `features/search/` (EntryFilter + FilterSheet + allTagsProvider), `features/calendar/` (month grid + day-detail sheet + nav), repository `EntryQuery` filtering, History search icon + active-filter banner + no-matches state.
4. **Phase 4 — Statistics & charts (`fl_chart`).**
5. **Phase 5 — Local reminders, JSON export/import.**

## File map (Phases 1 + 2 + 3)

```
lib/
  main.dart                                       # bootstrap → ProviderScope → MoodTrackerApp
  app/
    bootstrap.dart                                # ensureInitialized + registerServices
    app.dart                                      # MaterialApp.router + ScreenUtilInit
  core/
    db/                                           # Drift: tables.dart, app_database.dart (+ .g.dart, gitignored if regenerated)
    di/                                           # service_locator (GetIt) + infrastructure_providers (Riverpod wrappers)
    error/                                        # Failure sealed class + Result/Unit
    l10n/                                         # context.l10n extension + LocaleNotifier + native_name
    navigation/                                   # AppRoutes + AppRouter (GoRouter shell + first-run redirect)
    prefs/                                        # AppPrefs (themeMode, localeTag, onboardingCompleted)
    theme/                                        # AppColors, AppTextStyles, AppSpacing, AppRadius, AppElevation, AppMotion, AppTheme, ThemeNotifier
    utils/                                        # uuid + date helpers
    widgets/                                      # MoodFace, MoodCard, MoodDot, AppChip, AppDivider, EmptyStateView, ErrorView
  features/
    mood_entry/                                   # log + edit (the write surface)
      domain/{entities, enums, repositories}
      data/{mappers, mood_entry_repository_impl, mood_entry_repository_provider}
      presentation/{screens/log_entry_sheet, widgets/{mood_picker_row, intensity_slider, energy_segmented, tag_chip_input}}
      providers/{log_entry_form_state, log_entry_controller}
    history/                                      # list + detail + delete
      presentation/{screens/{history_screen, entry_detail_screen}, widgets/history_row}
      providers/history_controller
    today/                                        # quick-log + recent + FAB
      presentation/{screens/today_screen, widgets/quick_log_row}
      providers/today_controller
    settings/                                     # theme/language/reminders-stub/about
      presentation/{screens/{settings_screen, about_screen}, widgets/{settings_section, settings_tile, theme_picker_sheet, language_picker_sheet}}
      providers/settings_controller
    onboarding/                                   # 3-page first-run flow
      presentation/{screens/onboarding_screen, widgets/{onboarding_page, illustration_what, illustration_how, illustration_privacy}}
      providers/onboarding_controller
    search/                                       # cross-tab filter (Phase 3)
      domain/entry_filter
      providers/{entry_filter_controller, all_tags_provider}
      presentation/widgets/{filter_sheet, mood_range_slider, date_range_field, tag_filter_chips}
    calendar/                                     # month grid (Phase 3)
      domain/{year_month, day_mood_summary}
      providers/{selected_month_controller, calendar_entries_provider, day_summaries_provider}
      presentation/{screens/calendar_screen, widgets/{calendar_month, calendar_day_cell, calendar_day_sheet}}
  l10n/
    app_en.arb                                    # EN ARB source (73 keys)
    app_es.arb                                    # ES ARB source (mirrors EN key-for-key)
    app_localizations*.dart                       # generated, gitignored
test/
  ... mirrors lib/ ...
```
