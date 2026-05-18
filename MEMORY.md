# Project Memory — Mood Tracker

Context bundle for human collaborators and AI assistants picking up this repo cold. Read alongside the spec ([`docs/superpowers/specs/2026-05-17-mood-tracker-design.md`](docs/superpowers/specs/2026-05-17-mood-tracker-design.md)) and the active phase plan under [`docs/superpowers/plans/`](docs/superpowers/plans/).

**Maintenance rule:** This file is updated at the end of every working session — newest entries at the top of the **Session log** below. The status, file map, and decision sections are kept current as material state changes. If you're starting a session, scan the latest log entry first to see what's fresh.

## Session log

### 2026-05-19 — Daylio UI overhaul + demo seeder

- Layered a complete Daylio-style visual redesign on top of the finished 5-phase app. Dark-first palette: primary `#7C6FCD`, secondary `#4ECDC4`, mood scale `#FF6B6B/#FFA26B/#FFD93D/#6BCB77/#4D96FF`. Font roles flipped — Raleway now owns headings + UI labels (Bold/SemiBold), Lora owns body + caption + entry notes (Regular). `AppRadius` retokenized to `xs:4 / sm:8 / md:16 / lg:24 / xl:32 / pill:100`. `AppColors` gained `surfaceVariant`/`outline`/`error` canonical fields + `moodColor(Mood)` helper; old `muted`/`onMuted`/`border`/`accent`/`destructive` kept as shims for one prompt, then removed once all widgets migrated to the canonical names.
- Every primary surface redesigned, prompt by prompt: **Today** (greeting + date + card-wrapped quick-log + recent), **LogEntrySheet** (DraggableScrollableSheet shell + new mood picker / mood-colored intensity slider / pill energy chips / inline tag input with `allTagsProvider` suggestions / pill Save button), **Calendar** (transparent appbar, Monday-first M-T-W header, redesigned cells with mood dot + ×N badge, redesigned day sheet), **History** (pill search bar + swipe-to-delete with snackbar undo + restyled `ActiveFilterBanner` + redesigned mood-row cards with accent bar), **Filter sheet** (themed fields + gradient-track mood range slider via `_NoTrackShape` + outlined tag chips), **Insights** (pill range selector + section cards with accent rect + 5 themed charts, custom horizontal `TopTagsChart` not on fl_chart, mood-colored per-bucket bars + legend below correlation charts, per-dot `moodColor` on trend), **Settings/Reminders/Backup** (transparent appbars + pill buttons + large Raleway-Bold time display).
- Cross-cutting migrations: `RadioListTile` → `RadioGroup` + `Radio<T>` (Flutter 3.32+ API) in theme picker, language picker, and import-mode dialog — `// ignore_for_file: deprecated_member_use` directives removed. `withOpacity` → `withValues(alpha:)` everywhere (already mostly done; final sweep confirmed zero remaining). Pre-fill mood from QuickLogRow flows through `AppRoutes.logWithMood(Mood)` → query param → `LogEntryController` family arg (`typedef LogEntryArgs = ({String? editEntryId, Mood? initialMood})`).
- Bug fix shipped: `entry_detail_screen.dart` was rendering `entry.mood.name` (raw enum identifier like `"good"`) instead of the localized label. Now uses a `_moodLabel` switch over `Mood` → `l10n.moodAwful/Bad/Okay/Good/Great`. The other two `.name` call sites (`AppRoutes.logWithMood`, `BackupCodec`) are correct as-is.
- New dev tool: `lib/dev/demo_data_seeder.dart` exports `seedDemoData(MoodEntryRepository, {int? seed})` — additive seeder that inserts ~130–150 realistic mood entries spread across the last ~180 days (weighted moods, weighted energy, 1–3 entries on ~70% of days, ~60% tagged, ~70% with sleep hours). Triggered from a `kDebugMode`-gated "DEVELOPER" section in Settings; snackbar reports count via `l10n.settingsDevSeedDone(count)`. 4 new ARB key pairs for the dev section.
- Final consistency pass swept the codebase for hardcoded colors, non-tokenized radii, `withOpacity`, and ARB key parity. Four `BorderRadius.circular(literal)` sites swapped to `AppRadius.*` tokens; the rest are either painter-internal illustration geometry (12, 20) or computed values (`_trackHeight / 2 = 2`) below any token's value, both kept by design. ARB parity: EN 156, ES 156, zero mismatches.
- Test suite stayed at **230/230** throughout every prompt. `flutter analyze` reported 0 issues continuously. No goldens regenerated (`mood_face` painter untouched).
- Process learning: when a UI prompt's "files to touch" list is provided, it's sometimes incomplete — shared internal widgets (`active_filter_banner`, `correlation_chart`) or dependent tests need updates too. Established pattern: flag the gap concisely, propose expansion, proceed once acknowledged. The user consistently accepted the expansion across all 8 prompts.

### 2026-05-18 — Firebase Hosting (web) shipped

- Live at **https://mood-tracker-task.web.app** — Firebase project `mood-tracker-task` (Spark plan), hosting only.
- Made the project web-compatible behind conditional imports so native (Android/iOS/desktop) is untouched:
  - `core/db/connection/` — selector + `connection_native.dart` (FFI/path_provider/NativeDatabase) + `connection_web.dart` (`WasmDatabase.open` against `sqlite3.wasm` + `drift_worker.js`) + `connection_unsupported.dart` stub.
  - `features/reminders/data/` — extracted abstract `NotificationService`, moved native impl to `flutter_local_notifications_service.dart`, added `web_notification_service.dart` no-op + `notification_service_factory*.dart` selector.
  - `features/backup/data/` — extracted abstract `BackupService`, moved impl to `backup_service_native.dart`, added `backup_service_web.dart` (returns `ValidationFailure backupErrorPlatformUnsupported`) + `backup_service_factory*.dart` selector. New ARB key `backupErrorPlatformUnsupported`.
  - `core/di/service_locator.dart` + `backup/data/backup_service_provider.dart` now call the platform factory.
- WASM assets dropped in `web/sqlite3.wasm` (713K, sqlite3-2.9.4) + `web/drift_worker.js` (347K, drift-2.29.0). Build outputs them to `build/web/` with correct MIME types (`application/wasm`, `text/javascript`).
- `firebase.json` configures SPA rewrite + long-cache headers on hashed assets, `no-cache` on `index.html`. `.firebaserc` pins `default → mood-tracker-task`.
- Verified: `flutter analyze` 0 issues, `flutter test` 230 pass, `flutter build web --release` succeeds, live URL returns HTTP 200 for `/`, `/sqlite3.wasm`, `/drift_worker.js`.
- Limitations on web: reminders + backup are intentionally no-ops; DB persists in browser IndexedDB/OPFS (per device, per origin).

### 2026-05-18 — Phase 5 ship

- Phase 5 (Reminders + JSON export/import) landed in 20 commits on `main`. New tests: +47. Test suite at **228/228 passing**, `flutter analyze` clean.
- Shipped: `features/reminders/` (NotificationService wrapping flutter_local_notifications, ReminderController + permission status provider, RemindersScreen with enable switch + time picker + denied-card, bootstrap re-arm on app start), `features/backup/` (BackupCodec with versioned envelope + migration shim, BackupService with file IO via path_provider + share_plus + file_picker, BackupController sealed state machine, BackupScreen + ImportModeDialog with merge/replace + replace double-confirm).
- New deps: `flutter_local_notifications ^21.0.0`, `timezone ^0.11.0`, `share_plus ^12.0.2`, `file_picker ^11.0.2`, `permission_handler ^12.0.1`.
- Native config: Android manifest permissions (POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, SCHEDULE_EXACT_ALARM, USE_EXACT_ALARM) + flutter_local_notifications receivers; iOS AppDelegate UNUserNotificationCenter delegate.
- Two new `/settings/` child routes (`reminders`, `backup`) replace the Phase 2 stub tile and add a new Data tile. Settings shows reminder status as subtitle ("Off" / "Daily at HH:MM").
- Notable API adaptations forced by newer plugin versions: `flutter_local_notifications` 21.x uses all-named parameters for `zonedSchedule` and a `settings:` named param for `initialize`; `file_picker` 11.x replaced `FilePicker.platform.pickFiles` with the static `FilePicker.pickFiles`; project `Failure` types use `ValidationFailure({Map fieldErrors})` and `IOFailure({String debugMessage})` rather than `messageKey`/`message`.
- **Closes out the 5-phase plan.** No further phases planned.

### 2026-05-18 — Phase 4 ship

- Phase 4 (Insights tab) landed in 23 commits on `main`. New tests: +59. Test suite now at **181/181 passing**, `flutter analyze` clean.
- Shipped: `features/statistics/` (InsightsRange enum, 5 pure aggregators, accessibility summaries, SelectedRangeController, insightsEntriesProvider, 5 derived chart providers, InsightsScreen + 5 chart widgets + RangeSelector + InsightSectionCard), `fl_chart ^1.2.0` dep, 29 EN+ES ARB key pairs, router swap to drop the Insights placeholder.
- Cross-tab filter now reaches Insights: `entryFilterProvider ∩ selectedRangeProvider` feeds one StreamProvider that fans out to 5 per-chart `Provider<AsyncValue<T>>`. Filter banner reused as-is (Phase 3) with a `ValueKey('active_filter_banner')` added for testability.
- Notable decisions: daily-mean trend with gap-aware line segments, grouped-bar correlations (5 sleep buckets + 5 energy levels), per-chart empty cards, in-memory range (no persistence), DST-safe `DateTime(y, m, d ± N)` calendar arithmetic throughout, `Mood.score` getter already on the enum (no separate `mood_score.dart` extension file created).
- Next up: Phase 5 (Reminders + JSON export/import).

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

All 5 phases shipped (Phase 1 on 2026-05-17, Phases 2–5 on 2026-05-18). What works today:

- `core/` infrastructure — theme tokens, l10n pipeline (EN + ES), GoRouter shell with first-run redirect, Drift schema, Failure/Result, prefs, GetIt+Riverpod DI.
- `features/mood_entry/` — log + edit journal-style entries (mood, intensity, note, tags, sleep hours, energy).
- `features/history/` — list + entry detail + delete + skeleton loader + empty state, search icon, active-filter banner, no-matches state.
- `features/today/` — greeting + quick-log row + recent entries + FAB.
- `features/settings/` — Appearance (theme picker), Language (en/es picker), Reminders tile (tappable, shows "Off" / "Daily at HH:MM" subtitle), Data tile (backup/restore), About (version + `showLicensePage`).
- `features/onboarding/` — 3-page first-run flow with `CustomPainter` illustrations and GoRouter `redirect:` gated on `AppPrefs.onboardingCompleted`.
- `features/search/` — shared `EntryFilterController` (Notifier<EntryFilter>), `allTagsProvider` derived from entries, modal `FilterSheet` with draft-state-then-Apply UX, subcomponents (`MoodRangeSlider`, `DateRangeField`, `TagFilterChips`).
- `features/calendar/` — `YearMonth` + `DayMoodSummary` value objects, `SelectedMonthController`, derived `calendarEntriesProvider` + `daySummariesProvider`, 6×7 `CalendarMonth` grid + `CalendarDayCell` (with ×N badge + today highlight) + `CalendarDaySheet`, `CalendarScreen` with prev/next/jump-to-today nav. Filter from `features/search/` shapes the dots too — cross-tab.
- `features/statistics/` — `InsightsRange` enum (7d/30d/90d/all) with `toDateRange()`, 5 pure aggregators (`computeMoodTrend`, `computeDistribution`, `computeTopTags`, `computeSleepCorrelation`, `computeEnergyCorrelation`), accessibility summary helpers, `SelectedRangeController`, `insightsEntriesProvider` merging filter ∩ range, 5 derived chart providers, `InsightsScreen` composing `RangeSelector` + `InsightSectionCard` + 5 chart widgets (`MoodTrendChart`, `MoodDistributionChart`, `TopTagsChart`, plus sleep + energy correlation charts). Cross-tab filter banner reused from Phase 3.
- `features/reminders/` — `NotificationService` interface + `FlutterLocalNotificationsService` impl, `ReminderSchedule` value class with prefs codec, `ReminderController` (enable/disable + time mutation), permission status provider, `PermissionDeniedCard`, `ReminderTimePickerSheet`, `RemindersScreen` with enable switch + time picker + denied-card, bootstrap re-arm. Android + iOS native config complete.
- `features/backup/` — `BackupEnvelope` + `ImportMode` domain types, `BackupCodec` with versioned JSON envelope (v1) + forward-migration shim, `BackupService` with export (share sheet) + import (merge-or-replace via file picker), `BackupController` sealed state machine, `ImportModeDialog` with replace double-confirm, `BackupScreen` with export/import buttons + status bar.
- Full Spanish translations across all phases (~130+ keys mirrored).

`flutter analyze` reports 0 issues; `flutter test` passes 228/228 (including 5 `MoodFace` goldens).

**No further phases planned.** The 5-phase plan is complete.

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
4. **Phase 4 — Statistics & charts (`fl_chart`)** *(complete 2026-05-18)* — `features/statistics/` (InsightsRange, 5 aggregators, 5 chart providers, InsightsScreen + 5 chart widgets + RangeSelector + InsightSectionCard), `fl_chart` dep, 29 EN+ES ARB key pairs.
5. **Phase 5 — Local reminders, JSON export/import** *(complete 2026-05-18)* — `features/reminders/` (NotificationService, ReminderController, RemindersScreen), `features/backup/` (BackupCodec, BackupService, BackupController, BackupScreen + ImportModeDialog), new `/settings/reminders` and `/settings/backup` routes.

## File map (Phases 1 + 2 + 3 + 4 + 5)

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
    statistics/                                   # Insights tab (Phase 4)
      domain/{insights_range, aggregators/{mood_trend, distribution, top_tags, sleep_correlation, energy_correlation}, accessibility_summaries}
      providers/{selected_range_controller, insights_entries_provider, chart_providers}
      presentation/{screens/insights_screen, widgets/{range_selector, insight_section_card, mood_trend_chart, mood_distribution_chart, top_tags_chart, sleep_correlation_chart, energy_correlation_chart}}
    reminders/                                    # Daily local notifications (Phase 5)
      domain/{notification_service, reminder_schedule}
      data/flutter_local_notifications_service
      providers/{reminder_controller, permission_status_provider}
      presentation/{screens/reminders_screen, widgets/{permission_denied_card, reminder_time_picker_sheet}}
    backup/                                       # JSON export/import (Phase 5)
      domain/{backup_envelope, import_mode, backup_codec, backup_service}
      providers/backup_controller
      presentation/{screens/backup_screen, widgets/import_mode_dialog}
  l10n/
    app_en.arb                                    # EN ARB source (102 keys)
    app_es.arb                                    # ES ARB source (mirrors EN key-for-key)
    app_localizations*.dart                       # generated, gitignored
test/
  ... mirrors lib/ ...
```
