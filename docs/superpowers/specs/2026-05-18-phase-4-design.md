# Mood Tracker — Phase 4 Design Spec

**Date:** 2026-05-18
**Status:** Approved (scope refinement on top of the [2026-05-17 master spec](2026-05-17-mood-tracker-design.md))
**Predecessors:** Phases 1 + 2 + 3 complete on `main`, 122 tests green.

Per-phase scope refinement — not a fresh design. The master spec governs all architectural decisions. This document covers only what Phase 4 adds and modifies.

## 1. Goal

Ship the Insights tab. Five chart sections over a selectable time range, sharing the Phase 3 cross-tab filter, each section independently handling its own loading / error / empty state. Three sections come from the master spec (mood trend, distribution, top tags); two correlation sections (sleep ↔ mood, energy ↔ mood) are added in Phase 4.

## 2. Scope

**In:**

- `features/statistics/` — full feature module: domain types, pure aggregators, accessibility summaries, range controller, derived chart providers, screen + chart widgets.
- New bottom-nav tab `/insights` between Calendar and Settings; `StatefulShellRoute` branches go from 4 → 5.
- `fl_chart` dependency added (line, vertical bar, horizontal bar).
- `core/extensions/mood_score.dart` — shared `Mood → 1..5` ordinal mapping (multiple charts need it).
- Five chart widgets: `MoodTrendChart` (line + area), `MoodDistributionChart` (vertical bars), `TopTagsChart` (horizontal bars), `SleepCorrelationChart` (5 bucketed vertical bars), `EnergyCorrelationChart` (5 vertical bars per energy level).
- `ActiveFilterBanner` (Phase 3) is reused on the Insights screen with the same Clear behavior; a filter icon in the Insights AppBar opens the existing `FilterSheet`.
- Per-chart empty cards rendered inside an `InsightSectionCard` wrapper.
- Reduced-motion handling on all five charts via `MediaQuery.disableAnimationsOf`.
- Screen-reader summaries: one sentence per chart, computed in the domain layer, wrapped via `Semantics` (chart visual is wrapped in `ExcludeSemantics`).
- ~29 new EN/ES ARB key pairs (nav, range, section titles, empty states, tooltips, sleep buckets, accessibility summaries).

**Out of scope (deferred):**

- Statistics caching, isolates, or background recomputation (data set is small and aggregators are pure).
- Persistent range selection across app launches (matches the Phase 3 stance on `entryFilterProvider`).
- Per-entry trend dots (always daily mean — decision below).
- Adaptive bucket sizing on long ranges (always daily; no weekly/monthly downsample).
- Correlation coefficients (Pearson r captions); grouped-bar visuals only.
- Mini mood-face glyphs on the trend Y-axis (numeric labels only; mini-face overlay deferred to a polish pass).
- Streak counters or "entries this range" header metrics.
- Mood-face animations between selection states on the distribution chart.

## 3. File additions and modifications

```
lib/
  core/
    extensions/
      mood_score.dart                              [new]   Mood → 1..5 ordinal + score-to-label key
    navigation/
      app_router.dart                              [modify] add /insights branch (idx 3); Settings branch idx 3 → 4
      app_routes.dart                              [modify] add AppRoutes.insights = '/insights'
  features/
    statistics/                                    [new]   full feature module
      domain/
        insights_range.dart                        # enum + toDateRange(now)
        mood_trend.dart                            # MoodTrendPoint, MoodTrendSeries
        mood_distribution.dart                     # MoodDistribution
        top_tags_view.dart                         # TopTagsView, TopTagEntry
        correlation.dart                           # CorrelationView, CorrelationBucket, SleepBucket
        aggregators.dart                           # 5 pure functions; no Riverpod, no Drift
        accessibility_summaries.dart               # view-model → localized sentence helpers
      providers/
        selected_range_controller.dart             # Notifier<InsightsRange>; default d30, in-memory
        insights_entries_provider.dart             # StreamProvider<List<MoodEntry>>; entryFilter ∩ range
        chart_providers.dart                       # 5 derived Provider<AsyncValue<TView>>
      presentation/
        screens/
          insights_screen.dart                     # CustomScrollView; pinned RangeSelector header
        widgets/
          range_selector.dart                      # [7d][30d][90d][All] chip strip
          insight_section_card.dart                # title + AsyncValue.when(loading→skeleton, error→inline, data→chart|empty)
          mood_trend_chart.dart
          mood_distribution_chart.dart
          top_tags_chart.dart
          sleep_correlation_chart.dart
          energy_correlation_chart.dart
          insights_skeleton.dart                   # Skeletonizer mirror of 5 cards
  l10n/
    app_en.arb                                     [modify] ~29 new keys
    app_es.arb                                     [modify] Spanish mirrors
pubspec.yaml                                       [modify] add fl_chart
test/
  core/extensions/
    mood_score_test.dart                           [new]
  features/statistics/
    domain/
      insights_range_test.dart                     [new]
      aggregators_test.dart                        [new]   table-driven per aggregator
      accessibility_summaries_test.dart            [new]   EN + ES
    providers/
      selected_range_controller_test.dart          [new]
      insights_entries_provider_test.dart          [new]   filter ∩ range merge
      chart_providers_test.dart                    [new]
    presentation/
      insights_screen_test.dart                    [new]   golden path + filter banner
      range_selector_test.dart                     [new]
      insight_section_card_test.dart               [new]   loading/error/empty/data
      mood_trend_chart_test.dart                   [new]   smoke render
      mood_distribution_chart_test.dart            [new]
      top_tags_chart_test.dart                     [new]
      sleep_correlation_chart_test.dart            [new]
      energy_correlation_chart_test.dart           [new]
  widget_test.dart                                 [modify] extend smoke to cover Insights tab
```

## 4. Domain model

### 4.1 Range

```dart
enum InsightsRange { d7, d30, d90, all }

extension InsightsRangeX on InsightsRange {
  ({DateTime? start, DateTime? end}) toDateRange(DateTime now);
  // d7  → (now.startOfDay - 6 days,  null)   inclusive of today, 7 calendar days total
  // d30 → (now.startOfDay - 29 days, null)
  // d90 → (now.startOfDay - 89 days, null)
  // all → (null, null)
  String get labelKey;
}
```

`end` is left `null` so live entries logged after page load still appear (treated as unbounded upper limit by `EntryQuery`).

### 4.2 View models

```dart
class MoodTrendPoint {
  final DateTime day;          // local midnight
  final double? averageMood;   // null = no entries that day → gap
  final int entryCount;
}

class MoodTrendSeries {
  final List<MoodTrendPoint> points;   // dense between [start, end], gap days included as null
  final InsightsRange range;
  int get daysWithData;
  double? get overallAverage;
  double? get minDay;
  double? get maxDay;
  DateTime? get lowestDay;
}

class MoodDistribution {
  final Map<Mood, int> counts;   // every Mood key present
  final int total;
  double percentage(Mood m);
}

class TopTagsView {
  final List<TopTagEntry> entries;   // sorted desc by count, ≤10; ties broken alphabetically by slug
  final int totalTaggedEntries;
}
class TopTagEntry { final Tag tag; final int count; }

class CorrelationView {
  final List<CorrelationBucket> buckets;   // always 5, fixed order
  int get nonEmptyBucketCount;
}
class CorrelationBucket {
  final String bucketLabelKey;   // l10n key
  final int sampleSize;
  final double? averageMood;     // null = empty bucket
}
```

### 4.3 Pure aggregators (`aggregators.dart`)

```dart
MoodTrendSeries computeMoodTrend({
  required List<MoodEntry> entries,
  required InsightsRange range,
  required DateTime now,
});

MoodDistribution computeDistribution(List<MoodEntry> entries);

TopTagsView computeTopTags(List<MoodEntry> entries, {int limit = 10});

CorrelationView computeSleepCorrelation(List<MoodEntry> entries);
// buckets (half-open intervals): [_, 6), [6, 7), [7, 8), [8, 9), [9, _)
// entries where sleepHours == null are excluded.

CorrelationView computeEnergyCorrelation(List<MoodEntry> entries);
// buckets: veryLow, low, medium, high, veryHigh (fixed order)
```

All five aggregators are pure: no Riverpod, no Drift, no clock reads (except `computeMoodTrend`, which receives `now` explicitly for deterministic testing).

### 4.4 Mood scoring (`core/extensions/mood_score.dart`)

```dart
extension MoodScore on Mood {
  int get score;            // awful=1, bad=2, okay=3, good=4, great=5
  String get l10nKey;       // existing keys reused
}
```

Lives in `core/` because trend, distribution, and both correlation aggregators all use it.

## 5. Provider graph

```
entryFilterProvider   (Phase 3, unchanged)
selectedRangeProvider (NEW, default d30, in-memory)
        │
        ▼
insightsEntriesProvider : StreamProvider<List<MoodEntry>>
    - ref.watch(entryFilterProvider) and ref.watch(selectedRangeProvider)
    - intersect filter EntryQuery with range:
        start = maxNullable(filter.start, range.start)
        end   = minNullable(filter.end,   range.end)
    - tags, moodRange, text passed through from filter
    - repository.watchAll(mergedQuery)
        │
        ├──────────────► moodTrendProvider          : Provider<AsyncValue<MoodTrendSeries>>
        ├──────────────► moodDistributionProvider   : Provider<AsyncValue<MoodDistribution>>
        ├──────────────► topTagsProvider            : Provider<AsyncValue<TopTagsView>>
        ├──────────────► sleepCorrelationProvider   : Provider<AsyncValue<CorrelationView>>
        └──────────────► energyCorrelationProvider  : Provider<AsyncValue<CorrelationView>>
```

Each per-chart `Provider` reads `insightsEntriesProvider` and calls the matching pure aggregator on `data`; `loading` and `error` pass through. They are `Provider<AsyncValue<T>>` (not `StreamProvider`) because the stream lives one level up and they are pure transformations of its current value.

`selectedRangeProvider` is in-memory only; no `AppPrefs` key. Fresh launch = `d30`. Same persistence stance as `entryFilterProvider`.

## 6. Presentation

### 6.1 `InsightsScreen` layout

```
AppBar
  title: l10n.insightsTitle
  actions: [
    IconButton(LucideIcons.slidersHorizontal)         → showModalBottomSheet(FilterSheet)
  ]
Body : CustomScrollView
  ├─ SliverPersistentHeader(pinned) → RangeSelector
  ├─ SliverToBoxAdapter             → ActiveFilterBanner (visible iff filter.isActive)
  └─ SliverList
       ├─ InsightSectionCard(title: insightsMoodTrend,      provider: moodTrendProvider)
       ├─ InsightSectionCard(title: insightsDistribution,   provider: moodDistributionProvider)
       ├─ InsightSectionCard(title: insightsTopTags,        provider: topTagsProvider)
       ├─ InsightSectionCard(title: insightsSleepVsMood,    provider: sleepCorrelationProvider)
       └─ InsightSectionCard(title: insightsEnergyVsMood,   provider: energyCorrelationProvider)
```

`InsightSectionCard<T>` is a thin generic wrapper:

- Reads its `Provider<AsyncValue<T>>`.
- `loading` → skeleton body (Skeletonizer).
- `error` → small inline `ErrorView` with retry that calls `ref.invalidate(insightsEntriesProvider)`.
- `data` → calls a `builder(T)` that returns either the chart or the per-chart empty placeholder (decided by the chart's own `isEmpty` rule below).

Per-chart empty rules:

| Chart | Empty when |
|---|---|
| Mood trend | `daysWithData < 2` |
| Distribution | `total == 0` |
| Top tags | `entries.isEmpty` |
| Sleep correlation | `nonEmptyBucketCount == 0` |
| Energy correlation | `nonEmptyBucketCount == 0` |

### 6.2 Chart widget contracts

- **`MoodTrendChart`** — `fl_chart` `LineChart`. Single line in `appColors.primary`, 20%-opacity area fill below. Bottom axis labels at `[start, mid, end]` only. Y axis 1..5 with integer labels. Null `averageMood` points produce line gaps. `LineTouchData` returns `insightsTooltipDay` with date / avg (1-decimal) / count.
- **`MoodDistributionChart`** — vertical `BarChart`, 5 bars (awful → great). Each bar tinted via the existing mood color scale on `context.appColors`. Bars with `count == 0` rendered as a faint ghost outline at the axis baseline so all 5 categories remain visible. `BarTouchData` returns `insightsTooltipMood` with label / count / integer percent.
- **`TopTagsChart`** — horizontal `BarChart` (rotated). Up to 10 bars; labels show tag label, value is count. Tooltip `insightsTooltipTag`.
- **`SleepCorrelationChart` / `EnergyCorrelationChart`** — vertical `BarChart`, exactly 5 bars. Empty buckets render the same way as distribution (faint ghost outline at the axis baseline) so all 5 buckets remain visible. Tooltip `insightsTooltipBucket` with bucket label / 1-decimal avg / sample size.

All five charts: `swapAnimationDuration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.base`.

### 6.3 Semantics

Each chart is wrapped:

```dart
Semantics(
  label: accessibilitySummaryFor(viewModel, l10n),
  child: ExcludeSemantics(child: theChart),
)
```

Summaries are pure functions in `accessibility_summaries.dart`, one per view-model type. Tests cover EN + ES.

### 6.4 Range selector

`SliverPersistentHeader` pinned at the top. A `Row` of four `ChoiceChip`-style `AppChip`s mapping to `InsightsRange` values. Single-select; tapping a chip calls `ref.read(selectedRangeProvider.notifier).set(value)`. Selected chip styled via `context.appColors.primary` background + `onPrimary` text; unselected uses `muted` / `onMuted`. Header height honors safe-area padding.

### 6.5 Filter integration

- AppBar `IconButton(LucideIcons.slidersHorizontal)` → `showModalBottomSheet` with the existing `FilterSheet` from `features/search/`. No changes to `FilterSheet` itself.
- `ActiveFilterBanner` is reused from `features/history/presentation/widgets/active_filter_banner.dart` without modification. The banner's "Clear" calls `ref.read(entryFilterProvider.notifier).clear()` which simultaneously affects History + Calendar + Insights.

## 7. Navigation

- New constant `AppRoutes.insights = '/insights'` (plus a route-name constant) added to `app_routes.dart`.
- `StatefulShellRoute` branches in `app_router.dart` go from `[today, history, calendar, settings]` to `[today, history, calendar, insights, settings]`. Settings branch index 3 → 4.
- Bottom nav destination order matches the branch order: Today, History, Calendar, **Insights** (new), Settings.
- New nav icon: `LucideIcons.barChart3`. Label: `l10n.bottomNavInsights`.
- No tests currently reference branch indices by number; quick `grep` confirmation is part of the implementation plan.

## 8. Localization

29 new EN keys + 29 ES mirrors. All keys carry `@`-metadata; tooltip and accessibility-summary keys carry ICU placeholders.

```
bottomNavInsights, insightsTitle
insightsRange7d, insightsRange30d, insightsRange90d, insightsRangeAll
insightsMoodTrend, insightsDistribution, insightsTopTags, insightsSleepVsMood, insightsEnergyVsMood
insightsTrendEmpty, insightsDistributionEmpty, insightsTopTagsEmpty, insightsSleepEmpty, insightsEnergyEmpty
insightsTooltipDay, insightsTooltipMood, insightsTooltipTag, insightsTooltipBucket
insightsSleepBucketUnder6, insightsSleepBucket6to7, insightsSleepBucket7to8, insightsSleepBucket8to9, insightsSleepBucket9plus
a11yTrendSummary, a11yDistributionSummary, a11yTopTagsSummary, a11ySleepSummary, a11yEnergySummary
```

Tooltip + a11y keys use ICU plurals where entry counts appear. Energy bucket labels reuse existing `energyVeryLow…energyVeryHigh` keys. Mood labels reuse existing `moodAwful…moodGreat` keys.

## 9. Testing

Target: **+50–60 tests**, total suite around **170–180 passing**. `flutter analyze` stays at 0 issues.

### 9.1 Domain (pure)

- `insights_range_test.dart` — `toDateRange(fixedNow)` produces expected `(start, end)` for each enum value. Inclusive-of-today semantics verified at the calendar boundary.
- `aggregators_test.dart` — table-driven, one `group` per aggregator. Coverage:
  - `computeMoodTrend`: empty list; single-entry; two same-day entries (avg); gap days appear as `MoodTrendPoint(averageMood: null)`; range spans correctly for each `InsightsRange`.
  - `computeDistribution`: empty list, all 5 moods present even with `count: 0`, percentage math, single-entry case.
  - `computeTopTags`: empty, single-tag, >10 tags caps at 10, ties broken alphabetically by slug.
  - `computeSleepCorrelation`: null sleep excluded; boundary tests at 5.99 / 6.0 / 6.99 / 7.0 / 7.99 / 8.0 / 8.99 / 9.0 / 9.01; sample size and avg per bucket; all-empty input.
  - `computeEnergyCorrelation`: all 5 buckets always present in fixed order; empty input; uneven distribution.
- `accessibility_summaries_test.dart` — EN + ES output for each summary helper, with ICU plurals tested for `count: 0/1/2`.

### 9.2 Providers

- `selected_range_controller_test.dart` — initial `d30`, setter updates state.
- `insights_entries_provider_test.dart` — fake repo + fake filter + fake range. Asserts:
  - With empty filter: query passes through range start/end exactly.
  - With filter dates: intersection rule (later start wins; earlier end wins; nulls treated as unbounded).
  - Tag / mood / text filter fields pass through unchanged.
- `chart_providers_test.dart` — synthetic entry list, verify each per-chart provider emits the right view model via the corresponding aggregator.

### 9.3 Widgets

- `insights_screen_test.dart` — happy path (5 cards render, in correct order); filter active → `ActiveFilterBanner` shows; tap filter icon → `FilterSheet` opens; tap range chip → `selectedRangeProvider` updates.
- `range_selector_test.dart` — tap each chip, verify state change and styling.
- `insight_section_card_test.dart` — `loading` → skeleton; `error` → inline error; `data` with empty rule met → empty card; `data` with chart-ready data → chart slot.
- One smoke test per chart widget (`mood_trend_chart_test.dart` etc.) — render with a fake view model, assert no exceptions and the `Semantics` label is present.

### 9.4 Integration

`test/widget_test.dart` is extended: after the existing log-→-list-→-edit flow, tap Insights, assert at least one chart card is visible; then go back to History, apply a tag filter, return to Insights, assert the `ActiveFilterBanner` is visible.

### 9.5 Testing patterns reused

- Google Fonts runtime fetching disabled in `setUpAll` (Phase 1 pattern).
- `MediaQueryData(disableAnimations: true)` wrapper for at least one chart smoke test to confirm `swapAnimationDuration: Duration.zero` path.
- Fake repo with `Stream.value(const [])` for screen tests to avoid `pumpAndSettle` hangs on Drift `.watch()` streams (Phase 1 pattern).

## 10. Edge cases and decisions

- **Daily mean trend, always.** No per-entry points, no adaptive bucketing, no downsampling. The aggregator builds a dense day series across `[range.start, today]`; days without entries appear as `averageMood: null` and render as line gaps.
- **Sleep-bucket boundaries are half-open `[lo, hi)`.** 7.0 belongs to `7–8`, never to `6–7`. Documented in `computeSleepCorrelation`.
- **Filter applies on Insights, with banner + Clear** (matches the Phase 3 cross-tab pattern). Filter icon in the AppBar lets the user *edit* the filter without leaving Insights.
- **Range selector is in-memory only.** No `AppPrefs` persistence — same stance as `entryFilterProvider`. Fresh launch starts at `d30`.
- **`InsightsRange.all` ⇒ `(start: null, end: null)`.** The trend X-axis spans `firstEntryDay → today` when range is `all`; if there are no entries, the empty rule kicks in and the trend card shows its empty placeholder.
- **Theme switch live-updates charts.** All paint colors flow from `context.appColors`; the charts re-render on `ThemeMode` change automatically (no manual cache invalidation).
- **No statistics caching, no isolate.** Aggregators are O(N) over the in-range slice. Single-device local SQLite, typically tens to a few thousand entries — comfortably within one frame on a debug build.
- **Per-chart `AsyncValue` providers, not one fat `AsyncNotifier`.** Each card independently handles its loading/error/empty state; rebuilds are scoped; testable piece-by-piece.
- **`core/extensions/mood_score.dart` (not `features/statistics/`).** Trend, distribution, and both correlations all need `Mood → 1..5`. Putting it in `core/` keeps the extension reachable without a cross-feature import.

## 11. Risks and unknowns

- **`fl_chart` version pinning.** Latest stable expected to work with Flutter 3.41.9, but the version pin (e.g. `^0.69.x`) is finalized in the implementation plan after a `flutter pub outdated` check. If the latest line has a breaking change, the plan documents the fallback version.
- **Horizontal `BarChart` label rotation on small screens.** Long tag labels may overflow at 360-dp widths. Fallback: ellipsize at fixed character count; covered by a widget test at the smallest design width.
- **Live-update repaint cost.** A logged entry triggers a stream emit → 5 providers re-aggregate → 5 cards rebuild. Cheap on small data sets, but worth a manual smoke pass with ≥200 seeded entries before declaring Phase 4 done.
- **Filter-icon tap during open `FilterSheet`.** The History pattern handles this; reused as-is. No additional state plumbing.

## 12. Dependencies added

- `fl_chart` — version pinned during implementation. No other dependencies.

## 13. Out of scope (explicitly)

- Trend per-entry points or adaptive/weekly/monthly buckets.
- Pearson r coefficient captions on correlation charts.
- Mood-face mini-glyph Y-axis labels on the trend chart.
- Streak counters, "entries this range" headline metrics.
- Range selector persistence.
- Statistics caching or background recomputation.
- Insights-specific filter UI (the Phase 3 `FilterSheet` is reused as-is).
- Tag-detail drilldown from `TopTagsChart` (tap = tooltip only; no navigation).
