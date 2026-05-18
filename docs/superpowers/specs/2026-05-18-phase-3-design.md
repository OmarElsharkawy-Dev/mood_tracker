# Mood Tracker — Phase 3 Design Spec

**Date:** 2026-05-18
**Status:** Approved (scope refinement on top of the [2026-05-17 master spec](2026-05-17-mood-tracker-design.md))
**Predecessors:** Phases 1 + 2 complete on `main`, 75 tests green.

Per-phase scope refinement — not a fresh design. The master spec governs all architectural decisions. This document covers only what Phase 3 adds and modifies.

## 1. Goal

Replace the Calendar placeholder with a real month-grid view, and add a cross-tab filter (date range, mood range, tag selection, free-text) that shapes both the History list and the Calendar grid.

## 2. Scope

**In:**

- `features/search/` — shared filter state (`EntryFilterController`), modal `FilterSheet`, subcomponents (`MoodRangeSlider`, `TagFilterChips`, `DateRangeField`).
- `features/calendar/` — month grid (`CalendarMonth`, `CalendarDayCell`), day-detail bottom sheet, month navigation, "Jump to today" action.
- Repository upgrade: `MoodEntryRepositoryImpl.watchAll`/`getAll` actually honor `EntryQuery` (currently the parameter is accepted but ignored).
- History updates: search icon in app bar opens the filter sheet; an "active filter" banner appears above the list when a filter is set; a distinct "no matches" empty state shows when the filtered list is empty.
- A new `allTagsProvider` (derived stream of distinct tags across all entries) used by the filter sheet's tag chips.
- ~20 new EN/ES ARB keys for filter and calendar UI.

**Out of scope (deferred):**

- Per-tag colors in calendar cells.
- Week / year calendar variants.
- Persistent filter state across app launches.
- Full-text search beyond `LIKE '%text%'`.
- Saved filter presets, search history.
- Calendar mini-faces (master spec offered them as an alternative to dots; Phase 1's choice stays — single dot + numeric badge).

## 3. File additions and modifications

```
lib/
  features/
    search/                                            [new]
      domain/
        entry_filter.dart                              # EntryFilter value class
      providers/
        entry_filter_controller.dart                   # Notifier<EntryFilter>; isActive helper
        all_tags_provider.dart                         # StreamProvider<List<Tag>> distinct across entries
      presentation/widgets/
        filter_sheet.dart                              # modal bottom sheet, apply-on-tap draft state
        mood_range_slider.dart                         # RangeSlider 0..4 over Mood
        tag_filter_chips.dart                          # Wrap of AppChips with toggle behavior
        date_range_field.dart                          # tap → showDateRangePicker
    calendar/                                          [new]
      domain/
        year_month.dart                                # immutable {year, month} + helpers
        day_mood_summary.dart                          # {date, averageMood, entryCount}
      providers/
        selected_month_controller.dart                 # Notifier<YearMonth>
        calendar_entries_provider.dart                 # StreamProvider<Map<DateTime, List<MoodEntry>>>
        day_summaries_provider.dart                    # Provider<Map<DateTime, DayMoodSummary>>
      presentation/
        screens/calendar_screen.dart                   # replaces _PlaceholderScreen('Calendar')
        widgets/calendar_month.dart                    # 6×7 grid
        widgets/calendar_day_cell.dart                 # day number + MoodDot + ×N badge
        widgets/calendar_day_sheet.dart                # bottom sheet for one day's entries
  features/history/
    presentation/widgets/
      active_filter_banner.dart                        # [new] thin row + Clear action
    presentation/screens/history_screen.dart           # [modify] search icon + filter wiring + no-matches state
    providers/history_controller.dart                  # [modify] historyProvider reads entryFilterProvider
  features/mood_entry/data/
    mood_entry_repository_impl.dart                    # [modify] _applyQuery helper for SELECT WHERE clauses
  core/
    navigation/app_router.dart                         # [modify] swap _PlaceholderScreen('Calendar') for CalendarScreen
  l10n/
    app_en.arb                                         # [modify] ~20 new keys
    app_es.arb                                         # [modify] Spanish mirrors
test/
  features/search/...                                  # [new] controller + value-class + filter sheet + all-tags tests
  features/calendar/...                                # [new] selected_month + day_summaries + screen + day_cell tests
  features/history/...                                 # [modify] add filter-applied + no-matches tests
  features/mood_entry/data/                            # [modify] add 5 new query-filter tests
```

## 4. Shared filter state

### 4.1 `EntryFilter` value class

```dart
@immutable
class EntryFilter {
  const EntryFilter({
    this.text,
    this.moodRange,
    this.dateRange,
    this.tagIds = const [],
  });

  static const empty = EntryFilter();

  final String? text;
  final ({Mood min, Mood max})? moodRange;
  final DateTimeRange? dateRange;   // domain's DateTimeRange from EntryQuery file
  final List<String> tagIds;

  bool get isActive =>
      (text != null && text!.isNotEmpty) ||
      moodRange != null ||
      dateRange != null ||
      tagIds.isNotEmpty;

  /// Number of distinct filter dimensions currently set; powers the banner label.
  int get activeCount {
    var n = 0;
    if (text != null && text!.isNotEmpty) n++;
    if (moodRange != null) n++;
    if (dateRange != null) n++;
    if (tagIds.isNotEmpty) n++;
    return n;
  }

  EntryQuery toEntryQuery() => EntryQuery(
        text: text,
        moodRange: moodRange,
        dateRange: dateRange,
        tagIds: tagIds.isEmpty ? null : tagIds,
      );

  EntryFilter copyWith({...});  // standard
}
```

The class shadows `EntryQuery` fields exactly; the difference is that `EntryFilter` has an "empty" canonical value and `isActive`/`activeCount` derivations needed by the UI. `toEntryQuery()` maps to the existing repository-layer type so no domain changes are needed.

### 4.2 `EntryFilterController`

```dart
class EntryFilterController extends Notifier<EntryFilter> {
  @override
  EntryFilter build() => EntryFilter.empty;

  void setText(String? text) =>
      state = state.copyWith(text: (text?.isEmpty ?? true) ? null : text);
  void setMoodRange(({Mood min, Mood max})? range) =>
      state = state.copyWith(moodRange: range);
  void setDateRange(DateTimeRange? range) =>
      state = state.copyWith(dateRange: range);
  void setTagIds(List<String> ids) =>
      state = state.copyWith(tagIds: ids);

  void replace(EntryFilter filter) => state = filter;
  void clear() => state = EntryFilter.empty;
}

final entryFilterProvider =
    NotifierProvider<EntryFilterController, EntryFilter>(EntryFilterController.new);
```

Filter state is in-memory only. A fresh app launch starts with `EntryFilter.empty`. (Per-session feels right — the master spec marks persistent filter presets as out of scope.)

### 4.3 `allTagsProvider`

```dart
final allTagsProvider = StreamProvider<List<Tag>>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  return repo.watchAll().map((entries) {
    final byId = <String, Tag>{};
    for (final e in entries) {
      for (final t in e.tags) byId[t.id] = t;
    }
    final list = byId.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return list;
  }).distinct((a, b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  });
});
```

The filter sheet's tag chips iterate this list. Empty-tag projects show an empty Wrap (no extra empty-state — the section header still renders so users learn the feature exists). `distinct` keeps the stream cheap when entries change but the tag set hasn't.

## 5. Repository: honor `EntryQuery`

`MoodEntryRepositoryImpl.watchAll(EntryQuery? query)` and `getAll(EntryQuery? query)` currently accept the parameter but only order by `occurred_at DESC` + apply `limit`. Phase 3 adds a private `_applyQuery` helper that mutates the Drift `SimpleSelectStatement` before `.watch()` / `.get()`.

```dart
void _applyQuery(SimpleSelectStatement<$EntriesTable, EntryRow> select,
                 EntryQuery query) {
  final w = <Expression<bool>>[];
  final r = query.dateRange;
  if (r != null) {
    w.add(_db.entries.occurredAt.isBetweenValues(
        r.start.millisecondsSinceEpoch, r.end.millisecondsSinceEpoch));
  }
  final m = query.moodRange;
  if (m != null) {
    w.add(_db.entries.mood
        .isBetweenValues(m.min.index, m.max.index));
  }
  final t = query.tagIds;
  if (t != null && t.isNotEmpty) {
    final sub = _db.selectOnly(_db.entryTags)
      ..addColumns([_db.entryTags.entryId])
      ..where(_db.entryTags.tagId.isIn(t));
    w.add(_db.entries.id.isInQuery(sub));
  }
  final text = query.text;
  if (text != null && text.isNotEmpty) {
    w.add(_db.entries.note.like('%$text%'));
  }
  if (w.isNotEmpty) {
    select.where((_) => w.reduce((a, b) => a & b));
  }
}
```

Tag filter uses an `IN` subquery against the `entry_tags` join table — returns entries that have **any** of the selected tags (OR within the dimension; AND across dimensions is the existing repo behavior). This matches what users expect from filter chips.

Text search is `LIKE '%text%'` against `note` only — case-insensitive on SQLite by default for ASCII; accented-character matches will Just Work for the EN-only note content we expect. If users start logging in Spanish notes, a future phase can switch to `LOWER(note) LIKE LOWER(?)` or FTS5.

## 6. Calendar feature

### 6.1 `YearMonth` value object

```dart
@immutable
class YearMonth {
  const YearMonth(this.year, this.month);

  factory YearMonth.fromDate(DateTime d) => YearMonth(d.year, d.month);

  final int year;
  final int month;  // 1..12

  YearMonth get next => month == 12 ? YearMonth(year + 1, 1) : YearMonth(year, month + 1);
  YearMonth get previous => month == 1 ? YearMonth(year - 1, 12) : YearMonth(year, month - 1);

  DateTime get firstDay => DateTime(year, month);
  DateTime get lastDay => DateTime(year, month + 1, 0);

  // equality + hashCode by (year, month)
}
```

### 6.2 `DayMoodSummary`

```dart
@immutable
class DayMoodSummary {
  const DayMoodSummary({
    required this.date,
    required this.averageMood,
    required this.entryCount,
  });

  final DateTime date;       // startOfDay
  final Mood averageMood;    // rounded to nearest enum value
  final int entryCount;
}
```

Average is computed as the rounded mean of `Mood.score` across that day's entries, then mapped back to the closest enum value. Tie-break rounds up (toward `great`).

### 6.3 Providers

`selectedMonthControllerProvider` — `Notifier<YearMonth>` initialized to `YearMonth.fromDate(DateTime.now())`. Methods: `nextMonth()`, `previousMonth()`, `jumpToToday()`, `setMonth(YearMonth)`.

`calendarEntriesProvider` — `StreamProvider.autoDispose<List<MoodEntry>>` that:
1. Watches `selectedMonthControllerProvider` to know which month bounds to query.
2. Watches `entryFilterProvider` to read the cross-tab filter.
3. Constructs an `EntryQuery` whose `dateRange` is the intersection of `[selectedMonth.firstDay, selectedMonth.lastDay]` and the filter's `dateRange` (if set). All other filter dimensions (mood, tags, text) pass through directly.
4. Pipes it into `repository.watchAll(query: combined)`.

`daySummariesProvider` — derives `Map<DateTime, DayMoodSummary>` (keyed by `startOfDay`) from `calendarEntriesProvider`. Days with zero entries are simply absent from the map — `CalendarDayCell` checks key presence.

### 6.4 `CalendarScreen`

```dart
class CalendarScreen extends ConsumerWidget { ... }
```

App bar: month/year title (using `DateFormat.yMMMM(locale)`), `IconButton(Icons.chevron_left)` and `IconButton(Icons.chevron_right)` flanking, plus an overflow `PopupMenuButton` with one item: "Jump to today".

Body: `CalendarMonth(month: selectedMonth)`. The widget pulls the summaries from `daySummariesProvider` and renders the 6×7 grid.

### 6.5 `CalendarMonth`

A `Column` with:
- Weekday header row (S M T W T F S, localized via `intl`).
- 6 rows × 7 columns of `CalendarDayCell`s. Cells outside the current month are present but rendered at 0.4 opacity and non-tappable.

Layout via a `GridView.count(crossAxisCount: 7, shrinkWrap: true)` constrained by the screen, with `childAspectRatio: 1`.

### 6.6 `CalendarDayCell`

```dart
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    required this.date,
    required this.summary,        // null = empty day
    required this.isCurrentMonth,
    required this.isToday,
    this.onTap,
  });
}
```

Renders:
- Day number top-left (`AppTextStyles.bodySmall`).
- Today is highlighted with a circular outline around the number.
- If `summary != null`, a centered `MoodDot(mood: summary.averageMood, size: 12)` and (when `summary.entryCount > 1`) a small "×N" badge in the top-right corner using `AppTextStyles.caption` on a `colors.muted` rounded background.
- Cells with non-null `summary` are tappable; empty cells are not.
- Cells outside `isCurrentMonth` render the day number at 0.4 opacity, no dot/badge, not tappable.

Tap → `CalendarDaySheet.show(context, date, entries: ...)`.

### 6.7 `CalendarDaySheet`

Modal bottom sheet (consistent with `LogEntrySheet`/`FilterSheet` patterns), top-aligned with title (`DateFormat.yMMMMd(locale).format(date)`), then a `ListView` of `HistoryRow`s (reusing the existing widget from Phase 1) for that day's entries. Tap a row navigates via `context.push(AppRoutes.entryDetailFor(id))`.

## 7. History changes

### 7.1 Filter wiring

`historyProvider` becomes:

```dart
final historyProvider = StreamProvider<List<MoodEntry>>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  final filter = ref.watch(entryFilterProvider);
  return repo.watchAll(query: filter.toEntryQuery());
});
```

### 7.2 Search icon

`HistoryScreen` AppBar gains a trailing `IconButton(Icons.search, onPressed: () => FilterSheet.show(context))`.

### 7.3 Active filter banner

A new `ActiveFilterBanner` widget renders at the top of the screen (above the list) when `entryFilterProvider.isActive` is true:

```
┌─────────────────────────────────────┐
│  ⓘ 2 filters active        [Clear]  │
└─────────────────────────────────────┘
```

Label uses `l10n.filterActiveCount(activeCount)`. "Clear" calls `entryFilterController.clear()`.

### 7.4 No-matches state

When `historyProvider` emits an empty list AND `entryFilterProvider.isActive` is true, swap the existing `historyEmpty` view for the no-matches variant:

```dart
EmptyStateView(
  title: l10n.historyNoMatchesTitle,
  message: l10n.historyNoMatchesMessage,
  action: FilledButton(
    onPressed: () => ref.read(entryFilterProvider.notifier).clear(),
    child: Text(l10n.filterClear),
  ),
)
```

When the filter is NOT active and the list is empty, the existing "Nothing logged yet" message stays.

## 8. FilterSheet UI

`FilterSheet` is an `isScrollControlled: true` modal bottom sheet with a `DraggableScrollableSheet` (initial size 0.6, max 0.95). Contents:

1. **Drag handle** — small grey horizontal bar (centered, 8pt tall, 36pt wide).
2. **Title** — "Filter" (`AppTextStyles.title`).
3. **Search field** — `TextField` with `Icons.search` prefix and `hintText: l10n.filterTextHint`. Updates draft state on change.
4. **Mood range** — `MoodRangeSlider`, a `RangeSlider` 0..4 with `divisions: 4`. Labels show `MoodFace(mood: minMood, size: 24)` and `MoodFace(mood: maxMood, size: 24)` flanking the slider. Default (no filter) is the full range; setting it to anything less than [awful, great] activates the dimension.
5. **Date range** — `DateRangeField`, a tappable row showing `l10n.filterDateAny` when unset or `DateFormat.yMMMd().format(start) – format(end)` when set. Tap opens `showDateRangePicker(context, firstDate: 2020-01-01, lastDate: now+1y, initialDateRange: current)`. Long-press clears it.
6. **Tag chips** — `TagFilterChips` wraps `AppChip`s, one per tag from `allTagsProvider`. Tap toggles. When `allTagsProvider` is loading or empty, the section header still renders with an "—" placeholder line.
7. **Footer** — a `Row` with `TextButton('Clear')` on the left and `FilledButton('Apply')` on the right, separated by a `Spacer`.

**Draft state:** `FilterSheet` is a `ConsumerStatefulWidget` that holds a local `EntryFilter` in `State`, initialized from `ref.read(entryFilterProvider)` in `initState`. Controls mutate the local copy; "Apply" calls `entryFilterController.replace(_draft)` then `Navigator.pop`. "Clear" sets `_draft = EntryFilter.empty` without dismissing. This prevents the History/Calendar lists from rebuilding while the user is still configuring filters.

## 9. Localization

### 9.1 New EN keys (~20)

Filter sheet: `filterTitle`, `filterTextHint`, `filterMoodRange`, `filterDateRange`, `filterDateAny`, `filterTags`, `filterApply`, `filterClear`, `filterActiveCount` (with `{count}` placeholder + `intl` plural metadata).

History: `historyNoMatchesTitle`, `historyNoMatchesMessage`, `historySearchTooltip`.

Calendar: `calendarPrevMonth`, `calendarNextMonth`, `calendarJumpToToday`, `calendarDayEmpty`.

Day sheet title is the formatted date itself (`DateFormat.yMMMMd(locale)`) — no separate framing ARB key. `calendarDayEmpty` covers the "no entries this day" message that the sheet can display if it's somehow opened from a day with no entries (defensive; shouldn't happen in practice since empty cells aren't tappable).

### 9.2 Spanish

Standard Spanish mirroring every new key. Plural metadata for `filterActiveCount` covers singular/other forms ("1 filtro" / "{count} filtros").

## 10. Router

A single one-line change in `app_router.dart`: replace `_PlaceholderScreen('Calendar')` with `const CalendarScreen()`. No new routes are added — the filter is a modal sheet, not a route; the day-detail is also a modal sheet from within Calendar.

## 11. Testing strategy

- **`EntryFilter` (value class)** — equality, `isActive`, `activeCount`, `toEntryQuery()` mapping, `copyWith` round-trip.
- **`EntryFilterController`** — setters update state; `clear()` resets; `setText('')` is normalized to `null` (so `isActive` works correctly).
- **`MoodEntryRepositoryImpl` query filtering** — 5 new tests covering: dateRange isolates entries in window; moodRange restricts; tagIds filters by `IN` subquery; text matches `LIKE '%x%'`; combined filter intersects correctly.
- **`YearMonth`** — `next`/`previous` cross year boundaries; `firstDay`/`lastDay` correct for all 12 months including February in a leap year.
- **`selectedMonthController`** — `nextMonth`/`previousMonth`/`jumpToToday` mutate as expected; `setMonth` accepts arbitrary `YearMonth`.
- **`DaySummariesProvider`** — given a synthetic entry list, produces the expected map keyed by `startOfDay`. Tests rounding (3 entries with mood 2/3/4 → averageMood okay [3]).
- **`allTagsProvider`** — emits distinct, sorted tags; doesn't double-count.
- **`FilterSheet` widget test** — open sheet, change mood range, tap Apply → sheet dismisses, `entryFilterProvider` reflects the change. Tap Clear → all fields reset, sheet stays open.
- **`HistoryScreen` widget test** — with filter active, list emits empty, no-matches empty state shows with Clear button; tap Clear → filter cleared.
- **`CalendarMonth` widget test** — pump month with entries on 2 days (one with single entry, one with three) → expect 1 dot on first day, 1 dot + "×3" badge on second day.
- **`CalendarDayCell` widget test** — non-current-month cell is at 0.4 opacity and non-tappable.
- **`CalendarScreen` widget test** — tap a day with entries → `CalendarDaySheet` appears with the right number of `HistoryRow`s.

No new goldens.

## 12. Out of scope (reaffirmed)

- Per-tag colors in calendar cells.
- Week / year calendar variants.
- Persistent filter state across launches.
- Full-text search (FTS5 / language-aware).
- Saved filter presets, search history.
- Calendar mini-faces in cells.
- Filter affecting Today screen (Today's "Recent" is always the latest 3 unfiltered entries; intentional).

## 13. Key Decisions Log

| Decision | Choice | Why |
|---|---|---|
| Filter scope | Cross-tab (History + Calendar) | User chose cross-tab over local-to-History during brainstorm; gives the filter a "global scope" feel. |
| Filter UX | Modal bottom sheet | Consistent with Phase 2's pickers; familiar pattern. |
| Filter apply mode | Draft state, apply-on-tap | Avoids list thrashing while user fiddles with controls. |
| Empty-match state | Localized "no matches" + Clear button | Clear recovery action; honest user feedback. |
| Filter persistence | In-memory only | Per-session; presets are out of scope. |
| Day grouping for calendar | One dot per day (with ×N badge if multi-entry) | Matches master spec §7.4; mini-faces alternative deferred. |
| Tag filter semantics | OR within dimension | Standard chip filter behavior; matches user expectation. |
| Text search | `LIKE '%text%'` on `note` | Sufficient for Phase 3; FTS deferred. |
| Calendar week start | Sun (Material default) | Locale-aware via `intl` defaults; revisit if Spanish users prefer Mon. |
| Tag source | Derived from entries via `allTagsProvider` | Avoids a separate "manage tags" screen in Phase 3. |
