# Mood Tracker — Phase 4 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Insights placeholder with a real Insights tab: range selector (7d/30d/90d/all), five chart sections (mood trend line, mood distribution bars, top tags horizontal bars, sleep↔mood correlation bars, energy↔mood correlation bars), shared Phase 3 cross-tab filter integration, per-chart empty cards, reduced-motion support, screen-reader summaries.

**Architecture:** New `features/statistics/` module. Pure-function aggregators in `domain/` take entries and return view models. A `selectedRangeProvider` (Notifier<InsightsRange>) and an `insightsEntriesProvider` (StreamProvider that merges `entryFilterProvider` ∩ range) feed five derived `Provider<AsyncValue<TView>>` per-chart providers. `InsightsScreen` is a `CustomScrollView` of five `InsightSectionCard`s, each owning its own loading/error/empty state.

**Tech Stack:** Flutter 3.41.9, Riverpod, `fl_chart` (new), existing Drift/GoRouter/Skeletonizer stack.

**Spec:** `docs/superpowers/specs/2026-05-18-phase-4-design.md`

**Predecessor:** Phase 3 complete on `main` (HEAD ~`634e90b`, plus Phase 4 spec commits). 122 tests green; `flutter analyze` clean.

**Pre-existing infrastructure (do NOT re-create):**

- `Mood.score` (getter on the `Mood` enum at `lib/features/mood_entry/domain/enums/mood.dart`, returning `index + 1` → 1..5). The Phase 4 spec mentions `core/extensions/mood_score.dart`; this file is **not** needed — use `Mood.score` directly.
- `AppRoutes.insights = '/insights'` already declared.
- `app_router.dart` already has 5 branches in order `[today, history, calendar, insights, settings]`; the insights branch builds `_PlaceholderScreen('Insights')`. Phase 4 swaps the body of that branch.
- Bottom-nav `NavigationDestination` for Insights already exists with `Icons.show_chart_outlined` / `Icons.show_chart`. Keep this icon.
- ARB keys `navInsights` already present in `app_en.arb` (`"Insights"`) and `app_es.arb` (`"Estadísticas"`).
- `EntryFilter.toEntryQuery()` returns an `EntryQuery` honoring all filter dimensions — reuse for the filter side of the merge.
- `FilterSheet.show(context)` modal entry-point already exists in `features/search/`.
- `ActiveFilterBanner` widget already exists at `lib/features/history/presentation/widgets/active_filter_banner.dart` — reusable as-is (it reads `entryFilterProvider` itself; no parameters).

**Working conventions (carry-over from Phases 1–3):**

- Every Dart file ends with a newline.
- After every task: `flutter analyze` reports 0 issues; `flutter test` passes.
- Commits NEVER include a `Co-Authored-By` trailer.
- Imports sorted alphabetically: package imports first, blank line, then project (relative) imports.
- `const` constructors where possible; `final` locals.
- Generated `lib/l10n/app_localizations*.dart` files are gitignored — never commit them.
- Widget tests touching Google Fonts must set `GoogleFonts.config.allowRuntimeFetching = false` in `setUpAll`.
- Widget tests that subscribe to a Drift `.watch()` stream must use a fake repo emitting `Stream.value(const [])` to avoid `pumpAndSettle` hangs.
- Riverpod `AsyncNotifier` setters: prefer `ref.invalidateSelf()` over force-unwrapping `state.value!`.

---

## Task 1: Add `fl_chart` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Check the current published version**

Run: `flutter pub outdated fl_chart` — won't return anything (not installed yet). Instead use:

Run: `flutter pub add fl_chart`

This adds the latest compatible version to `pubspec.yaml` and runs `pub get`. After it completes, open `pubspec.yaml` and verify a line was added under `dependencies:` (likely something like `fl_chart: ^0.69.x` or newer).

- [ ] **Step 2: Move the dep into the existing "UI" group block**

Edit `pubspec.yaml` so the new `fl_chart:` line sits inside the `# UI` group, alphabetized:

```yaml
  # UI
  fl_chart: ^0.69.2   # ← actual resolved version from `flutter pub add`
  flutter_screenutil: ^5.9.3
  google_fonts: ^6.2.1
  lucide_icons_flutter: ^3.0.5
  skeletonizer: ^2.1.3
```

(Use the version `flutter pub add` actually resolved — keep its `^` form. If a newer version is available, that's fine.)

- [ ] **Step 3: Verify build still works**

Run: `flutter pub get`
Expected: completes without error.
Run: `flutter analyze`
Expected: `No issues found!` (the dep is added but not yet imported).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add fl_chart dependency for Phase 4 charts"
```

---

## Task 2: Add Insights ARB keys (EN + ES)

29 new key pairs. Spec §8.

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_es.arb`

- [ ] **Step 1: Append all 29 EN keys at the end of `app_en.arb` (before the closing `}`)**

Find the closing `}` of the JSON object in `app_en.arb`. Insert a trailing comma on the line above (if not present), then append:

```json
  "insightsTitle": "Insights",
  "@insightsTitle": {},
  "insightsRange7d": "7d",
  "@insightsRange7d": {},
  "insightsRange30d": "30d",
  "@insightsRange30d": {},
  "insightsRange90d": "90d",
  "@insightsRange90d": {},
  "insightsRangeAll": "All",
  "@insightsRangeAll": {},
  "insightsFilterTooltip": "Filter",
  "@insightsFilterTooltip": {},
  "insightsMoodTrend": "Mood trend",
  "@insightsMoodTrend": {},
  "insightsDistribution": "Mood distribution",
  "@insightsDistribution": {},
  "insightsTopTags": "Top tags",
  "@insightsTopTags": {},
  "insightsSleepVsMood": "Sleep vs. mood",
  "@insightsSleepVsMood": {},
  "insightsEnergyVsMood": "Energy vs. mood",
  "@insightsEnergyVsMood": {},
  "insightsTrendEmpty": "Log at least 2 days to see a trend.",
  "@insightsTrendEmpty": {},
  "insightsDistributionEmpty": "No entries in this range yet.",
  "@insightsDistributionEmpty": {},
  "insightsTopTagsEmpty": "Tag some entries to see your top tags.",
  "@insightsTopTagsEmpty": {},
  "insightsSleepEmpty": "Add sleep hours when logging to see this.",
  "@insightsSleepEmpty": {},
  "insightsEnergyEmpty": "Log a few entries to see energy patterns.",
  "@insightsEnergyEmpty": {},
  "insightsTooltipDay": "{date} — avg {avg}\n{count, plural, =1{1 entry} other{{count} entries}}",
  "@insightsTooltipDay": {
    "placeholders": {
      "date": {"type": "String"},
      "avg": {"type": "String"},
      "count": {"type": "int"}
    }
  },
  "insightsTooltipMood": "{label} — {count, plural, =1{1 entry} other{{count} entries}} ({percent}%)",
  "@insightsTooltipMood": {
    "placeholders": {
      "label": {"type": "String"},
      "count": {"type": "int"},
      "percent": {"type": "int"}
    }
  },
  "insightsTooltipTag": "{label} — {count, plural, =1{1 entry} other{{count} entries}}",
  "@insightsTooltipTag": {
    "placeholders": {
      "label": {"type": "String"},
      "count": {"type": "int"}
    }
  },
  "insightsTooltipBucket": "{label} — avg {avg} (n={count})",
  "@insightsTooltipBucket": {
    "placeholders": {
      "label": {"type": "String"},
      "avg": {"type": "String"},
      "count": {"type": "int"}
    }
  },
  "insightsSleepBucketUnder6": "<6h",
  "@insightsSleepBucketUnder6": {},
  "insightsSleepBucket6to7": "6–7h",
  "@insightsSleepBucket6to7": {},
  "insightsSleepBucket7to8": "7–8h",
  "@insightsSleepBucket7to8": {},
  "insightsSleepBucket8to9": "8–9h",
  "@insightsSleepBucket8to9": {},
  "insightsSleepBucket9plus": "≥9h",
  "@insightsSleepBucket9plus": {},
  "a11yTrendSummary": "Mood trend over {days} days. Average {avg}. Range {min} to {max}.",
  "@a11yTrendSummary": {
    "placeholders": {
      "days": {"type": "int"},
      "avg": {"type": "String"},
      "min": {"type": "String"},
      "max": {"type": "String"}
    }
  },
  "a11yDistributionSummary": "{great} great, {good} good, {okay} okay, {bad} bad, {awful} awful.",
  "@a11yDistributionSummary": {
    "placeholders": {
      "great": {"type": "int"},
      "good": {"type": "int"},
      "okay": {"type": "int"},
      "bad": {"type": "int"},
      "awful": {"type": "int"}
    }
  },
  "a11yTopTagsSummary": "Top tags: {summary}.",
  "@a11yTopTagsSummary": {
    "placeholders": {"summary": {"type": "String"}}
  },
  "a11ySleepSummary": "Sleep vs. mood: {summary}.",
  "@a11ySleepSummary": {
    "placeholders": {"summary": {"type": "String"}}
  },
  "a11yEnergySummary": "Energy vs. mood: {summary}.",
  "@a11yEnergySummary": {
    "placeholders": {"summary": {"type": "String"}}
  }
```

- [ ] **Step 2: Append ES mirrors to `app_es.arb`**

```json
  "insightsTitle": "Estadísticas",
  "@insightsTitle": {},
  "insightsRange7d": "7d",
  "@insightsRange7d": {},
  "insightsRange30d": "30d",
  "@insightsRange30d": {},
  "insightsRange90d": "90d",
  "@insightsRange90d": {},
  "insightsRangeAll": "Todo",
  "@insightsRangeAll": {},
  "insightsFilterTooltip": "Filtrar",
  "@insightsFilterTooltip": {},
  "insightsMoodTrend": "Tendencia del ánimo",
  "@insightsMoodTrend": {},
  "insightsDistribution": "Distribución del ánimo",
  "@insightsDistribution": {},
  "insightsTopTags": "Etiquetas principales",
  "@insightsTopTags": {},
  "insightsSleepVsMood": "Sueño vs. ánimo",
  "@insightsSleepVsMood": {},
  "insightsEnergyVsMood": "Energía vs. ánimo",
  "@insightsEnergyVsMood": {},
  "insightsTrendEmpty": "Registra al menos 2 días para ver una tendencia.",
  "@insightsTrendEmpty": {},
  "insightsDistributionEmpty": "Aún no hay entradas en este rango.",
  "@insightsDistributionEmpty": {},
  "insightsTopTagsEmpty": "Etiqueta algunas entradas para ver tus etiquetas principales.",
  "@insightsTopTagsEmpty": {},
  "insightsSleepEmpty": "Añade horas de sueño al registrar para ver esto.",
  "@insightsSleepEmpty": {},
  "insightsEnergyEmpty": "Registra algunas entradas para ver patrones de energía.",
  "@insightsEnergyEmpty": {},
  "insightsTooltipDay": "{date} — prom. {avg}\n{count, plural, =1{1 entrada} other{{count} entradas}}",
  "@insightsTooltipDay": {
    "placeholders": {
      "date": {"type": "String"},
      "avg": {"type": "String"},
      "count": {"type": "int"}
    }
  },
  "insightsTooltipMood": "{label} — {count, plural, =1{1 entrada} other{{count} entradas}} ({percent}%)",
  "@insightsTooltipMood": {
    "placeholders": {
      "label": {"type": "String"},
      "count": {"type": "int"},
      "percent": {"type": "int"}
    }
  },
  "insightsTooltipTag": "{label} — {count, plural, =1{1 entrada} other{{count} entradas}}",
  "@insightsTooltipTag": {
    "placeholders": {
      "label": {"type": "String"},
      "count": {"type": "int"}
    }
  },
  "insightsTooltipBucket": "{label} — prom. {avg} (n={count})",
  "@insightsTooltipBucket": {
    "placeholders": {
      "label": {"type": "String"},
      "avg": {"type": "String"},
      "count": {"type": "int"}
    }
  },
  "insightsSleepBucketUnder6": "<6h",
  "@insightsSleepBucketUnder6": {},
  "insightsSleepBucket6to7": "6–7h",
  "@insightsSleepBucket6to7": {},
  "insightsSleepBucket7to8": "7–8h",
  "@insightsSleepBucket7to8": {},
  "insightsSleepBucket8to9": "8–9h",
  "@insightsSleepBucket8to9": {},
  "insightsSleepBucket9plus": "≥9h",
  "@insightsSleepBucket9plus": {},
  "a11yTrendSummary": "Tendencia del ánimo durante {days} días. Promedio {avg}. Rango de {min} a {max}.",
  "@a11yTrendSummary": {
    "placeholders": {
      "days": {"type": "int"},
      "avg": {"type": "String"},
      "min": {"type": "String"},
      "max": {"type": "String"}
    }
  },
  "a11yDistributionSummary": "{great} excelente, {good} bien, {okay} regular, {bad} mal, {awful} terrible.",
  "@a11yDistributionSummary": {
    "placeholders": {
      "great": {"type": "int"},
      "good": {"type": "int"},
      "okay": {"type": "int"},
      "bad": {"type": "int"},
      "awful": {"type": "int"}
    }
  },
  "a11yTopTagsSummary": "Etiquetas principales: {summary}.",
  "@a11yTopTagsSummary": {
    "placeholders": {"summary": {"type": "String"}}
  },
  "a11ySleepSummary": "Sueño vs. ánimo: {summary}.",
  "@a11ySleepSummary": {
    "placeholders": {"summary": {"type": "String"}}
  },
  "a11yEnergySummary": "Energía vs. ánimo: {summary}.",
  "@a11yEnergySummary": {
    "placeholders": {"summary": {"type": "String"}}
  }
```

- [ ] **Step 3: Regenerate `AppLocalizations`**

Run: `flutter gen-l10n`
Expected: no errors. `lib/l10n/app_localizations.dart` regenerated (gitignored — don't commit it).

- [ ] **Step 4: Verify**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_es.arb
git commit -m "feat(l10n): add 29 Insights ARB key pairs"
```

---

## Task 3: `InsightsRange` enum + `toDateRange`

Spec §4.1.

**Files:**
- Create: `lib/features/statistics/domain/insights_range.dart`
- Test: `test/features/statistics/domain/insights_range_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/statistics/domain/insights_range_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';

void main() {
  // Fixed "now" for deterministic boundary math.
  final now = DateTime(2026, 5, 18, 14, 30); // 2:30pm local
  final today = DateTime(2026, 5, 18);       // start of day

  group('InsightsRangeX.toDateRange', () {
    test('d7 → today inclusive, 7 calendar days', () {
      final r = InsightsRange.d7.toDateRange(now);
      expect(r.start, DateTime(2026, 5, 12));
      expect(r.end, isNull);
    });

    test('d30 → 30 calendar days', () {
      final r = InsightsRange.d30.toDateRange(now);
      expect(r.start, DateTime(2026, 4, 19));
      expect(r.end, isNull);
    });

    test('d90 → 90 calendar days', () {
      final r = InsightsRange.d90.toDateRange(now);
      expect(r.start, DateTime(2026, 2, 18));
      expect(r.end, isNull);
    });

    test('all → both null', () {
      final r = InsightsRange.all.toDateRange(now);
      expect(r.start, isNull);
      expect(r.end, isNull);
    });

    test('start aligns to midnight regardless of clock time', () {
      // ignore: unused_local_variable
      final _ = today; // referenced for reader clarity
      final r = InsightsRange.d7.toDateRange(DateTime(2026, 5, 18, 23, 59));
      expect(r.start!.hour, 0);
      expect(r.start!.minute, 0);
    });
  });

  group('InsightsRangeX.labelKey', () {
    test('returns the right l10n key', () {
      expect(InsightsRange.d7.labelKey, 'insightsRange7d');
      expect(InsightsRange.d30.labelKey, 'insightsRange30d');
      expect(InsightsRange.d90.labelKey, 'insightsRange90d');
      expect(InsightsRange.all.labelKey, 'insightsRangeAll');
    });
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/domain/insights_range_test.dart`
Expected: file fails to compile (`InsightsRange` undefined).

- [ ] **Step 3: Implement**

```dart
// lib/features/statistics/domain/insights_range.dart
enum InsightsRange { d7, d30, d90, all }

extension InsightsRangeX on InsightsRange {
  ({DateTime? start, DateTime? end}) toDateRange(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case InsightsRange.d7:
        return (start: today.subtract(const Duration(days: 6)), end: null);
      case InsightsRange.d30:
        return (start: today.subtract(const Duration(days: 29)), end: null);
      case InsightsRange.d90:
        return (start: today.subtract(const Duration(days: 89)), end: null);
      case InsightsRange.all:
        return (start: null, end: null);
    }
  }

  String get labelKey {
    switch (this) {
      case InsightsRange.d7:
        return 'insightsRange7d';
      case InsightsRange.d30:
        return 'insightsRange30d';
      case InsightsRange.d90:
        return 'insightsRange90d';
      case InsightsRange.all:
        return 'insightsRangeAll';
    }
  }
}
```

- [ ] **Step 4: Run, verify PASS**

Run: `flutter test test/features/statistics/domain/insights_range_test.dart`
Expected: 6 tests pass.

- [ ] **Step 5: Run full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; existing 122 + 6 new = 128 tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/statistics/domain/insights_range.dart \
        test/features/statistics/domain/insights_range_test.dart
git commit -m "feat(statistics): add InsightsRange enum with toDateRange helper"
```

---

## Task 4: `MoodTrendPoint` + `MoodTrendSeries` + `computeMoodTrend`

Spec §4.2 + §4.3. Computes the dense daily-mean series across `[range.start, today]` with `null` for gap days.

**Files:**
- Create: `lib/features/statistics/domain/mood_trend.dart`
- Create: `lib/features/statistics/domain/aggregators.dart` (this task adds `computeMoodTrend` only; later tasks append more functions)
- Test: `test/features/statistics/domain/mood_trend_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/statistics/domain/mood_trend_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/statistics/domain/aggregators.dart';
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';
import 'package:mood_tracker/features/statistics/domain/mood_trend.dart';

MoodEntry _entry({
  required String id,
  required DateTime occurredAt,
  Mood mood = Mood.okay,
}) {
  return MoodEntry(
    id: id,
    occurredAt: occurredAt,
    mood: mood,
    intensity: 5,
    note: null,
    tags: const [],
    sleepHours: null,
    energy: EnergyLevel.medium,
    createdAt: occurredAt,
    updatedAt: occurredAt,
  );
}

void main() {
  final now = DateTime(2026, 5, 18, 14);

  group('computeMoodTrend', () {
    test('empty entries → dense gap series of correct length', () {
      final series = computeMoodTrend(
        entries: const [],
        range: InsightsRange.d7,
        now: now,
      );
      expect(series.points.length, 7);
      expect(series.points.every((p) => p.averageMood == null), isTrue);
      expect(series.daysWithData, 0);
      expect(series.overallAverage, isNull);
    });

    test('single entry → that day has averageMood, others null', () {
      final series = computeMoodTrend(
        entries: [_entry(id: '1', occurredAt: DateTime(2026, 5, 16, 10), mood: Mood.good)],
        range: InsightsRange.d7,
        now: now,
      );
      expect(series.points.length, 7);
      final filled = series.points.where((p) => p.averageMood != null).toList();
      expect(filled.length, 1);
      expect(filled.single.day, DateTime(2026, 5, 16));
      expect(filled.single.averageMood, Mood.good.score.toDouble());
      expect(filled.single.entryCount, 1);
    });

    test('two same-day entries average mood ordinals', () {
      final series = computeMoodTrend(
        entries: [
          _entry(id: 'a', occurredAt: DateTime(2026, 5, 16, 8), mood: Mood.awful),
          _entry(id: 'b', occurredAt: DateTime(2026, 5, 16, 20), mood: Mood.great),
        ],
        range: InsightsRange.d7,
        now: now,
      );
      final filled = series.points.singleWhere((p) => p.averageMood != null);
      expect(filled.entryCount, 2);
      expect(filled.averageMood, (1 + 5) / 2);
    });

    test('series spans range.start..today inclusive', () {
      final series = computeMoodTrend(
        entries: const [],
        range: InsightsRange.d30,
        now: now,
      );
      expect(series.points.first.day, DateTime(2026, 4, 19));
      expect(series.points.last.day, DateTime(2026, 5, 18));
      expect(series.points.length, 30);
    });

    test('all-range with no entries → empty series', () {
      final series = computeMoodTrend(
        entries: const [],
        range: InsightsRange.all,
        now: now,
      );
      expect(series.points, isEmpty);
    });

    test('all-range with entries → spans first-entry-day to today', () {
      final series = computeMoodTrend(
        entries: [
          _entry(id: 'old', occurredAt: DateTime(2026, 5, 15, 9), mood: Mood.okay),
          _entry(id: 'new', occurredAt: DateTime(2026, 5, 17, 9), mood: Mood.good),
        ],
        range: InsightsRange.all,
        now: now,
      );
      expect(series.points.first.day, DateTime(2026, 5, 15));
      expect(series.points.last.day, DateTime(2026, 5, 18));
      expect(series.points.length, 4);
      expect(series.daysWithData, 2);
    });

    test('overallAverage, minDay, maxDay, lowestDay populated', () {
      final series = computeMoodTrend(
        entries: [
          _entry(id: 'a', occurredAt: DateTime(2026, 5, 16, 9), mood: Mood.bad),  // 2
          _entry(id: 'b', occurredAt: DateTime(2026, 5, 17, 9), mood: Mood.great), // 5
        ],
        range: InsightsRange.d7,
        now: now,
      );
      expect(series.overallAverage, (2 + 5) / 2);
      expect(series.minDay, 2);
      expect(series.maxDay, 5);
      expect(series.lowestDay, DateTime(2026, 5, 16));
    });
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/domain/mood_trend_test.dart`
Expected: compile errors (`mood_trend.dart`, `aggregators.dart`, `computeMoodTrend` undefined).

- [ ] **Step 3: Implement `mood_trend.dart`**

```dart
// lib/features/statistics/domain/mood_trend.dart
import 'package:flutter/foundation.dart';

import 'insights_range.dart';

@immutable
class MoodTrendPoint {
  const MoodTrendPoint({
    required this.day,
    required this.averageMood,
    required this.entryCount,
  });

  final DateTime day;
  final double? averageMood;
  final int entryCount;
}

@immutable
class MoodTrendSeries {
  const MoodTrendSeries({required this.points, required this.range});

  final List<MoodTrendPoint> points;
  final InsightsRange range;

  int get daysWithData =>
      points.where((p) => p.averageMood != null).length;

  double? get overallAverage {
    final filled = points.where((p) => p.averageMood != null).toList();
    if (filled.isEmpty) return null;
    final sum = filled.fold<double>(0, (acc, p) => acc + p.averageMood!);
    return sum / filled.length;
  }

  double? get minDay {
    final filled =
        points.where((p) => p.averageMood != null).map((p) => p.averageMood!);
    if (filled.isEmpty) return null;
    return filled.reduce((a, b) => a < b ? a : b);
  }

  double? get maxDay {
    final filled =
        points.where((p) => p.averageMood != null).map((p) => p.averageMood!);
    if (filled.isEmpty) return null;
    return filled.reduce((a, b) => a > b ? a : b);
  }

  DateTime? get lowestDay {
    MoodTrendPoint? best;
    for (final p in points) {
      if (p.averageMood == null) continue;
      if (best == null || p.averageMood! < best.averageMood!) best = p;
    }
    return best?.day;
  }
}
```

- [ ] **Step 4: Implement `aggregators.dart` (just `computeMoodTrend` for now)**

```dart
// lib/features/statistics/domain/aggregators.dart
import '../../mood_entry/domain/entities/mood_entry.dart';
import 'insights_range.dart';
import 'mood_trend.dart';

DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

MoodTrendSeries computeMoodTrend({
  required List<MoodEntry> entries,
  required InsightsRange range,
  required DateTime now,
}) {
  final today = _startOfDay(now);
  final r = range.toDateRange(now);

  // Build groups keyed by start-of-day.
  final byDay = <DateTime, List<MoodEntry>>{};
  for (final e in entries) {
    final key = _startOfDay(e.occurredAt);
    byDay.putIfAbsent(key, () => []).add(e);
  }

  late final DateTime? rangeStart;
  if (range == InsightsRange.all) {
    if (byDay.isEmpty) {
      return MoodTrendSeries(points: const [], range: range);
    }
    rangeStart = byDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  } else {
    rangeStart = r.start;
  }

  final start = rangeStart!;
  final dayCount = today.difference(start).inDays + 1;
  final points = <MoodTrendPoint>[];
  for (var i = 0; i < dayCount; i++) {
    final day = start.add(Duration(days: i));
    final group = byDay[day];
    if (group == null || group.isEmpty) {
      points.add(MoodTrendPoint(day: day, averageMood: null, entryCount: 0));
    } else {
      final sum = group.fold<int>(0, (acc, e) => acc + e.mood.score);
      points.add(MoodTrendPoint(
        day: day,
        averageMood: sum / group.length,
        entryCount: group.length,
      ));
    }
  }
  return MoodTrendSeries(points: points, range: range);
}
```

- [ ] **Step 5: Run, verify PASS**

Run: `flutter test test/features/statistics/domain/mood_trend_test.dart`
Expected: 7 tests pass.

- [ ] **Step 6: Full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; 135 tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/statistics/domain/mood_trend.dart \
        lib/features/statistics/domain/aggregators.dart \
        test/features/statistics/domain/mood_trend_test.dart
git commit -m "feat(statistics): add computeMoodTrend with dense gap-filled day series"
```

---

## Task 5: `MoodDistribution` + `computeDistribution`

Spec §4.2 + §4.3.

**Files:**
- Create: `lib/features/statistics/domain/mood_distribution.dart`
- Modify: `lib/features/statistics/domain/aggregators.dart` (append `computeDistribution`)
- Test: `test/features/statistics/domain/mood_distribution_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/statistics/domain/mood_distribution_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/statistics/domain/aggregators.dart';
import 'package:mood_tracker/features/statistics/domain/mood_distribution.dart';

MoodEntry _entry(String id, Mood m) => MoodEntry(
      id: id,
      occurredAt: DateTime(2026, 5, 18),
      mood: m,
      intensity: 5,
      note: null,
      tags: const [],
      sleepHours: null,
      energy: EnergyLevel.medium,
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );

void main() {
  group('computeDistribution', () {
    test('empty input → all 5 keys present, all zero, total 0', () {
      final d = computeDistribution(const []);
      expect(d.total, 0);
      for (final m in Mood.values) {
        expect(d.counts.containsKey(m), isTrue);
        expect(d.counts[m], 0);
        expect(d.percentage(m), 0);
      }
    });

    test('counts and percentages with mixed input', () {
      final d = computeDistribution([
        _entry('a', Mood.great),
        _entry('b', Mood.great),
        _entry('c', Mood.okay),
        _entry('d', Mood.bad),
      ]);
      expect(d.total, 4);
      expect(d.counts[Mood.great], 2);
      expect(d.counts[Mood.good], 0);
      expect(d.counts[Mood.okay], 1);
      expect(d.counts[Mood.bad], 1);
      expect(d.counts[Mood.awful], 0);
      expect(d.percentage(Mood.great), 0.5);
      expect(d.percentage(Mood.okay), 0.25);
      expect(d.percentage(Mood.awful), 0);
    });
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/domain/mood_distribution_test.dart`
Expected: compile errors.

- [ ] **Step 3: Implement `mood_distribution.dart`**

```dart
// lib/features/statistics/domain/mood_distribution.dart
import 'package:flutter/foundation.dart';

import '../../mood_entry/domain/enums/mood.dart';

@immutable
class MoodDistribution {
  const MoodDistribution({required this.counts, required this.total});

  final Map<Mood, int> counts;
  final int total;

  double percentage(Mood m) {
    if (total == 0) return 0;
    return (counts[m] ?? 0) / total;
  }
}
```

- [ ] **Step 4: Append `computeDistribution` to `aggregators.dart`**

Add (after `computeMoodTrend`):

```dart
import 'mood_distribution.dart';
import '../../mood_entry/domain/enums/mood.dart';
```

(Both already at top? `mood.dart` will need adding — it isn't imported yet. Combine imports alphabetically.)

Updated imports block at the top of `aggregators.dart`:

```dart
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/enums/mood.dart';
import 'insights_range.dart';
import 'mood_distribution.dart';
import 'mood_trend.dart';
```

Then append at the bottom of the file:

```dart
MoodDistribution computeDistribution(List<MoodEntry> entries) {
  final counts = <Mood, int>{
    for (final m in Mood.values) m: 0,
  };
  for (final e in entries) {
    counts[e.mood] = counts[e.mood]! + 1;
  }
  return MoodDistribution(counts: counts, total: entries.length);
}
```

- [ ] **Step 5: Run, verify PASS**

Run: `flutter test test/features/statistics/domain/mood_distribution_test.dart`
Expected: 2 tests pass.

- [ ] **Step 6: Full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; 137 tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/statistics/domain/mood_distribution.dart \
        lib/features/statistics/domain/aggregators.dart \
        test/features/statistics/domain/mood_distribution_test.dart
git commit -m "feat(statistics): add computeDistribution with always-present mood keys"
```

---

## Task 6: `TopTagsView` + `TopTagEntry` + `computeTopTags`

Spec §4.2 + §4.3. Sorted desc by count, ties broken alphabetically by tag slug, cap at `limit` (default 10).

**Files:**
- Create: `lib/features/statistics/domain/top_tags_view.dart`
- Modify: `lib/features/statistics/domain/aggregators.dart` (append `computeTopTags`)
- Test: `test/features/statistics/domain/top_tags_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/statistics/domain/top_tags_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/statistics/domain/aggregators.dart';

Tag _tag(String slug) => Tag(id: 't_$slug', slug: slug, label: slug);

MoodEntry _entry(String id, List<Tag> tags) => MoodEntry(
      id: id,
      occurredAt: DateTime(2026, 5, 18),
      mood: Mood.okay,
      intensity: 5,
      note: null,
      tags: tags,
      sleepHours: null,
      energy: EnergyLevel.medium,
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );

void main() {
  group('computeTopTags', () {
    test('empty input → empty entries, totalTaggedEntries 0', () {
      final v = computeTopTags(const []);
      expect(v.entries, isEmpty);
      expect(v.totalTaggedEntries, 0);
    });

    test('counts and sorts desc by count', () {
      final work = _tag('work');
      final family = _tag('family');
      final run = _tag('run');
      final v = computeTopTags([
        _entry('a', [work, family]),
        _entry('b', [work]),
        _entry('c', [run]),
      ]);
      expect(v.entries.map((e) => e.tag.slug).toList(), ['work', 'family', 'run']);
      expect(v.entries.map((e) => e.count).toList(), [2, 1, 1]);
      expect(v.totalTaggedEntries, 3);
    });

    test('ties broken alphabetically by slug', () {
      final b = _tag('beta');
      final a = _tag('alpha');
      final v = computeTopTags([
        _entry('x', [b, a]),
      ]);
      expect(v.entries.map((e) => e.tag.slug).toList(), ['alpha', 'beta']);
    });

    test('caps at limit (default 10)', () {
      final tags = List.generate(15, (i) => _tag('t${i.toString().padLeft(2, '0')}'));
      final entries = [for (final t in tags) _entry(t.slug, [t])];
      final v = computeTopTags(entries);
      expect(v.entries.length, 10);
      // First 10 t00..t09 by alphabetical tie-break.
      expect(v.entries.map((e) => e.tag.slug).toList(),
          ['t00', 't01', 't02', 't03', 't04', 't05', 't06', 't07', 't08', 't09']);
    });

    test('untagged entries excluded from totalTaggedEntries', () {
      final v = computeTopTags([
        _entry('a', [_tag('x')]),
        _entry('b', const []),
      ]);
      expect(v.totalTaggedEntries, 1);
    });
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/domain/top_tags_test.dart`
Expected: compile errors.

- [ ] **Step 3: Implement `top_tags_view.dart`**

```dart
// lib/features/statistics/domain/top_tags_view.dart
import 'package:flutter/foundation.dart';

import '../../mood_entry/domain/entities/tag.dart';

@immutable
class TopTagEntry {
  const TopTagEntry({required this.tag, required this.count});

  final Tag tag;
  final int count;
}

@immutable
class TopTagsView {
  const TopTagsView({required this.entries, required this.totalTaggedEntries});

  final List<TopTagEntry> entries;
  final int totalTaggedEntries;
}
```

- [ ] **Step 4: Append `computeTopTags` to `aggregators.dart`**

Update import block at top of `aggregators.dart`:

```dart
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/enums/mood.dart';
import 'insights_range.dart';
import 'mood_distribution.dart';
import 'mood_trend.dart';
import 'top_tags_view.dart';
```

Append at the bottom:

```dart
TopTagsView computeTopTags(List<MoodEntry> entries, {int limit = 10}) {
  final counts = <String, ({String slug, String label, int count, String tagId})>{};
  var tagged = 0;
  for (final e in entries) {
    if (e.tags.isEmpty) continue;
    tagged++;
    for (final t in e.tags) {
      final cur = counts[t.id];
      counts[t.id] = (
        slug: t.slug,
        label: t.label,
        count: (cur?.count ?? 0) + 1,
        tagId: t.id,
      );
    }
  }
  final sorted = counts.values.toList()
    ..sort((a, b) {
      final c = b.count.compareTo(a.count);
      if (c != 0) return c;
      return a.slug.compareTo(b.slug);
    });
  final capped = sorted.take(limit).toList();
  return TopTagsView(
    entries: [
      for (final r in capped)
        TopTagEntry(
          tag: _tagFromRecord(r),
          count: r.count,
        ),
    ],
    totalTaggedEntries: tagged,
  );
}
```

Add this small private helper anywhere in the file (e.g. above `computeTopTags`):

```dart
Tag _tagFromRecord(
    ({String slug, String label, int count, String tagId}) r) {
  return Tag(id: r.tagId, slug: r.slug, label: r.label);
}
```

…and import Tag at the top:

```dart
import '../../mood_entry/domain/entities/tag.dart';
```

(Sorted alphabetically: it lands right after `mood_entry.dart` since `entities/tag.dart` > `entities/mood_entry.dart` lexicographically.)

Final import block at the top of `aggregators.dart`:

```dart
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/entities/tag.dart';
import '../../mood_entry/domain/enums/mood.dart';
import 'insights_range.dart';
import 'mood_distribution.dart';
import 'mood_trend.dart';
import 'top_tags_view.dart';
```

- [ ] **Step 5: Run, verify PASS**

Run: `flutter test test/features/statistics/domain/top_tags_test.dart`
Expected: 5 tests pass.

- [ ] **Step 6: Full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; 142 tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/statistics/domain/top_tags_view.dart \
        lib/features/statistics/domain/aggregators.dart \
        test/features/statistics/domain/top_tags_test.dart
git commit -m "feat(statistics): add computeTopTags sorted desc with alphabetical tiebreak"
```

---

## Task 7: `CorrelationView` + `CorrelationBucket` + `SleepBucket` + `computeSleepCorrelation`

Spec §4.2 + §4.3. Half-open `[lo, hi)` buckets; entries with `sleepHours == null` excluded.

**Files:**
- Create: `lib/features/statistics/domain/correlation.dart`
- Modify: `lib/features/statistics/domain/aggregators.dart` (append `computeSleepCorrelation`)
- Test: `test/features/statistics/domain/sleep_correlation_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/statistics/domain/sleep_correlation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/statistics/domain/aggregators.dart';

MoodEntry _e({required String id, required double? sleep, required Mood mood}) =>
    MoodEntry(
      id: id,
      occurredAt: DateTime(2026, 5, 18),
      mood: mood,
      intensity: 5,
      note: null,
      tags: const [],
      sleepHours: sleep,
      energy: EnergyLevel.medium,
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );

void main() {
  group('computeSleepCorrelation', () {
    test('empty → 5 empty buckets in fixed order', () {
      final v = computeSleepCorrelation(const []);
      expect(v.buckets.length, 5);
      expect(v.buckets.map((b) => b.bucketLabelKey).toList(), [
        'insightsSleepBucketUnder6',
        'insightsSleepBucket6to7',
        'insightsSleepBucket7to8',
        'insightsSleepBucket8to9',
        'insightsSleepBucket9plus',
      ]);
      expect(v.buckets.every((b) => b.averageMood == null), isTrue);
      expect(v.nonEmptyBucketCount, 0);
    });

    test('null sleep entries are excluded', () {
      final v = computeSleepCorrelation([
        _e(id: 'a', sleep: null, mood: Mood.great),
        _e(id: 'b', sleep: 7.5, mood: Mood.good),
      ]);
      expect(v.buckets[0].sampleSize, 0);
      expect(v.buckets[2].sampleSize, 1); // 7-8
      expect(v.buckets[2].averageMood, Mood.good.score.toDouble());
      expect(v.nonEmptyBucketCount, 1);
    });

    test('boundary tests on half-open intervals', () {
      final entries = [
        _e(id: '0', sleep: 5.99, mood: Mood.okay),  // <6
        _e(id: '1', sleep: 6.0, mood: Mood.okay),   // 6-7
        _e(id: '2', sleep: 6.99, mood: Mood.okay),  // 6-7
        _e(id: '3', sleep: 7.0, mood: Mood.okay),   // 7-8
        _e(id: '4', sleep: 7.99, mood: Mood.okay),  // 7-8
        _e(id: '5', sleep: 8.0, mood: Mood.okay),   // 8-9
        _e(id: '6', sleep: 8.99, mood: Mood.okay),  // 8-9
        _e(id: '7', sleep: 9.0, mood: Mood.okay),   // 9+
        _e(id: '8', sleep: 12.0, mood: Mood.okay),  // 9+
      ];
      final v = computeSleepCorrelation(entries);
      expect(v.buckets[0].sampleSize, 1); // <6
      expect(v.buckets[1].sampleSize, 2); // 6-7
      expect(v.buckets[2].sampleSize, 2); // 7-8
      expect(v.buckets[3].sampleSize, 2); // 8-9
      expect(v.buckets[4].sampleSize, 2); // 9+
    });

    test('averageMood is mean of mood scores within bucket', () {
      final v = computeSleepCorrelation([
        _e(id: 'a', sleep: 7.5, mood: Mood.awful),  // 1
        _e(id: 'b', sleep: 7.2, mood: Mood.great),  // 5
      ]);
      expect(v.buckets[2].sampleSize, 2);
      expect(v.buckets[2].averageMood, 3.0);
    });
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/domain/sleep_correlation_test.dart`
Expected: compile errors.

- [ ] **Step 3: Implement `correlation.dart`**

```dart
// lib/features/statistics/domain/correlation.dart
import 'package:flutter/foundation.dart';

enum SleepBucket { under6, h6to7, h7to8, h8to9, h9plus }

extension SleepBucketX on SleepBucket {
  String get labelKey {
    switch (this) {
      case SleepBucket.under6:
        return 'insightsSleepBucketUnder6';
      case SleepBucket.h6to7:
        return 'insightsSleepBucket6to7';
      case SleepBucket.h7to8:
        return 'insightsSleepBucket7to8';
      case SleepBucket.h8to9:
        return 'insightsSleepBucket8to9';
      case SleepBucket.h9plus:
        return 'insightsSleepBucket9plus';
    }
  }
}

SleepBucket sleepBucketFor(double hours) {
  if (hours < 6) return SleepBucket.under6;
  if (hours < 7) return SleepBucket.h6to7;
  if (hours < 8) return SleepBucket.h7to8;
  if (hours < 9) return SleepBucket.h8to9;
  return SleepBucket.h9plus;
}

@immutable
class CorrelationBucket {
  const CorrelationBucket({
    required this.bucketLabelKey,
    required this.sampleSize,
    required this.averageMood,
  });

  final String bucketLabelKey;
  final int sampleSize;
  final double? averageMood;
}

@immutable
class CorrelationView {
  const CorrelationView({required this.buckets});

  final List<CorrelationBucket> buckets;

  int get nonEmptyBucketCount =>
      buckets.where((b) => b.sampleSize > 0).length;
}
```

- [ ] **Step 4: Append `computeSleepCorrelation` to `aggregators.dart`**

Update imports at the top of `aggregators.dart` (alphabetical):

```dart
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/entities/tag.dart';
import '../../mood_entry/domain/enums/mood.dart';
import 'correlation.dart';
import 'insights_range.dart';
import 'mood_distribution.dart';
import 'mood_trend.dart';
import 'top_tags_view.dart';
```

Append at the bottom:

```dart
CorrelationView computeSleepCorrelation(List<MoodEntry> entries) {
  final buckets = <SleepBucket, List<int>>{
    for (final b in SleepBucket.values) b: <int>[],
  };
  for (final e in entries) {
    final h = e.sleepHours;
    if (h == null) continue;
    buckets[sleepBucketFor(h)]!.add(e.mood.score);
  }
  return CorrelationView(
    buckets: [
      for (final b in SleepBucket.values)
        CorrelationBucket(
          bucketLabelKey: b.labelKey,
          sampleSize: buckets[b]!.length,
          averageMood: buckets[b]!.isEmpty
              ? null
              : buckets[b]!.reduce((a, c) => a + c) / buckets[b]!.length,
        ),
    ],
  );
}
```

- [ ] **Step 5: Run, verify PASS**

Run: `flutter test test/features/statistics/domain/sleep_correlation_test.dart`
Expected: 4 tests pass.

- [ ] **Step 6: Full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; 146 tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/statistics/domain/correlation.dart \
        lib/features/statistics/domain/aggregators.dart \
        test/features/statistics/domain/sleep_correlation_test.dart
git commit -m "feat(statistics): add SleepBucket + computeSleepCorrelation"
```

---

## Task 8: `computeEnergyCorrelation`

Spec §4.3. Reuses `CorrelationView` / `CorrelationBucket` from Task 7. Always emits 5 buckets, one per `EnergyLevel`, in enum order.

**Files:**
- Modify: `lib/features/statistics/domain/aggregators.dart` (append)
- Test: `test/features/statistics/domain/energy_correlation_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/statistics/domain/energy_correlation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/statistics/domain/aggregators.dart';

MoodEntry _e(String id, EnergyLevel lvl, Mood mood) => MoodEntry(
      id: id,
      occurredAt: DateTime(2026, 5, 18),
      mood: mood,
      intensity: 5,
      note: null,
      tags: const [],
      sleepHours: null,
      energy: lvl,
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );

void main() {
  group('computeEnergyCorrelation', () {
    test('empty → 5 empty buckets in EnergyLevel order', () {
      final v = computeEnergyCorrelation(const []);
      expect(v.buckets.length, 5);
      expect(v.buckets.map((b) => b.bucketLabelKey).toList(),
          ['energyVeryLow', 'energyLow', 'energyMedium', 'energyHigh', 'energyVeryHigh']);
      expect(v.nonEmptyBucketCount, 0);
    });

    test('buckets carry sample size and avg mood', () {
      final v = computeEnergyCorrelation([
        _e('a', EnergyLevel.medium, Mood.good),    // 4
        _e('b', EnergyLevel.medium, Mood.great),   // 5
        _e('c', EnergyLevel.veryLow, Mood.awful),  // 1
      ]);
      expect(v.buckets[0].sampleSize, 1);
      expect(v.buckets[0].averageMood, 1.0);
      expect(v.buckets[2].sampleSize, 2);
      expect(v.buckets[2].averageMood, 4.5);
      expect(v.buckets[4].averageMood, isNull);
      expect(v.nonEmptyBucketCount, 2);
    });
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/domain/energy_correlation_test.dart`
Expected: compile error (`computeEnergyCorrelation` undefined).

- [ ] **Step 3: Append `computeEnergyCorrelation` to `aggregators.dart`**

Update imports (alphabetical):

```dart
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/entities/tag.dart';
import '../../mood_entry/domain/enums/energy_level.dart';
import '../../mood_entry/domain/enums/mood.dart';
import 'correlation.dart';
import 'insights_range.dart';
import 'mood_distribution.dart';
import 'mood_trend.dart';
import 'top_tags_view.dart';
```

Add a small helper near the top (after imports):

```dart
String _energyLabelKey(EnergyLevel level) {
  switch (level) {
    case EnergyLevel.veryLow:
      return 'energyVeryLow';
    case EnergyLevel.low:
      return 'energyLow';
    case EnergyLevel.medium:
      return 'energyMedium';
    case EnergyLevel.high:
      return 'energyHigh';
    case EnergyLevel.veryHigh:
      return 'energyVeryHigh';
  }
}
```

Append at the bottom:

```dart
CorrelationView computeEnergyCorrelation(List<MoodEntry> entries) {
  final buckets = <EnergyLevel, List<int>>{
    for (final l in EnergyLevel.values) l: <int>[],
  };
  for (final e in entries) {
    buckets[e.energy]!.add(e.mood.score);
  }
  return CorrelationView(
    buckets: [
      for (final l in EnergyLevel.values)
        CorrelationBucket(
          bucketLabelKey: _energyLabelKey(l),
          sampleSize: buckets[l]!.length,
          averageMood: buckets[l]!.isEmpty
              ? null
              : buckets[l]!.reduce((a, c) => a + c) / buckets[l]!.length,
        ),
    ],
  );
}
```

- [ ] **Step 4: Run, verify PASS**

Run: `flutter test test/features/statistics/domain/energy_correlation_test.dart`
Expected: 2 tests pass.

- [ ] **Step 5: Full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; 148 tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/statistics/domain/aggregators.dart \
        test/features/statistics/domain/energy_correlation_test.dart
git commit -m "feat(statistics): add computeEnergyCorrelation"
```

---

## Task 9: `accessibility_summaries.dart`

Spec §4 + §6.3. Pure functions that take a view model + `AppLocalizations` and return one sentence per chart.

**Files:**
- Create: `lib/features/statistics/domain/accessibility_summaries.dart`
- Test: `test/features/statistics/domain/accessibility_summaries_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/statistics/domain/accessibility_summaries_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/statistics/domain/accessibility_summaries.dart';
import 'package:mood_tracker/features/statistics/domain/correlation.dart';
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';
import 'package:mood_tracker/features/statistics/domain/mood_distribution.dart';
import 'package:mood_tracker/features/statistics/domain/mood_trend.dart';
import 'package:mood_tracker/features/statistics/domain/top_tags_view.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

Future<AppLocalizations> _loadEn() async =>
    await AppLocalizations.delegate.load(const Locale('en'));

Future<AppLocalizations> _loadEs() async =>
    await AppLocalizations.delegate.load(const Locale('es'));

void main() {
  test('trend summary EN', () async {
    final l = await _loadEn();
    final series = MoodTrendSeries(
      range: InsightsRange.d7,
      points: [
        MoodTrendPoint(day: DateTime(2026, 5, 12), averageMood: 3, entryCount: 1),
        MoodTrendPoint(day: DateTime(2026, 5, 13), averageMood: null, entryCount: 0),
        MoodTrendPoint(day: DateTime(2026, 5, 14), averageMood: 5, entryCount: 1),
        MoodTrendPoint(day: DateTime(2026, 5, 15), averageMood: null, entryCount: 0),
        MoodTrendPoint(day: DateTime(2026, 5, 16), averageMood: null, entryCount: 0),
        MoodTrendPoint(day: DateTime(2026, 5, 17), averageMood: null, entryCount: 0),
        MoodTrendPoint(day: DateTime(2026, 5, 18), averageMood: null, entryCount: 0),
      ],
    );
    expect(trendSummary(series, l), 'Mood trend over 7 days. Average 4.0. Range 3.0 to 5.0.');
  });

  test('distribution summary EN', () async {
    final l = await _loadEn();
    final d = MoodDistribution(counts: const {
      Mood.awful: 0,
      Mood.bad: 1,
      Mood.okay: 2,
      Mood.good: 3,
      Mood.great: 4,
    }, total: 10);
    expect(distributionSummary(d, l), '4 great, 3 good, 2 okay, 1 bad, 0 awful.');
  });

  test('top tags summary EN', () async {
    final l = await _loadEn();
    final v = TopTagsView(entries: [
      TopTagEntry(tag: Tag(id: '1', slug: 'work', label: 'work'), count: 5),
      TopTagEntry(tag: Tag(id: '2', slug: 'run', label: 'run'), count: 2),
    ], totalTaggedEntries: 7);
    expect(topTagsSummary(v, l), 'Top tags: work 5, run 2.');
  });

  test('top tags summary empty EN', () async {
    final l = await _loadEn();
    final v = const TopTagsView(entries: [], totalTaggedEntries: 0);
    expect(topTagsSummary(v, l), 'Top tags: .');
  });

  test('sleep correlation summary ES', () async {
    final l = await _loadEs();
    final v = const CorrelationView(buckets: [
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucketUnder6', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket6to7', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket7to8', sampleSize: 2, averageMood: 3.5),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket8to9', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket9plus', sampleSize: 0, averageMood: null),
    ]);
    expect(sleepSummary(v, l), 'Sueño vs. ánimo: 7–8h prom. 3.5.');
  });

  test('energy correlation summary EN', () async {
    final l = await _loadEn();
    final v = const CorrelationView(buckets: [
      CorrelationBucket(bucketLabelKey: 'energyVeryLow', sampleSize: 1, averageMood: 2.0),
      CorrelationBucket(bucketLabelKey: 'energyLow', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'energyMedium', sampleSize: 3, averageMood: 4.0),
      CorrelationBucket(bucketLabelKey: 'energyHigh', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'energyVeryHigh', sampleSize: 0, averageMood: null),
    ]);
    expect(energySummary(v, l), 'Energy vs. mood: Very low avg 2.0, Medium avg 4.0.');
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/domain/accessibility_summaries_test.dart`
Expected: compile error (file undefined).

- [ ] **Step 3: Implement `accessibility_summaries.dart`**

```dart
// lib/features/statistics/domain/accessibility_summaries.dart
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../l10n/app_localizations.dart';
import 'correlation.dart';
import 'mood_distribution.dart';
import 'mood_trend.dart';
import 'top_tags_view.dart';

String _fmt(double v) => v.toStringAsFixed(1);

@visibleForTesting
String labelForBucketKey(String key, AppLocalizations l) {
  switch (key) {
    case 'insightsSleepBucketUnder6':
      return l.insightsSleepBucketUnder6;
    case 'insightsSleepBucket6to7':
      return l.insightsSleepBucket6to7;
    case 'insightsSleepBucket7to8':
      return l.insightsSleepBucket7to8;
    case 'insightsSleepBucket8to9':
      return l.insightsSleepBucket8to9;
    case 'insightsSleepBucket9plus':
      return l.insightsSleepBucket9plus;
    case 'energyVeryLow':
      return l.energyVeryLow;
    case 'energyLow':
      return l.energyLow;
    case 'energyMedium':
      return l.energyMedium;
    case 'energyHigh':
      return l.energyHigh;
    case 'energyVeryHigh':
      return l.energyVeryHigh;
  }
  return key;
}

String trendSummary(MoodTrendSeries series, AppLocalizations l) {
  final avg = series.overallAverage ?? 0;
  final min = series.minDay ?? 0;
  final max = series.maxDay ?? 0;
  return l.a11yTrendSummary(series.points.length, _fmt(avg), _fmt(min), _fmt(max));
}

String distributionSummary(MoodDistribution d, AppLocalizations l) {
  return l.a11yDistributionSummary(
    d.counts[_great]!, d.counts[_good]!, d.counts[_okay]!, d.counts[_bad]!, d.counts[_awful]!,
  );
}

String topTagsSummary(TopTagsView v, AppLocalizations l) {
  final summary = v.entries.map((e) => '${e.tag.label} ${e.count}').join(', ');
  return l.a11yTopTagsSummary(summary);
}

String sleepSummary(CorrelationView v, AppLocalizations l) {
  final parts = <String>[];
  for (final b in v.buckets) {
    if (b.averageMood == null) continue;
    final shortLabel = labelForBucketKey(b.bucketLabelKey, l);
    parts.add(_bucketPhrase(shortLabel, b.averageMood!, isSleep: true, l: l));
  }
  return l.a11ySleepSummary(parts.join(', '));
}

String energySummary(CorrelationView v, AppLocalizations l) {
  final parts = <String>[];
  for (final b in v.buckets) {
    if (b.averageMood == null) continue;
    final shortLabel = labelForBucketKey(b.bucketLabelKey, l);
    parts.add(_bucketPhrase(shortLabel, b.averageMood!, isSleep: false, l: l));
  }
  return l.a11yEnergySummary(parts.join(', '));
}

String _bucketPhrase(String label, double avg,
    {required bool isSleep, required AppLocalizations l}) {
  // EN: "<label> avg N.N"      / ES: "<label> prom. N.N"
  // Sleep already includes its own "h" suffix in the bucket label.
  return isSleep
      ? '$label ${_avgWord(l)} ${_fmt(avg)}'
      : '$label ${_avgWord(l)} ${_fmt(avg)}';
}

String _avgWord(AppLocalizations l) {
  // Cheap locale check: the EN ARB uses "avg", ES uses "prom.". Both already
  // appear in tooltip strings so we don't need a new key — match l.localeName.
  return l.localeName.startsWith('es') ? 'prom.' : 'avg';
}

const _awful = Mood.awful;
const _bad = Mood.bad;
const _okay = Mood.okay;
const _good = Mood.good;
const _great = Mood.great;
```

…and add the missing import for `Mood`:

```dart
import '../../mood_entry/domain/enums/mood.dart';
```

Final import block:

```dart
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../l10n/app_localizations.dart';
import '../../mood_entry/domain/enums/mood.dart';
import 'correlation.dart';
import 'mood_distribution.dart';
import 'mood_trend.dart';
import 'top_tags_view.dart';
```

- [ ] **Step 4: Run, verify PASS**

Run: `flutter test test/features/statistics/domain/accessibility_summaries_test.dart`
Expected: 6 tests pass.

> **Note for the implementer:** if `_avgWord` produces incorrect output for ES, the test for sleep ES will catch it — adjust the locale check. The test expects `'Sueño vs. ánimo: 7–8h prom. 3.5.'` (note `prom.` not `avg`).

- [ ] **Step 5: Full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; 154 tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/statistics/domain/accessibility_summaries.dart \
        test/features/statistics/domain/accessibility_summaries_test.dart
git commit -m "feat(statistics): add accessibility summary helpers for 5 charts"
```

---

## Task 10: `selected_range_controller.dart` (Notifier)

Spec §5. In-memory `Notifier<InsightsRange>`, default `d30`.

**Files:**
- Create: `lib/features/statistics/providers/selected_range_controller.dart`
- Test: `test/features/statistics/providers/selected_range_controller_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/statistics/providers/selected_range_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';
import 'package:mood_tracker/features/statistics/providers/selected_range_controller.dart';

void main() {
  test('default is d30', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(selectedRangeProvider), InsightsRange.d30);
  });

  test('setter updates state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(selectedRangeProvider.notifier).set(InsightsRange.d90);
    expect(container.read(selectedRangeProvider), InsightsRange.d90);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/providers/selected_range_controller_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

```dart
// lib/features/statistics/providers/selected_range_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/insights_range.dart';

class SelectedRangeController extends Notifier<InsightsRange> {
  @override
  InsightsRange build() => InsightsRange.d30;

  void set(InsightsRange range) => state = range;
}

final selectedRangeProvider =
    NotifierProvider<SelectedRangeController, InsightsRange>(
        SelectedRangeController.new);
```

- [ ] **Step 4: Run, verify PASS, commit**

```bash
flutter test test/features/statistics/providers/selected_range_controller_test.dart
flutter analyze && flutter test
git add lib/features/statistics/providers/selected_range_controller.dart \
        test/features/statistics/providers/selected_range_controller_test.dart
git commit -m "feat(statistics): add SelectedRangeController defaulting to d30"
```

Expected: 156 tests pass.

---

## Task 11: `insights_entries_provider.dart` — filter ∩ range merge

Spec §5. The single StreamProvider that all per-chart providers depend on.

**Files:**
- Create: `lib/features/statistics/providers/insights_entries_provider.dart`
- Test: `test/features/statistics/providers/insights_entries_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/statistics/providers/insights_entries_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/features/search/domain/entry_filter.dart';
import 'package:mood_tracker/features/search/providers/entry_filter_controller.dart';
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';
import 'package:mood_tracker/features/statistics/providers/insights_entries_provider.dart';
import 'package:mood_tracker/features/statistics/providers/selected_range_controller.dart';

class _FakeRepo implements MoodEntryRepository {
  EntryQuery? lastQuery;
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) {
    lastQuery = query;
    return Stream.value(const []);
  }

  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (const <MoodEntry>[], null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry entry) async =>
      (entry, null);
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry entry) async =>
      (entry, null);
  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      (null, NotFoundFailure(id: id));
}

void main() {
  test('empty filter + d7 → query carries range.start, end null', () async {
    final repo = _FakeRepo();
    final now = DateTime(2026, 5, 18);
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
      insightsNowProvider.overrideWithValue(now),
    ]);
    addTearDown(container.dispose);
    container.read(selectedRangeProvider.notifier).set(InsightsRange.d7);
    await container.read(insightsEntriesProvider.future);
    expect(repo.lastQuery!.dateRange!.start, DateTime(2026, 5, 12));
    expect(repo.lastQuery!.dateRange!.end, DateTime(2026, 5, 19));
    expect(repo.lastQuery!.tagIds, isNull);
    expect(repo.lastQuery!.text, isNull);
    expect(repo.lastQuery!.moodRange, isNull);
  });

  test('filter date range + range → intersection (later start, earlier end)',
      () async {
    final repo = _FakeRepo();
    final now = DateTime(2026, 5, 18);
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
      insightsNowProvider.overrideWithValue(now),
    ]);
    addTearDown(container.dispose);
    container.read(entryFilterProvider.notifier).setDateRange(DateTimeRange(
          start: DateTime(2026, 5, 14),
          end: DateTime(2026, 5, 17),
        ));
    container.read(selectedRangeProvider.notifier).set(InsightsRange.d7);
    await container.read(insightsEntriesProvider.future);
    expect(repo.lastQuery!.dateRange!.start, DateTime(2026, 5, 14)); // later
    expect(repo.lastQuery!.dateRange!.end, DateTime(2026, 5, 17));   // earlier
  });

  test('filter tags + range → tags pass through', () async {
    final repo = _FakeRepo();
    final now = DateTime(2026, 5, 18);
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
      insightsNowProvider.overrideWithValue(now),
    ]);
    addTearDown(container.dispose);
    container.read(entryFilterProvider.notifier).setTagIds(['t1', 't2']);
    container.read(selectedRangeProvider.notifier).set(InsightsRange.d30);
    await container.read(insightsEntriesProvider.future);
    expect(repo.lastQuery!.tagIds, ['t1', 't2']);
  });

  test('filter text + mood + range all merged', () async {
    final repo = _FakeRepo();
    final now = DateTime(2026, 5, 18);
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
      insightsNowProvider.overrideWithValue(now),
    ]);
    addTearDown(container.dispose);
    container.read(entryFilterProvider.notifier).setText('run');
    container.read(entryFilterProvider.notifier).setMoodRange(
        (min: Mood.okay, max: Mood.great));
    container.read(selectedRangeProvider.notifier).set(InsightsRange.d90);
    await container.read(insightsEntriesProvider.future);
    expect(repo.lastQuery!.text, 'run');
    expect(repo.lastQuery!.moodRange!.min, Mood.okay);
    expect(repo.lastQuery!.moodRange!.max, Mood.great);
    expect(repo.lastQuery!.dateRange!.start, DateTime(2026, 2, 18));
  });

  test('range "all" → no dateRange unless filter provides one', () async {
    final repo = _FakeRepo();
    final now = DateTime(2026, 5, 18);
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
      insightsNowProvider.overrideWithValue(now),
    ]);
    addTearDown(container.dispose);
    container.read(selectedRangeProvider.notifier).set(InsightsRange.all);
    await container.read(insightsEntriesProvider.future);
    expect(repo.lastQuery!.dateRange, isNull);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/providers/insights_entries_provider_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

```dart
// lib/features/statistics/providers/insights_entries_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood_entry/data/mood_entry_repository_provider.dart';
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/repositories/entry_query.dart';
import '../../search/providers/entry_filter_controller.dart';
import '../domain/insights_range.dart';
import 'selected_range_controller.dart';

/// Overridable for tests; in production reads `DateTime.now()`.
final insightsNowProvider = Provider<DateTime>((_) => DateTime.now());

final insightsEntriesProvider = StreamProvider<List<MoodEntry>>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  final filter = ref.watch(entryFilterProvider);
  final range = ref.watch(selectedRangeProvider);
  final now = ref.watch(insightsNowProvider);

  final base = filter.toEntryQuery();
  final rangeDates = range.toDateRange(now);

  // Compute the inclusive end-of-day for the range so today's entries are
  // included regardless of clock time.
  final inclusiveEnd = rangeDates.start == null
      ? null
      : DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

  DateTimeRange? merged;
  if (rangeDates.start == null) {
    merged = base.dateRange;
  } else if (base.dateRange == null) {
    merged = DateTimeRange(start: rangeDates.start!, end: inclusiveEnd!);
  } else {
    final start = base.dateRange!.start.isAfter(rangeDates.start!)
        ? base.dateRange!.start
        : rangeDates.start!;
    final end = base.dateRange!.end.isBefore(inclusiveEnd!)
        ? base.dateRange!.end
        : inclusiveEnd;
    merged = DateTimeRange(start: start, end: end);
  }

  return repo.watchAll(
    query: EntryQuery(
      dateRange: merged,
      moodRange: base.moodRange,
      tagIds: base.tagIds,
      text: base.text,
    ),
  );
});
```

- [ ] **Step 4: Run, verify PASS**

Run: `flutter test test/features/statistics/providers/insights_entries_provider_test.dart`
Expected: 5 tests pass.

- [ ] **Step 5: Full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; 161 tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/statistics/providers/insights_entries_provider.dart \
        test/features/statistics/providers/insights_entries_provider_test.dart
git commit -m "feat(statistics): add insightsEntriesProvider merging filter and range"
```

---

## Task 12: `chart_providers.dart` — 5 derived per-chart providers

Spec §5. Each is a `Provider<AsyncValue<TView>>` reading `insightsEntriesProvider` + the matching aggregator.

**Files:**
- Create: `lib/features/statistics/providers/chart_providers.dart`
- Test: `test/features/statistics/providers/chart_providers_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/statistics/providers/chart_providers_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';
import 'package:mood_tracker/features/statistics/providers/chart_providers.dart';
import 'package:mood_tracker/features/statistics/providers/insights_entries_provider.dart';
import 'package:mood_tracker/features/statistics/providers/selected_range_controller.dart';

MoodEntry _e(String id, Mood m, {List<Tag> tags = const [], double? sleep, EnergyLevel energy = EnergyLevel.medium}) {
  final t = DateTime(2026, 5, 18, 10);
  return MoodEntry(
    id: id, occurredAt: t, mood: m, intensity: 5, note: null,
    tags: tags, sleepHours: sleep, energy: energy,
    createdAt: t, updatedAt: t,
  );
}

class _FixedRepo implements MoodEntryRepository {
  _FixedRepo(this.data);
  final List<MoodEntry> data;
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) => Stream.value(data);
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (data, null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry entry) async => (entry, null);
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry entry) async => (entry, null);
  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      (null, NotFoundFailure(id: id));
}

ProviderContainer _container(List<MoodEntry> data) {
  final c = ProviderContainer(overrides: [
    moodEntryRepositoryProvider.overrideWithValue(_FixedRepo(data)),
    insightsNowProvider.overrideWithValue(DateTime(2026, 5, 18, 12)),
  ]);
  c.read(selectedRangeProvider.notifier).set(InsightsRange.d7);
  return c;
}

void main() {
  test('moodTrendProvider emits data with daysWithData', () async {
    final c = _container([_e('a', Mood.good)]);
    addTearDown(c.dispose);
    await c.read(insightsEntriesProvider.future);
    final v = c.read(moodTrendProvider).value!;
    expect(v.daysWithData, 1);
  });

  test('moodDistributionProvider returns total', () async {
    final c = _container([_e('a', Mood.great), _e('b', Mood.bad)]);
    addTearDown(c.dispose);
    await c.read(insightsEntriesProvider.future);
    expect(c.read(moodDistributionProvider).value!.total, 2);
  });

  test('topTagsProvider returns entries', () async {
    final c = _container([_e('a', Mood.okay, tags: [const Tag(id: 't', slug: 's', label: 'l')])]);
    addTearDown(c.dispose);
    await c.read(insightsEntriesProvider.future);
    final v = c.read(topTagsProvider).value!;
    expect(v.entries.single.tag.id, 't');
  });

  test('sleepCorrelationProvider returns view', () async {
    final c = _container([_e('a', Mood.good, sleep: 7.5)]);
    addTearDown(c.dispose);
    await c.read(insightsEntriesProvider.future);
    expect(c.read(sleepCorrelationProvider).value!.nonEmptyBucketCount, 1);
  });

  test('energyCorrelationProvider returns view', () async {
    final c = _container([_e('a', Mood.good, energy: EnergyLevel.high)]);
    addTearDown(c.dispose);
    await c.read(insightsEntriesProvider.future);
    final v = c.read(energyCorrelationProvider).value!;
    expect(v.buckets[3].sampleSize, 1);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/providers/chart_providers_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

```dart
// lib/features/statistics/providers/chart_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/aggregators.dart';
import '../domain/correlation.dart';
import '../domain/mood_distribution.dart';
import '../domain/mood_trend.dart';
import '../domain/top_tags_view.dart';
import 'insights_entries_provider.dart';
import 'selected_range_controller.dart';

final moodTrendProvider = Provider<AsyncValue<MoodTrendSeries>>((ref) {
  final entries = ref.watch(insightsEntriesProvider);
  final range = ref.watch(selectedRangeProvider);
  final now = ref.watch(insightsNowProvider);
  return entries.whenData(
      (data) => computeMoodTrend(entries: data, range: range, now: now));
});

final moodDistributionProvider = Provider<AsyncValue<MoodDistribution>>((ref) {
  final entries = ref.watch(insightsEntriesProvider);
  return entries.whenData(computeDistribution);
});

final topTagsProvider = Provider<AsyncValue<TopTagsView>>((ref) {
  final entries = ref.watch(insightsEntriesProvider);
  return entries.whenData((data) => computeTopTags(data));
});

final sleepCorrelationProvider = Provider<AsyncValue<CorrelationView>>((ref) {
  final entries = ref.watch(insightsEntriesProvider);
  return entries.whenData(computeSleepCorrelation);
});

final energyCorrelationProvider = Provider<AsyncValue<CorrelationView>>((ref) {
  final entries = ref.watch(insightsEntriesProvider);
  return entries.whenData(computeEnergyCorrelation);
});
```

- [ ] **Step 4: Run, verify PASS, commit**

```bash
flutter test test/features/statistics/providers/chart_providers_test.dart
flutter analyze && flutter test
git add lib/features/statistics/providers/chart_providers.dart \
        test/features/statistics/providers/chart_providers_test.dart
git commit -m "feat(statistics): add 5 per-chart derived providers"
```

Expected: 166 tests pass.

---

## Task 13: `RangeSelector` widget

Spec §6.4. Horizontal `AppChip` strip; reads `selectedRangeProvider`; tap → setter.

**Files:**
- Create: `lib/features/statistics/presentation/widgets/range_selector.dart`
- Test: `test/features/statistics/presentation/range_selector_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/statistics/presentation/range_selector_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';
import 'package:mood_tracker/features/statistics/presentation/widgets/range_selector.dart';
import 'package:mood_tracker/features/statistics/providers/selected_range_controller.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget harness({required ProviderContainer container}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: RangeSelector()),
      ),
    );
  }

  testWidgets('renders 4 chips with EN labels', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(harness(container: c));
    await tester.pump();
    expect(find.text('7d'), findsOneWidget);
    expect(find.text('30d'), findsOneWidget);
    expect(find.text('90d'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('tapping a chip updates selectedRangeProvider', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(harness(container: c));
    await tester.pump();
    await tester.tap(find.text('90d'));
    await tester.pump();
    expect(c.read(selectedRangeProvider), InsightsRange.d90);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/presentation/range_selector_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

```dart
// lib/features/statistics/presentation/widgets/range_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../domain/insights_range.dart';
import '../../providers/selected_range_controller.dart';

class RangeSelector extends ConsumerWidget {
  const RangeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedRangeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (final r in InsightsRange.values) ...[
            AppChip(
              label: _label(context, r),
              selected: r == selected,
              onTap: () =>
                  ref.read(selectedRangeProvider.notifier).set(r),
            ),
            if (r != InsightsRange.values.last)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }

  String _label(BuildContext context, InsightsRange r) {
    final l = context.l10n;
    switch (r) {
      case InsightsRange.d7:
        return l.insightsRange7d;
      case InsightsRange.d30:
        return l.insightsRange30d;
      case InsightsRange.d90:
        return l.insightsRange90d;
      case InsightsRange.all:
        return l.insightsRangeAll;
    }
  }
}
```

- [ ] **Step 4: Run, verify PASS, commit**

```bash
flutter test test/features/statistics/presentation/range_selector_test.dart
flutter analyze && flutter test
git add lib/features/statistics/presentation/widgets/range_selector.dart \
        test/features/statistics/presentation/range_selector_test.dart
git commit -m "feat(statistics): add RangeSelector chip strip widget"
```

Expected: 168 tests pass.

---

## Task 14: `InsightSectionCard<T>` wrapper

Spec §6.1. Generic card that handles `AsyncValue.when(loading|error|data)` + an `isEmpty` check.

**Files:**
- Create: `lib/features/statistics/presentation/widgets/insight_section_card.dart`
- Test: `test/features/statistics/presentation/insight_section_card_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/statistics/presentation/insight_section_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/statistics/presentation/widgets/insight_section_card.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProviderScope(child: Scaffold(body: card)),
    ));
    await tester.pump();
  }

  testWidgets('loading state shows skeleton placeholder', (tester) async {
    await pumpCard(
      tester,
      InsightSectionCard<int>(
        title: 'T',
        value: const AsyncValue.loading(),
        isEmpty: (v) => false,
        emptyMessage: 'empty',
        builder: (v) => Text('value: $v'),
      ),
    );
    expect(find.text('T'), findsOneWidget);
    expect(find.text('value: 0'), findsNothing);
  });

  testWidgets('error state shows retry message', (tester) async {
    await pumpCard(
      tester,
      InsightSectionCard<int>(
        title: 'T',
        value: AsyncValue.error(const UnknownFailure(), StackTrace.empty),
        isEmpty: (v) => false,
        emptyMessage: 'empty',
        builder: (v) => Text('value: $v'),
      ),
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('empty state shows the emptyMessage', (tester) async {
    await pumpCard(
      tester,
      InsightSectionCard<int>(
        title: 'T',
        value: const AsyncValue.data(0),
        isEmpty: (v) => true,
        emptyMessage: 'empty message',
        builder: (v) => Text('value: $v'),
      ),
    );
    expect(find.text('empty message'), findsOneWidget);
  });

  testWidgets('data state calls builder', (tester) async {
    await pumpCard(
      tester,
      InsightSectionCard<int>(
        title: 'T',
        value: const AsyncValue.data(42),
        isEmpty: (v) => false,
        emptyMessage: 'empty',
        builder: (v) => Text('value: $v'),
      ),
    );
    expect(find.text('value: 42'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/presentation/insight_section_card_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

```dart
// lib/features/statistics/presentation/widgets/insight_section_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class InsightSectionCard<T> extends ConsumerWidget {
  const InsightSectionCard({
    super.key,
    required this.title,
    required this.value,
    required this.isEmpty,
    required this.emptyMessage,
    required this.builder,
    this.accessibilitySummary,
  });

  final String title;
  final AsyncValue<T> value;
  final bool Function(T value) isEmpty;
  final String emptyMessage;
  final Widget Function(T value) builder;
  final String? accessibilitySummary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBR),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            value.when(
              loading: () => Skeletonizer(
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: colors.muted,
                    borderRadius: AppRadius.smBR,
                  ),
                ),
              ),
              error: (_, __) => SizedBox(
                height: 80,
                child: Center(
                  child: Icon(
                    Icons.error_outline,
                    color: colors.onMuted,
                  ),
                ),
              ),
              data: (data) {
                if (isEmpty(data)) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      emptyMessage,
                      style: AppTextStyles.body.copyWith(color: colors.onMuted),
                    ),
                  );
                }
                final child = builder(data);
                if (accessibilitySummary == null) return child;
                return Semantics(
                  label: accessibilitySummary,
                  container: true,
                  child: ExcludeSemantics(child: child),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run, verify PASS, commit**

```bash
flutter test test/features/statistics/presentation/insight_section_card_test.dart
flutter analyze && flutter test
git add lib/features/statistics/presentation/widgets/insight_section_card.dart \
        test/features/statistics/presentation/insight_section_card_test.dart
git commit -m "feat(statistics): add generic InsightSectionCard wrapper"
```

Expected: 172 tests pass.

---

## Task 15: `MoodTrendChart`

Spec §6.2. `fl_chart` `LineChart` with area fill. Renders null-gap-aware data.

**Files:**
- Create: `lib/features/statistics/presentation/widgets/mood_trend_chart.dart`
- Test: `test/features/statistics/presentation/mood_trend_chart_test.dart`

- [ ] **Step 1: Write the smoke test**

```dart
// test/features/statistics/presentation/mood_trend_chart_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/statistics/domain/insights_range.dart';
import 'package:mood_tracker/features/statistics/domain/mood_trend.dart';
import 'package:mood_tracker/features/statistics/presentation/widgets/mood_trend_chart.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders without throwing for non-empty series', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final series = MoodTrendSeries(range: InsightsRange.d7, points: [
      MoodTrendPoint(day: DateTime(2026, 5, 12), averageMood: 3, entryCount: 1),
      MoodTrendPoint(day: DateTime(2026, 5, 13), averageMood: null, entryCount: 0),
      MoodTrendPoint(day: DateTime(2026, 5, 14), averageMood: 4, entryCount: 1),
      MoodTrendPoint(day: DateTime(2026, 5, 15), averageMood: 5, entryCount: 1),
      MoodTrendPoint(day: DateTime(2026, 5, 16), averageMood: null, entryCount: 0),
      MoodTrendPoint(day: DateTime(2026, 5, 17), averageMood: 2, entryCount: 1),
      MoodTrendPoint(day: DateTime(2026, 5, 18), averageMood: 3, entryCount: 1),
    ]);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(height: 240, child: MoodTrendChart(series: series))),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/presentation/mood_trend_chart_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement**

```dart
// lib/features/statistics/presentation/widgets/mood_trend_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../domain/mood_trend.dart';

class MoodTrendChart extends StatelessWidget {
  const MoodTrendChart({super.key, required this.series});

  final MoodTrendSeries series;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Build segments split by null gaps.
    final segments = <List<FlSpot>>[];
    List<FlSpot> current = [];
    for (var i = 0; i < series.points.length; i++) {
      final p = series.points[i];
      if (p.averageMood == null) {
        if (current.isNotEmpty) {
          segments.add(current);
          current = [];
        }
      } else {
        current.add(FlSpot(i.toDouble(), p.averageMood!));
      }
    }
    if (current.isNotEmpty) segments.add(current);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 1,
          maxY: 5,
          minX: 0,
          maxX: (series.points.length - 1).toDouble().clamp(0, double.infinity),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 24,
              ),
            ),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _bottomInterval(series.points.length),
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= series.points.length) {
                    return const SizedBox.shrink();
                  }
                  final d = series.points[idx].day;
                  return Text('${d.month}/${d.day}',
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          lineBarsData: [
            for (final seg in segments)
              LineChartBarData(
                spots: seg,
                isCurved: true,
                color: colors.primary,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: colors.primary.withValues(alpha: 0.2),
                ),
              ),
          ],
          lineTouchData: const LineTouchData(enabled: true),
        ),
        duration: reduceMotion ? Duration.zero : AppMotion.base,
      ),
    );
  }

  static double _bottomInterval(int days) {
    if (days <= 8) return 1;
    if (days <= 32) return (days / 4).floorToDouble();
    return (days / 6).floorToDouble();
  }
}
```

- [ ] **Step 4: Run, verify PASS, commit**

```bash
flutter test test/features/statistics/presentation/mood_trend_chart_test.dart
flutter analyze && flutter test
git add lib/features/statistics/presentation/widgets/mood_trend_chart.dart \
        test/features/statistics/presentation/mood_trend_chart_test.dart
git commit -m "feat(statistics): add MoodTrendChart line + area widget"
```

Expected: 173 tests pass.

---

## Task 16: `MoodDistributionChart`

Spec §6.2. Vertical `BarChart`, 5 bars, ghost outline for 0-count.

**Files:**
- Create: `lib/features/statistics/presentation/widgets/mood_distribution_chart.dart`
- Test: `test/features/statistics/presentation/mood_distribution_chart_test.dart`

- [ ] **Step 1: Write the smoke test**

```dart
// test/features/statistics/presentation/mood_distribution_chart_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/statistics/domain/mood_distribution.dart';
import 'package:mood_tracker/features/statistics/presentation/widgets/mood_distribution_chart.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders 5 bars including zero-count buckets', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final d = MoodDistribution(counts: const {
      Mood.awful: 0,
      Mood.bad: 1,
      Mood.okay: 2,
      Mood.good: 3,
      Mood.great: 4,
    }, total: 10);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(height: 240, child: MoodDistributionChart(data: d))),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/presentation/mood_distribution_chart_test.dart`

- [ ] **Step 3: Implement**

```dart
// lib/features/statistics/presentation/widgets/mood_distribution_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../mood_entry/domain/enums/mood.dart';
import '../../domain/mood_distribution.dart';

class MoodDistributionChart extends StatelessWidget {
  const MoodDistributionChart({super.key, required this.data});

  final MoodDistribution data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final maxCount = data.counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxCount == 0 ? 1 : maxCount).toDouble();

    Color barColor(Mood m) {
      final t = m.index / (Mood.values.length - 1);
      return Color.lerp(colors.primary, colors.accent, t)!;
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= Mood.values.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(_label(Mood.values[i]),
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(enabled: true),
          barGroups: [
            for (var i = 0; i < Mood.values.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: (data.counts[Mood.values[i]] ?? 0).toDouble(),
                  color: data.counts[Mood.values[i]] == 0
                      ? colors.muted
                      : barColor(Mood.values[i]),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ]),
          ],
        ),
        duration: reduceMotion ? Duration.zero : AppMotion.base,
      ),
    );
  }

  static String _label(Mood m) {
    switch (m) {
      case Mood.awful:
        return '😩';
      case Mood.bad:
        return '🙁';
      case Mood.okay:
        return '😐';
      case Mood.good:
        return '🙂';
      case Mood.great:
        return '😄';
    }
  }
}
```

> **Note:** The emoji labels here are placeholder axis ticks; the real mood face glyphs are deferred to a polish pass (see spec §2 "Out of scope"). If the analyzer complains about emoji in source, swap for short text labels (`'1'..'5'`).

- [ ] **Step 4: Run, verify PASS, commit**

```bash
flutter test test/features/statistics/presentation/mood_distribution_chart_test.dart
flutter analyze && flutter test
git add lib/features/statistics/presentation/widgets/mood_distribution_chart.dart \
        test/features/statistics/presentation/mood_distribution_chart_test.dart
git commit -m "feat(statistics): add MoodDistributionChart 5-bar widget"
```

Expected: 174 tests pass.

---

## Task 17: `TopTagsChart`

Spec §6.2. Horizontal bar chart (rotated `BarChart`).

**Files:**
- Create: `lib/features/statistics/presentation/widgets/top_tags_chart.dart`
- Test: `test/features/statistics/presentation/top_tags_chart_test.dart`

- [ ] **Step 1: Write the smoke test**

```dart
// test/features/statistics/presentation/top_tags_chart_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/statistics/domain/top_tags_view.dart';
import 'package:mood_tracker/features/statistics/presentation/widgets/top_tags_chart.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders top tags without throwing', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final v = TopTagsView(entries: [
      TopTagEntry(tag: const Tag(id: 'w', slug: 'work', label: 'work'), count: 5),
      TopTagEntry(tag: const Tag(id: 'f', slug: 'family', label: 'family'), count: 3),
    ], totalTaggedEntries: 8);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(height: 240, child: TopTagsChart(data: v))),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('work'), findsOneWidget);
    expect(find.text('family'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/presentation/top_tags_chart_test.dart`

- [ ] **Step 3: Implement**

```dart
// lib/features/statistics/presentation/widgets/top_tags_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/top_tags_view.dart';

class TopTagsChart extends StatelessWidget {
  const TopTagsChart({super.key, required this.data});

  final TopTagsView data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final maxCount = data.entries.fold<int>(0, (a, e) => a > e.count ? a : e.count);
    final maxX = (maxCount == 0 ? 1 : maxCount).toDouble();

    return SizedBox(
      height: 36.0 * data.entries.length + 24,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          minY: 0,
          maxY: data.entries.length.toDouble(),
          minX: 0,
          maxX: maxX,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 80,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Text(data.entries[i].tag.label,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(enabled: true),
          barGroups: [
            for (var i = 0; i < data.entries.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: data.entries[i].count.toDouble(),
                  color: colors.primary,
                  width: 16,
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(4)),
                ),
              ]),
          ],
        ),
        duration: reduceMotion ? Duration.zero : AppMotion.base,
      ),
    );
  }
}
```

> **Note on rotation:** `fl_chart`'s `BarChart` does not have a single-prop horizontal mode. The chart above renders vertical bars with the tag label on the leading axis — visually close enough to the spec's horizontal-bar intent for Phase 4. A true horizontal layout (rotated 90°) can be a polish pass.

- [ ] **Step 4: Run, verify PASS, commit**

```bash
flutter test test/features/statistics/presentation/top_tags_chart_test.dart
flutter analyze && flutter test
git add lib/features/statistics/presentation/widgets/top_tags_chart.dart \
        test/features/statistics/presentation/top_tags_chart_test.dart
git commit -m "feat(statistics): add TopTagsChart widget"
```

Expected: 175 tests pass.

---

## Task 18: `SleepCorrelationChart` + `EnergyCorrelationChart`

Spec §6.2. Both are 5-bar vertical charts with bucket labels on the X axis. Shared structure → one task, two files.

**Files:**
- Create: `lib/features/statistics/presentation/widgets/correlation_chart.dart` (shared private widget)
- Create: `lib/features/statistics/presentation/widgets/sleep_correlation_chart.dart`
- Create: `lib/features/statistics/presentation/widgets/energy_correlation_chart.dart`
- Test: `test/features/statistics/presentation/correlation_charts_test.dart`

- [ ] **Step 1: Write the smoke tests**

```dart
// test/features/statistics/presentation/correlation_charts_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/statistics/domain/correlation.dart';
import 'package:mood_tracker/features/statistics/presentation/widgets/energy_correlation_chart.dart';
import 'package:mood_tracker/features/statistics/presentation/widgets/sleep_correlation_chart.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

CorrelationView _v() => const CorrelationView(buckets: [
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucketUnder6', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket6to7', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket7to8', sampleSize: 2, averageMood: 3.5),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket8to9', sampleSize: 1, averageMood: 4.0),
      CorrelationBucket(bucketLabelKey: 'insightsSleepBucket9plus', sampleSize: 0, averageMood: null),
    ]);

CorrelationView _vEnergy() => const CorrelationView(buckets: [
      CorrelationBucket(bucketLabelKey: 'energyVeryLow', sampleSize: 1, averageMood: 2.0),
      CorrelationBucket(bucketLabelKey: 'energyLow', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'energyMedium', sampleSize: 3, averageMood: 4.0),
      CorrelationBucket(bucketLabelKey: 'energyHigh', sampleSize: 0, averageMood: null),
      CorrelationBucket(bucketLabelKey: 'energyVeryHigh', sampleSize: 0, averageMood: null),
    ]);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> wrap(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(height: 240, child: child)),
    ));
    await tester.pump();
  }

  testWidgets('SleepCorrelationChart renders', (tester) async {
    await wrap(tester, SleepCorrelationChart(data: _v()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('EnergyCorrelationChart renders', (tester) async {
    await wrap(tester, EnergyCorrelationChart(data: _vEnergy()));
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/presentation/correlation_charts_test.dart`

- [ ] **Step 3: Implement the shared widget**

```dart
// lib/features/statistics/presentation/widgets/correlation_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../domain/accessibility_summaries.dart';
import '../../domain/correlation.dart';

class CorrelationChart extends StatelessWidget {
  const CorrelationChart({super.key, required this.data});

  final CorrelationView data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final maxAvg = data.buckets.fold<double>(
        0, (a, b) => (b.averageMood ?? 0) > a ? b.averageMood! : a);
    final maxY = maxAvg < 5 ? 5.0 : maxAvg;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 24,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.buckets.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    labelForBucketKey(
                        data.buckets[i].bucketLabelKey, context.l10n),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(enabled: true),
          barGroups: [
            for (var i = 0; i < data.buckets.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: data.buckets[i].averageMood ?? 0,
                  color: data.buckets[i].sampleSize == 0
                      ? colors.muted
                      : colors.primary,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ]),
          ],
        ),
        duration: reduceMotion ? Duration.zero : AppMotion.base,
      ),
    );
  }
}
```

- [ ] **Step 4: Implement the two thin wrappers**

```dart
// lib/features/statistics/presentation/widgets/sleep_correlation_chart.dart
import 'package:flutter/material.dart';

import '../../domain/correlation.dart';
import 'correlation_chart.dart';

class SleepCorrelationChart extends StatelessWidget {
  const SleepCorrelationChart({super.key, required this.data});
  final CorrelationView data;

  @override
  Widget build(BuildContext context) => CorrelationChart(data: data);
}
```

```dart
// lib/features/statistics/presentation/widgets/energy_correlation_chart.dart
import 'package:flutter/material.dart';

import '../../domain/correlation.dart';
import 'correlation_chart.dart';

class EnergyCorrelationChart extends StatelessWidget {
  const EnergyCorrelationChart({super.key, required this.data});
  final CorrelationView data;

  @override
  Widget build(BuildContext context) => CorrelationChart(data: data);
}
```

- [ ] **Step 5: Run, verify PASS, commit**

```bash
flutter test test/features/statistics/presentation/correlation_charts_test.dart
flutter analyze && flutter test
git add lib/features/statistics/presentation/widgets/correlation_chart.dart \
        lib/features/statistics/presentation/widgets/sleep_correlation_chart.dart \
        lib/features/statistics/presentation/widgets/energy_correlation_chart.dart \
        test/features/statistics/presentation/correlation_charts_test.dart
git commit -m "feat(statistics): add sleep + energy correlation charts"
```

Expected: 177 tests pass.

---

## Task 19: `InsightsScreen`

Spec §6.1. Composes the five `InsightSectionCard`s with the range selector pinned at top and `ActiveFilterBanner` reused.

**Files:**
- Create: `lib/features/statistics/presentation/screens/insights_screen.dart`
- Test: `test/features/statistics/presentation/insights_screen_test.dart`

- [ ] **Step 1: Write the screen test**

```dart
// test/features/statistics/presentation/insights_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/features/search/providers/entry_filter_controller.dart';
import 'package:mood_tracker/features/statistics/presentation/screens/insights_screen.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

class _EmptyRepo implements MoodEntryRepository {
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) => Stream.value(const []);
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (const <MoodEntry>[], null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry entry) async => (entry, null);
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry entry) async => (entry, null);
  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      (null, NotFoundFailure(id: id));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester, {ProviderContainer? container}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = container ?? ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const InsightsScreen(),
      ),
    ));
    await tester.pump();
  }

  testWidgets('renders title, range selector and 5 section titles', (tester) async {
    await pump(tester);
    expect(find.text('Insights'), findsWidgets); // app bar + nav reuse possible
    expect(find.text('Mood trend'), findsOneWidget);
    expect(find.text('Mood distribution'), findsOneWidget);
    expect(find.text('Top tags'), findsOneWidget);
    expect(find.text('Sleep vs. mood'), findsOneWidget);
    expect(find.text('Energy vs. mood'), findsOneWidget);
    expect(find.text('30d'), findsOneWidget);
  });

  testWidgets('filter banner shows when filter is active', (tester) async {
    final c = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
    ]);
    c.read(entryFilterProvider.notifier).setText('run');
    await pump(tester, container: c);
    // ActiveFilterBanner exists; verify its presence via the (existing) test key
    // if defined, or by detecting any "Clear" / "Limpiar" label rendered.
    expect(find.byKey(const ValueKey('active_filter_banner')), findsOneWidget);
  });
}
```

> **Note for implementer:** if `ActiveFilterBanner` does not currently expose `ValueKey('active_filter_banner')`, add it in this task. Modify `lib/features/history/presentation/widgets/active_filter_banner.dart`: add `key: const ValueKey('active_filter_banner')` to the root widget the banner returns when active. This is the only edit outside the new feature folder for the banner.

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/statistics/presentation/insights_screen_test.dart`

- [ ] **Step 3: Implement `InsightsScreen`**

```dart
// lib/features/statistics/presentation/screens/insights_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../history/presentation/widgets/active_filter_banner.dart';
import '../../../search/presentation/widgets/filter_sheet.dart';
import '../../domain/accessibility_summaries.dart';
import '../../domain/mood_distribution.dart';
import '../../providers/chart_providers.dart';
import '../widgets/energy_correlation_chart.dart';
import '../widgets/insight_section_card.dart';
import '../widgets/mood_distribution_chart.dart';
import '../widgets/mood_trend_chart.dart';
import '../widgets/range_selector.dart';
import '../widgets/sleep_correlation_chart.dart';
import '../widgets/top_tags_chart.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.insightsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.insightsFilterTooltip,
            onPressed: () => FilterSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const RangeSelector(),
          const ActiveFilterBanner(),
          Expanded(
            child: ListView(
              children: [
                InsightSectionCard(
                  title: l10n.insightsMoodTrend,
                  value: ref.watch(moodTrendProvider),
                  isEmpty: (v) => v.daysWithData < 2,
                  emptyMessage: l10n.insightsTrendEmpty,
                  accessibilitySummary: ref.watch(moodTrendProvider).maybeWhen(
                        data: (v) => trendSummary(v, l10n),
                        orElse: () => null,
                      ),
                  builder: (v) => MoodTrendChart(series: v),
                ),
                InsightSectionCard<MoodDistribution>(
                  title: l10n.insightsDistribution,
                  value: ref.watch(moodDistributionProvider),
                  isEmpty: (v) => v.total == 0,
                  emptyMessage: l10n.insightsDistributionEmpty,
                  accessibilitySummary:
                      ref.watch(moodDistributionProvider).maybeWhen(
                            data: (v) => distributionSummary(v, l10n),
                            orElse: () => null,
                          ),
                  builder: (v) => MoodDistributionChart(data: v),
                ),
                InsightSectionCard(
                  title: l10n.insightsTopTags,
                  value: ref.watch(topTagsProvider),
                  isEmpty: (v) => v.entries.isEmpty,
                  emptyMessage: l10n.insightsTopTagsEmpty,
                  accessibilitySummary: ref.watch(topTagsProvider).maybeWhen(
                        data: (v) => topTagsSummary(v, l10n),
                        orElse: () => null,
                      ),
                  builder: (v) => TopTagsChart(data: v),
                ),
                InsightSectionCard(
                  title: l10n.insightsSleepVsMood,
                  value: ref.watch(sleepCorrelationProvider),
                  isEmpty: (v) => v.nonEmptyBucketCount == 0,
                  emptyMessage: l10n.insightsSleepEmpty,
                  accessibilitySummary:
                      ref.watch(sleepCorrelationProvider).maybeWhen(
                            data: (v) => sleepSummary(v, l10n),
                            orElse: () => null,
                          ),
                  builder: (v) => SleepCorrelationChart(data: v),
                ),
                InsightSectionCard(
                  title: l10n.insightsEnergyVsMood,
                  value: ref.watch(energyCorrelationProvider),
                  isEmpty: (v) => v.nonEmptyBucketCount == 0,
                  emptyMessage: l10n.insightsEnergyEmpty,
                  accessibilitySummary:
                      ref.watch(energyCorrelationProvider).maybeWhen(
                            data: (v) => energySummary(v, l10n),
                            orElse: () => null,
                          ),
                  builder: (v) => EnergyCorrelationChart(data: v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Add `ValueKey` to `ActiveFilterBanner` (one-line change)**

Open `lib/features/history/presentation/widgets/active_filter_banner.dart`. Locate the outer-most widget returned when the filter is active and add `key: const ValueKey('active_filter_banner')`. If the file currently returns a `Container`/`Material`/`Padding` directly, add the key to that widget. Do not change any other behavior.

- [ ] **Step 5: Run, verify PASS, commit**

```bash
flutter test test/features/statistics/presentation/insights_screen_test.dart
flutter analyze && flutter test
git add lib/features/statistics/presentation/screens/insights_screen.dart \
        lib/features/history/presentation/widgets/active_filter_banner.dart \
        test/features/statistics/presentation/insights_screen_test.dart
git commit -m "feat(statistics): add InsightsScreen composing 5 chart cards"
```

Expected: 179 tests pass.

---

## Task 20: Wire `InsightsScreen` into the router

Swap the existing `_PlaceholderScreen('Insights')` for `InsightsScreen`.

**Files:**
- Modify: `lib/core/navigation/app_router.dart`

- [ ] **Step 1: Edit `app_router.dart`**

At the top, add the import (alphabetical position):

```dart
import '../../features/statistics/presentation/screens/insights_screen.dart';
```

Find the existing Insights branch:

```dart
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.insights,
              builder: (context, _) => const _PlaceholderScreen('Insights'),
            ),
          ]),
```

Replace the `builder` body:

```dart
              builder: (context, _) => const InsightsScreen(),
```

- [ ] **Step 2: Run analyze + tests**

Run: `flutter analyze && flutter test`
Expected: 0 issues; 179 tests still pass.

- [ ] **Step 3: Commit**

```bash
git add lib/core/navigation/app_router.dart
git commit -m "feat(navigation): swap Insights placeholder for real InsightsScreen"
```

---

## Task 21: Extend the integration smoke test

Spec §9.4. After the existing log-→-list flow, switch to Insights and assert at least one section title is visible.

**Files:**
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Add a new `testWidgets` block at the end of `main()`**

```dart
  testWidgets('Insights screen renders against empty repo', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const InsightsScreen(),
      ),
    ));
    await tester.pump();
    expect(find.text('Mood trend'), findsOneWidget);
    expect(find.text('Energy vs. mood'), findsOneWidget);
  });
```

Add the import (alphabetical position):

```dart
import 'package:mood_tracker/features/statistics/presentation/screens/insights_screen.dart';
```

- [ ] **Step 2: Run, verify PASS**

Run: `flutter test test/widget_test.dart`
Expected: 2 tests pass.

- [ ] **Step 3: Full suite + analyze, commit**

```bash
flutter analyze && flutter test
git add test/widget_test.dart
git commit -m "test: extend integration smoke to cover InsightsScreen"
```

Expected: 180 tests pass.

---

## Task 22: Manual smoke + docs refresh + close-out commit

- [ ] **Step 1: Manual smoke (on simulator or device)**

`flutter run` and walk through:

1. Open Insights tab.
2. Tap each range chip (7d / 30d / 90d / All) — selection highlights, charts re-render (or empty cards if no data).
3. Tap filter icon → `FilterSheet` opens.
4. Apply a tag filter from History → switch to Insights → banner visible, charts shrink.
5. Tap "Clear" on banner → all data returns.
6. Switch system reduced-motion ON and re-open Insights → charts settle without animation.
7. Switch language to ES in Settings → Insights labels translate.

If any step fails, file the issue and fix before continuing.

- [ ] **Step 2: Update `README.md`**

If the README has a phase status section, append `Phase 4 — Statistics & charts (complete YYYY-MM-DD)`. Otherwise no change.

- [ ] **Step 3: Update `memory.md`**

Add a new session-log entry at the top per the memory.md maintenance rule:

```markdown
### 2026-05-??  — Phase 4 ship

- Phase 4 (Insights tab) landed in 22 tasks / ~22 commits on `main`. New tests: +~58. Total `flutter test` count: ~180. `flutter analyze` clean.
- Shipped: `features/statistics/` (InsightsRange enum + 5 aggregators + accessibility summaries + 5 derived providers + InsightsScreen + 5 chart widgets + RangeSelector + InsightSectionCard), `fl_chart` dep, 29 EN+ES ARB key pairs, router swap to drop the Insights placeholder.
- Cross-tab filter (Phase 3) now reaches Insights too: `entryFilterProvider` ∩ `selectedRangeProvider` feed one StreamProvider that fans out to 5 per-chart Provider<AsyncValue<T>>.
- Decisions captured: daily-mean trend always; correlation buckets as grouped bars (5 bars each); per-chart empty cards; in-memory range (no persistence); fl_chart's "horizontal" rendering implemented as a left-axis-labeled vertical bar chart.
- Update Phase 4 plan checkboxes when manual smoke is signed off.
- Next up: Phase 5 (Reminders + JSON export/import).
```

- [ ] **Step 4: Update `MEMORY.md` (auto-memory index)**

Add an entry at the project memory `MEMORY.md`:

```markdown
- [Phase 4 complete (YYYY-MM-DD)](project_phase4_complete.md) — Insights tab shipped: 5 charts + range selector + cross-tab filter integration
```

…and create the corresponding `project_phase4_complete.md` next to the existing phase memory files.

- [ ] **Step 5: Commit docs**

```bash
git add README.md memory.md
git commit -m "docs: mark Phase 4 plan complete; update memory.md session log"
```

…and separately commit the auto-memory update (per memory.md tooling conventions; outside repo).

- [ ] **Step 6: Mark this plan complete**

Edit the header of this plan file:

```markdown
> **Status: ✅ Complete (YYYY-MM-DD).** All 22 tasks landed across ~22 commits. `flutter analyze` reports 0 issues; `flutter test` passes ~180/~180.
```

Run a quick final pass:

```bash
flutter analyze
flutter test
```

Expected: 0 issues; ~180 tests pass.

---

## Spec coverage map

Spec section → Task numbers implementing it.

| Spec section | Tasks |
|---|---|
| §2 In-scope: `features/statistics/` module | 3–19 |
| §2 In-scope: `fl_chart` dep | 1 |
| §2 In-scope: 5 chart widgets | 15–18 |
| §2 In-scope: `ActiveFilterBanner` reuse + filter icon | 19 |
| §2 In-scope: per-chart empty cards | 14, 19 |
| §2 In-scope: reduced-motion handling | 15–18 (every chart reads `MediaQuery.disableAnimationsOf`) |
| §2 In-scope: screen-reader summaries | 9, 19 (wired into `InsightSectionCard.accessibilitySummary`) |
| §2 In-scope: 29 ARB key pairs | 2 |
| §4.1 `InsightsRange` + `toDateRange` | 3 |
| §4.2 view-model types | 4–8 |
| §4.3 5 pure aggregators | 4–8 |
| §4.4 Mood scoring | (pre-existing `Mood.score` — no task) |
| §5 Provider graph | 10–12 |
| §6.1 `InsightsScreen` layout | 19 |
| §6.2 Chart widget specs | 15–18 |
| §6.3 Semantics wrap | 14 (`InsightSectionCard`) + 19 (wires `accessibilitySummary`) |
| §6.4 Range selector | 13 |
| §6.5 Filter integration | 19 |
| §7 Navigation | 20 (pre-existing branch + nav destination remain) |
| §8 Localization | 2 |
| §9 Testing | 3–19 each include unit/widget tests; 21 = integration smoke |
| §10 Edge cases / decisions | embedded throughout |
| §11 Risks (`fl_chart` version, label rotation) | Task 1 (version), Task 17 (rotation note) |

## Risks called out

- **Task 17 — TopTagsChart "horizontal" rendering.** `fl_chart`'s `BarChart` has no single-flag horizontal mode. The plan implements bars vertically with the tag label on the left axis. If the user wants a true rotated layout, that's a polish-pass follow-up (use a `RotatedBox` wrapper or a different chart library).
- **Task 16 — Mood face emoji as bottom-axis labels.** Emoji in source code may produce analyzer or font warnings on some platforms. If so, swap for `'1'..'5'` text labels in one place.
- **Task 9 — Accessibility "avg/prom." word.** The locale check inside `_avgWord` is heuristic. If `localeName` doesn't return `'es'` (e.g., `'es_ES'`), the check still matches via `startsWith('es')`. The test covers ES so any regression surfaces immediately.
- **`flutter pub add fl_chart` may resolve to a version with breaking API changes.** If `LineChartBarData.belowBarData.color` or `BarChartRodData.borderRadius` properties change, adjust in-place; the plan's call sites are isolated to one file per chart.

## Final acceptance criteria

1. `flutter analyze` → `No issues found!`
2. `flutter test` → all tests pass, ~180/180.
3. Manual smoke on simulator/device covers all 7 scenarios listed in Task 22 Step 1.
4. Spanish translations render on Insights when locale set to ES.
5. `memory.md` session log updated.
6. This plan's header marked `Status: ✅ Complete (YYYY-MM-DD)`.
