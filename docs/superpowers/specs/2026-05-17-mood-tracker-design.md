# Mood Tracker — Design Spec

**Date:** 2026-05-17
**Status:** Approved (architecture + UI)
**Intent:** Learning playground exercising the full Flutter + Clean Architecture + Riverpod + l10n + theming stack end-to-end.

## 1. Scope & Goals

A local-only, single-user mood tracker for Flutter. The app captures rich journal-style entries (mood, intensity, free-text note, activity tags, sleep hours, energy level) and surfaces them through history, calendar, search/filter, statistics with charts, daily reminders, JSON export/import, and an onboarding flow. Two locales: English and Spanish (both LTR). Two themes: light and dark, with a system-follow option. No accounts, no network sync.

The goal is not commercial polish — it is to exercise the canonical patterns end-to-end on a feature surface broad enough that each pattern shows up at least once.

## 2. Architecture

### 2.1 Layering

Feature-First Clean Architecture. Each feature owns three layers:

- `domain/` — plain Dart entities, value objects, repository interfaces. No imports from `data/` or `presentation/`.
- `data/` — Drift DAOs, repository implementations, DTO mappers. No imports from `presentation/`.
- `presentation/` — screens + widgets (thin composers).
- `providers/` — Riverpod controllers + state classes (sits next to `presentation/`, only consumed by it).

Cross-cutting infrastructure lives in `core/` and is shared.

### 2.2 Module layout

```
lib/
  main.dart                       // runApp + bootstrap
  app/
    app.dart                      // MaterialApp.router, theme/locale wiring
    bootstrap.dart                // init Drift, prefs, DI, error zone
  core/
    db/                           // AppDatabase (Drift), DAOs base, migrations
    di/                           // GetIt registration + Riverpod overrides
    error/                        // Failure, Result helpers
    l10n/                         // generated AppLocalizations + LocaleNotifier
    navigation/                   // AppRouter (GoRouter), AppRoutes constants
    theme/                        // AppColors, AppTextStyles, AppSpacing, AppRadius,
                                  //   AppElevation, AppMotion, ThemeNotifier
    widgets/                      // MoodFace, MoodCard, MoodDot, EmptyStateView,
                                  //   ErrorView, RangeSelector, AppChip, AppDivider
    utils/                        // formatters, validators, date helpers
    prefs/                        // SharedPreferences wrapper
  features/
    mood_entry/                   // log + edit (write surface)
      domain/  data/  presentation/  providers/
    history/                      // list + detail (read-only)
    calendar/                     // month grid + day sheet (read-only)
    search/                       // filter + text search (read-only)
    statistics/                   // aggregations + charts (read-only)
    reminders/                    // local notifications scheduling
    backup/                       // JSON export / import
    settings/                     // theme, language, reminder time
    onboarding/                   // first-run intro
  l10n/
    app_en.arb
    app_es.arb
```

### 2.3 Cross-feature data ownership

`features/mood_entry/data/` is the canonical home of the entry repository. Read-only features (`history`, `calendar`, `search`, `statistics`) import `MoodEntryRepository` from `mood_entry/domain/`. No duplicated data layers.

`core/db/AppDatabase` is the single Drift database. Features contribute DAOs; the database itself is centralized so migrations are coherent.

### 2.4 Dependency injection

Hybrid: **GetIt** registers infrastructure singletons at bootstrap (`AppDatabase`, `SharedPreferences`, `NotificationService`). **Riverpod** providers expose them via thin wrapper providers so tests can override at the Riverpod layer without touching GetIt directly.

```dart
final appDatabaseProvider = Provider<AppDatabase>((_) => getIt<AppDatabase>());
```

This keeps the test override surface narrow and well-typed.

## 3. Domain Model

### 3.1 Entities

Plain Dart, no codegen.

```dart
class MoodEntry {
  final String id;                   // uuid v4
  final DateTime occurredAt;         // when the mood happened (user-editable)
  final Mood mood;                   // enum: awful, bad, okay, good, great
  final int intensity;               // 1..10, validated
  final String? note;                // free text, nullable
  final List<Tag> tags;              // 0..N
  final double? sleepHours;          // 0..24, nullable
  final EnergyLevel energy;          // enum: veryLow, low, medium, high, veryHigh
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Tag {
  final String id;
  final String label;                // user-editable display label
  final String slug;                 // lowercased, deduped — natural key
}

enum Mood { awful, bad, okay, good, great }
enum EnergyLevel { veryLow, low, medium, high, veryHigh }
```

`Mood` and `EnergyLevel` are plain enums; presentation concerns (color, face shape, label) live in `core/theme/` and `core/l10n/` so the domain stays presentation-agnostic.

`intensity` and `sleepHours` are validated in the controller, not wrapped in value objects.

### 3.2 Drift schema (normalized)

```sql
entries(
  id            TEXT PRIMARY KEY,
  occurred_at   INTEGER NOT NULL,             -- epoch ms
  mood          INTEGER NOT NULL,             -- enum ordinal
  intensity     INTEGER NOT NULL,
  note          TEXT,
  sleep_hours   REAL,
  energy        INTEGER NOT NULL,             -- enum ordinal
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);

tags(
  id     TEXT PRIMARY KEY,
  slug   TEXT NOT NULL UNIQUE,
  label  TEXT NOT NULL
);

entry_tags(
  entry_id TEXT NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
  tag_id   TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (entry_id, tag_id)
);

CREATE INDEX idx_entries_occurred_at ON entries(occurred_at);
CREATE INDEX idx_entry_tags_tag_id   ON entry_tags(tag_id);
```

### 3.3 Repository contract

```dart
abstract class MoodEntryRepository {
  Future<(MoodEntry?, Failure?)> create(MoodEntry entry);
  Future<(MoodEntry?, Failure?)> update(MoodEntry entry);
  Future<(Unit?, Failure?)> delete(String id);
  Future<(MoodEntry?, Failure?)> getById(String id);
  Stream<List<MoodEntry>> watchAll({EntryQuery? query});
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query});
}

class EntryQuery {
  final DateTimeRange? dateRange;
  final ({Mood min, Mood max})? moodRange;
  final List<String>? tagIds;
  final String? text;
  final int? limit;
}
```

Read-only features all consume `watchAll`/`getAll` via `EntryQuery` — single query surface, single source of truth.

### 3.4 Error handling

Result tuples `(T?, Failure?)`. `Failure` is a sealed class in `core/error/`:

```dart
sealed class Failure { final String? debugMessage; }
class DatabaseFailure extends Failure { ... }
class NotFoundFailure extends Failure { ... }
class ValidationFailure extends Failure { final Map<String,String> fieldErrors; }
class IOFailure extends Failure { ... }
class UnknownFailure extends Failure { final Object cause; }
```

Repository implementations catch Drift exceptions and map to `Failure`s; the presentation layer never sees raw exceptions. `Failure → user-facing string` mapping lives in `core/l10n/failure_messages.dart` (localized).

## 4. Presentation Layer & State Management

### 4.1 Provider topology

Three layers per feature:

1. **Infrastructure providers** (`core/`) — singletons wrapping GetIt: `appDatabaseProvider`, `prefsProvider`, `notificationServiceProvider`.
2. **Repository providers** (`features/<feature>/data/`) — return the impl, depend on infra.
3. **Controller providers** (`features/<feature>/providers/`) — `AsyncNotifier`/`Notifier` classes holding screen state and calling repositories.

### 4.2 Screen composition pattern

Screens are thin widget composers. All logic lives in a controller; the screen reads state and delegates intents.

```dart
class LogEntryScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logEntryControllerProvider);
    final controller = ref.read(logEntryControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.logEntryTitle)),
      body: state.when(
        data: (form) => LogEntryForm(form: form, onSubmit: controller.submit),
        loading: () => const LogEntrySkeleton(),
        error: (e, _) => ErrorView(failure: e as Failure, onRetry: controller.retry),
      ),
    );
  }
}
```

### 4.3 Reactive vs one-shot reads

- **History / Calendar / Search / Statistics** → `StreamProvider` wrapping `repository.watchAll(query)`. Live updates as entries change.
- **Log Entry form** → `AsyncNotifierProvider<LogEntryController, LogEntryFormState>`. One-shot; submit triggers a write.
- **Settings** → `NotifierProvider<SettingsController, SettingsState>` backed by `SharedPreferences`.

### 4.4 Form state

Plain Dart class with validation methods — not a tree of `TextEditingController`s. The form widget reads `LogEntryFormState` from the controller and pushes changes via intent methods (`updateMood`, `addTag`, `setIntensity`, ...). Testable without pumping widgets.

### 4.5 Loading & empty states

Skeletonizer shimmer skeletons for any load > 300ms. Each feature ships a `<FeatureName>Skeleton` widget that mirrors the real layout. Shared `EmptyStateView` in `core/widgets/` for empty data.

### 4.6 Error UI

Shared `ErrorView` in `core/widgets/` takes a `Failure` and shows a localized message + retry button.

## 5. Navigation

GoRouter with typed `AppRoutes` constants. Bottom nav with 5 tabs; a centralized FAB on the Today screen for logging.

```
/
  /today                     [tab 1]
    /log                     (modal sheet)
    /entry/:id               (entry detail)
    /entry/:id/edit          (edit sheet)
  /history                   [tab 2]
    /entry/:id               (shared with /today/entry/:id)
  /calendar                  [tab 3]
    /day/:date               (day-detail sheet)
  /insights                  [tab 4]
  /settings                  [tab 5]
    /theme
    /language
    /reminders
    /backup
  /onboarding                (full-screen, redirect target for first run)
```

Onboarding is enforced via a GoRouter `redirect` that checks the `onboardingCompleted` pref. Once true, `/onboarding` is no longer reachable.

State preservation across tab switches via `StatefulShellRoute.indexedStack`.

## 6. Design System

### 6.1 Visual direction

**Style: Soft UI Evolution** — modern soft shadows (clearer than neumorphism, softer than flat), rounded 8-12px corners, 200-300ms motion, WCAG AA+ contrast in both themes.

**Palette: Mental Health (lavender + green).** Light theme is the source of truth; dark uses desaturated tonal variants (not inversions).

```
// Light
primary       #8B5CF6     onPrimary      #FFFFFF
secondary     #C4B5FD     onSecondary    #0F172A
accent        #059669     onAccent       #FFFFFF
background    #FAF5FF     onBackground   #4C1D95
surface       #FFFFFF     onSurface      #4C1D95
muted         #EDEFF9     onMuted        #64748B
border        #EDE9FE
destructive   #DC2626     onDestructive  #FFFFFF
```

**Mood color scale (5 steps)** — derived procedurally by interpolating between `primary` (lavender) and `accent` (green) along a perceptual curve, then validated for ≥3:1 contrast against surface. This means light/dark/intensity overlays all flow from one curve rather than five hand-picked hexes.

### 6.2 Typography

```
display    Lora 700       32sp   line-height 1.25
headline   Lora 600       24sp   1.3
title      Lora 600       18sp   1.4
body       Raleway 400    16sp   1.55
bodySmall  Raleway 400    14sp   1.5
label      Raleway 500    13sp   1.4   (UPPERCASE for chip headers)
caption    Raleway 400    12sp   1.4
```

Loaded via Google Fonts package; preloaded at bootstrap to avoid runtime FOIT.

### 6.3 Spacing / radius / elevation / motion

```
spacing   4 / 8 / 12 / 16 / 20 / 24 / 32 / 48 / 64
radius    xs:6  sm:8  md:12  lg:16  xl:24  pill:9999
elevation e1 (chips) / e2 (cards) / e3 (sheets, modals)
motion    fast:150ms  base:250ms  slow:350ms
          easeOut for enter, easeIn for exit (exit ≈ 70% of enter)
          all animations honor MediaQuery.disableAnimations (reduced-motion)
```

Sizes scaled to design baseline 390×844 via `flutter_screenutil`.

### 6.4 Iconography

**Lucide** icons via `lucide_icons_flutter` — consistent vector stroke, free, large coverage. No system emoji as icons.

**Mood faces are not icons.** They are `CustomPainter` widgets:

- One painter class parameterized by `Mood` (and optionally `intensity` for future face-curvature overlays).
- Paint colors flow in from `context.appColors` so faces are theme-aware without asset swapping.
- Smoothly interpolatable between mood states (curvature, eye position) — useful for selection animations.
- Used in: mood picker cards, entry detail header, optional calendar mini-faces, empty-state illustrations.

### 6.5 Shared widgets

- `MoodFace(mood, intensity, size, color)` — `CustomPainter`.
- `MoodCard(mood, isSelected, onTap)` — wraps `MoodFace` + label + press feedback (scale 0.96 down → 1.05 selected).
- `MoodDot(mood, size)` — small filled circle in mood color.
- `EmptyStateView(title, message, action, illustration)`.
- `ErrorView(failure, onRetry)`.
- `AppChip`, `AppPill`, `AppDivider`, `RangeSelector`.
- `<Feature>Skeleton` per feature.

### 6.6 Accessibility rules baked into the system

- Touch targets ≥ 44pt; hit-area expanded beyond visual bounds for small icons.
- 4.5:1 contrast for body, 3:1 for large text and UI glyphs (verified in both themes).
- Mood is never conveyed by color alone — every dot/cell/legend element has an adjacent face or label.
- Reduced-motion: all animations collapse to instant transitions.
- Dynamic Type honored — text wraps rather than truncates; layouts validated at largest font scale.
- VoiceOver/TalkBack labels on every interactive control; chart screens ship a text-summary string.

## 7. Screen Inventory

### 7.1 Today (`/today`)

The first screen after onboarding. Greeting at top, then "How are you feeling right now?" with the 5 face cards inline. Tapping a face opens the Log Entry sheet pre-populated with that mood. Below: the most recent 3 entries (`MoodDot` + relative time + mood label + first 60 chars of note). The FAB is redundant on this screen — primary log path is the inline face row — but kept for consistency with other tabs.

### 7.2 Log Entry (`/today/log` or `/entry/:id/edit`)

Modal bottom sheet (med-height initial, drag to expand to full). Fields top-to-bottom:

1. Mood: 5 face cards (CustomPainter) in a row. Selected card scales ×1.05 and fills with mood color.
2. Intensity: 1-10 slider with tabular numerals showing current value.
3. Energy: 5 segmented chips (very low → very high).
4. Sleep hours: optional number input with stepper (0.5-hour increments).
5. Tags: chip input with autocomplete from existing tags + "Add new" affordance.
6. Note: multi-line text field with character counter (soft limit 1000).
7. Occurred-at: defaults to now; editable via time picker.

Primary CTA at bottom: "Save". Secondary "Cancel" with unsaved-changes confirm. Form auto-saves a draft to prefs to survive accidental dismissal.

### 7.3 History (`/history`)

Scrollable list (`ListView.builder`) of all entries, newest first. Each row: `MoodDot` + date/time + mood label + first 60 chars of note + small tag indicators. Tap → entry detail. Swipe-left → delete (with undo toast). Search icon in app bar → opens Search sheet.

### 7.4 Calendar (`/calendar`)

Month grid. Each day cell shows a single colored dot tinted by that day's average mood (computed from all entries on that day). A small numeric badge ("×3") appears in the corner if the day has more than one entry. Days without entries are clearly empty. Tap a day → bottom sheet listing that day's entries. Prev/next month chevrons in app bar; "Jump to today" overflow action.

### 7.5 Insights (`/insights`)

Range selector at top: `[7d] [30d] [90d] [all]`. Three sections:

1. **Mood trend** — `fl_chart` line + 20%-opacity area fill. X = time, Y = mood scale 1-5. Tap a point → tooltip with date and entry count.
2. **Mood distribution** — vertical bar chart, 5 bars (one per mood state). Bar tap → reveals count + percentage.
3. **Top tags** — horizontal bar chart, top 10 tags by entry count.

Screen exposes a screen-reader summary string ("Mood trend over 30 days: average 3.2, range 2-5, ...") via `Semantics`.

### 7.6 Settings (`/settings`)

List of subsections:

- Theme (light / dark / system)
- Language (English / Español)
- Reminders (enable + time picker; permission gated)
- Data (export to JSON, import from JSON)
- About (version, licenses)

### 7.7 Onboarding (`/onboarding`)

3 screens with `CustomPainter` illustrations: (1) what the app does, (2) how to log, (3) privacy ("everything stays on this device"). "Skip" in app bar; "Next" → "Get started" CTA. Sets `onboardingCompleted` pref on completion.

## 8. Localization

ARB-based pipeline (English + Spanish). Every UI string lives in `app_en.arb` with `@`-metadata, mirrored in `app_es.arb`. `flutter gen-l10n` produces `AppLocalizations`.

`context.l10n.<key>` access via an extension on `BuildContext`. No string concatenation in widgets — use ARB placeholders + plurals.

`LocaleNotifier` in `core/l10n/` persists the chosen locale via prefs and exposes a Riverpod-watchable locale; `MaterialApp.router` reads it.

`failure_messages.dart` maps each `Failure` subtype to a localized human string with optional context placeholders.

## 9. Testing Strategy

- **Domain** — unit tests for validators and any entity-level logic; pure Dart, fast.
- **Data** — repository implementations tested against an in-memory Drift database (FakeDatabase) — exercises real SQL and the mapper layer end-to-end without I/O.
- **Providers** — `ProviderContainer` tests for controllers, with repository providers overridden by Mockito or hand-rolled fakes.
- **Widgets** — `testWidgets` for each screen happy path + at least one error and one empty state. Skeletons covered.
- **Golden tests** — for `MoodFace` painter (one golden per mood, plus an intensity-overlay scenario) so CustomPainter changes are caught visually.
- **Integration** — at least one end-to-end log → list → edit → delete flow.

`flutter test` must pass at the end of every phase. `flutter analyze` must report 0 issues.

## 10. Implementation Phases

Each phase ships a usable, testable improvement. Subsequent phases assume the foundation is in place.

**Phase 1 — Foundation + first vertical slice.** All `core/` infrastructure (theme tokens, ThemeNotifier, l10n pipeline EN-only, GoRouter + AppRoutes, AppDatabase with full schema and v1 migration, Failure + Result, prefs, GetIt registration, shared widgets including `MoodFace` painter), `features/mood_entry/` end-to-end, `features/history/`, and a wired-up Today screen.

**Phase 2 — Settings + Onboarding + Spanish.** `features/settings/`, `features/onboarding/` with first-run redirect, Spanish ARB translations for everything shipped to date, theme persistence.

**Phase 3 — Calendar + Search/filter.** `features/calendar/` (month grid with mood dots, day-detail sheet), `features/search/` (filter sheet + text search + debounced query providers).

**Phase 4 — Statistics & charts.** `features/statistics/` with `fl_chart` line+area, distribution bars, top-tags bar, range selector, screen-reader summary, reduced-motion handling. Derived providers for aggregations watching the entry stream.

**Phase 5 — Reminders + Export/Import.** `features/reminders/` (notifications service, daily reminder scheduling, permission flow), `features/backup/` (JSON export via share sheet, import with merge-vs-replace, schema-versioned format).

Each phase ends with: `flutter analyze` clean → `flutter test` green → manual smoke pass through the app.

## 11. Out of Scope (explicitly)

- Accounts, auth, cloud sync.
- Right-to-left layouts (no Arabic/Hebrew at launch).
- Wear-OS/watchOS companion.
- Widgets (home-screen).
- Multi-device sync.
- Custom theme palettes beyond light/dark (Material You / dynamic_color deferred).
- Voice logging.
- Third-party integrations (Health, calendar imports).

## 12. Key Decisions Log

| Decision | Choice | Why |
|---|---|---|
| Persistence | Drift | Type-safe SQL, relational schema for entries↔tags, exercises production-grade patterns. |
| State management | Riverpod | Per global preferences; reactive providers pair naturally with Drift streams. |
| DI | GetIt + Riverpod hybrid | GetIt for infra singletons; Riverpod for app state with narrow test override surface. |
| Tags storage | Normalized (`entry_tags` join) | Real reason to pick Drift; keeps queries clean. |
| Error model | Result tuples `(T?, Failure?)` | Per global preferences; no exceptions across layers. |
| Mood faces | `CustomPainter`, not SVG/PNG | Theme-aware, interpolatable, zero asset bytes, exercises an underused primitive. |
| Mood picker | 5 face cards in a row | Highest discoverability, instantly readable, touch-friendly. |
| Style direction | Soft UI Evolution | WCAG AA+ in both themes, modern, calm. |
| Palette | Mental Health (lavender + green) | Best wellness-domain match; both themes fully supported. |
| Type pairing | Lora (heading) + Raleway (body) | Journal-warm serif + humanist sans; overrides global default of Inter for this project. |
| Icon family | Lucide | Vector, consistent stroke, free, ships well in Flutter. |
| Nav structure | 5 bottom tabs + FAB on Today | Full tab budget, FAB for transient logging action; settings as a tab keeps it discoverable. |
| Today screen | Quick-log first + recent | Maximizes logging velocity; the FAB becomes a redundancy. |
| Insights | Trend + distribution + tag bars | Three focused views, each one chart deep. |
| Calendar | Month grid + colored mood dots | Familiar pattern, information-dense without busy. |
