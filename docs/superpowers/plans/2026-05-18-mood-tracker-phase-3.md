# Mood Tracker — Phase 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a real Calendar tab (month grid with mood dots + day-detail sheet + month nav) and a cross-tab filter (text + mood range + date range + tag chips) that shapes both History and Calendar.

**Architecture:** Two new features (`features/search/` and `features/calendar/`) plus repository upgrade so `MoodEntryRepository.watchAll` actually honors `EntryQuery` (currently accepted but ignored). Filter state lives in a shared `entryFilterProvider` consumed by both History and Calendar.

**Tech Stack:** Same as Phase 1+2 — no new dependencies.

**Spec:** `docs/superpowers/specs/2026-05-18-phase-3-design.md`

**Predecessor:** Phase 2 complete on `main`. HEAD before Phase 3 starts: `2138495` (Phase 3 spec commit). Phase 1+2 ship 75 tests, all green.

**Working conventions (carry-over):**

- Every Dart file ends with a newline.
- After every task: `flutter analyze` reports 0 issues; `flutter test` passes.
- Commits NEVER include a `Co-Authored-By` trailer.
- Imports sorted alphabetically: package imports first, then project imports.
- `const` constructors where possible; `final` locals.
- Generated `lib/l10n/app_localizations*.dart` files are gitignored — never commit them.
- Widget tests touching Google Fonts must set `GoogleFonts.config.allowRuntimeFetching = false` in `setUpAll`.
- Widget tests subscribing to Drift `.watch()` need fake repos (or `Stream.value(const [])` stubs).
- Riverpod `AsyncNotifier` setters use `ref.invalidateSelf()` instead of force-unwrapping `state.value!`.

---

## Task 1: Repository — honor `EntryQuery` filters

Phase 1 left `MoodEntryRepositoryImpl.watchAll`/`getAll` accepting `EntryQuery` but ignoring everything except `limit`. Phase 3 wires up the four filter dimensions.

**Files:**
- Modify: `lib/features/mood_entry/data/mood_entry_repository_impl.dart`
- Modify: `test/features/mood_entry/data/mood_entry_repository_impl_test.dart`

- [ ] **Step 1: Append 5 new failing tests at the end of `main()` in `mood_entry_repository_impl_test.dart`**

Keep all 6 existing tests intact. Add inside the existing test scaffolding so `repo`, `db`, and `sample(...)` remain in scope:

```dart
  test('watchAll filters by dateRange', () async {
    final base = DateTime(2026, 5, 17, 12);
    await repo.create(sample(id: 'a').copyWith(occurredAt: base.subtract(const Duration(days: 5))));
    await repo.create(sample(id: 'b').copyWith(occurredAt: base));
    await repo.create(sample(id: 'c').copyWith(occurredAt: base.add(const Duration(days: 5))));

    final (entries, err) = await repo.getAll(
      query: EntryQuery(
        dateRange: DateTimeRange(
          start: base.subtract(const Duration(days: 1)),
          end: base.add(const Duration(days: 1)),
        ),
      ),
    );
    expect(err, isNull);
    expect(entries!.length, 1);
    expect(entries.single.id, 'b');
  });

  test('watchAll filters by moodRange', () async {
    await repo.create(sample(id: 'awful').copyWith(mood: Mood.awful));
    await repo.create(sample(id: 'okay').copyWith(mood: Mood.okay));
    await repo.create(sample(id: 'great').copyWith(mood: Mood.great));

    final (entries, _) = await repo.getAll(
      query: const EntryQuery(moodRange: (min: Mood.bad, max: Mood.good)),
    );
    expect(entries!.map((e) => e.id), unorderedEquals(['okay']));
  });

  test('watchAll filters by tagIds (entries containing any of the tags)', () async {
    final work = Tag(id: 't_work', slug: 'work', label: 'Work');
    final sleep = Tag(id: 't_sleep', slug: 'sleep', label: 'Sleep');
    await repo.create(sample(id: 'with_work', tags: [work]));
    await repo.create(sample(id: 'with_sleep', tags: [sleep]));
    await repo.create(sample(id: 'without_tags'));

    final (entries, _) = await repo.getAll(
      query: const EntryQuery(tagIds: ['t_work']),
    );
    expect(entries!.map((e) => e.id), unorderedEquals(['with_work']));
  });

  test('watchAll filters by text (case-insensitive LIKE)', () async {
    await repo.create(sample(id: 'a').copyWith(note: 'Great hike today'));
    await repo.create(sample(id: 'b').copyWith(note: 'work meeting'));
    await repo.create(sample(id: 'c').copyWith(note: null));

    final (entries, _) = await repo.getAll(query: const EntryQuery(text: 'hike'));
    expect(entries!.map((e) => e.id), unorderedEquals(['a']));
  });

  test('watchAll combines filters with AND', () async {
    final work = Tag(id: 't_work', slug: 'work', label: 'Work');
    await repo.create(sample(id: 'm1', tags: [work]).copyWith(mood: Mood.good));
    await repo.create(sample(id: 'm2', tags: [work]).copyWith(mood: Mood.awful));
    await repo.create(sample(id: 'm3').copyWith(mood: Mood.good));

    final (entries, _) = await repo.getAll(
      query: const EntryQuery(
        tagIds: ['t_work'],
        moodRange: (min: Mood.good, max: Mood.great),
      ),
    );
    expect(entries!.map((e) => e.id), unorderedEquals(['m1']));
  });
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/mood_entry/data/mood_entry_repository_impl_test.dart`
Expected: 5 new tests FAIL (the repository currently ignores `query`). Existing 6 tests still pass.

- [ ] **Step 3: Add a private `_applyQuery` helper and call it from `watchAll`/`getAll`**

In `lib/features/mood_entry/data/mood_entry_repository_impl.dart`, modify the two methods and add the helper. Full text of the changed regions:

```dart
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) {
    final select = _db.select(_db.entries)
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);
    if (query != null) _applyQuery(select, query);
    if (query?.limit != null) select.limit(query!.limit!);
    return select.watch().asyncMap(_hydrate);
  }

  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async {
    try {
      final select = _db.select(_db.entries)
        ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);
      if (query != null) _applyQuery(select, query);
      if (query?.limit != null) select.limit(query!.limit!);
      final rows = await select.get();
      return (await _hydrate(rows), null);
    } catch (e) {
      return (null, DatabaseFailure(debugMessage: e.toString()));
    }
  }

  void _applyQuery(
    SimpleSelectStatement<$EntriesTable, EntryRow> select,
    EntryQuery query,
  ) {
    final r = query.dateRange;
    if (r != null) {
      select.where((t) => t.occurredAt.isBetweenValues(
            r.start.millisecondsSinceEpoch,
            r.end.millisecondsSinceEpoch,
          ));
    }
    final m = query.moodRange;
    if (m != null) {
      select.where((t) => t.mood.isBetweenValues(m.min.index, m.max.index));
    }
    final t = query.tagIds;
    if (t != null && t.isNotEmpty) {
      final sub = _db.selectOnly(_db.entryTags)
        ..addColumns([_db.entryTags.entryId])
        ..where(_db.entryTags.tagId.isIn(t));
      select.where((row) => row.id.isInQuery(sub));
    }
    final text = query.text;
    if (text != null && text.isNotEmpty) {
      select.where((row) => row.note.like('%$text%'));
    }
  }
```

The two `where(...)` calls within the same `SimpleSelectStatement` AND together automatically — Drift composes successive `.where` predicates with logical AND.

- [ ] **Step 4: Re-run, verify PASS**

Run: `flutter test test/features/mood_entry/data/mood_entry_repository_impl_test.dart`
Expected: 11 tests pass (6 existing + 5 new).

- [ ] **Step 5: Full suite + analyze + commit**

- `flutter analyze` → 0 issues
- `flutter test` → 80 tests pass (75 prior + 5 new)

```bash
git add lib/features/mood_entry/data/mood_entry_repository_impl.dart test/features/mood_entry/data/mood_entry_repository_impl_test.dart
git commit -m "feat(data): honor EntryQuery filters (dateRange, moodRange, tagIds, text)"
```

No `Co-Authored-By` trailer.

---

## Task 2: `EntryFilter` value class

**Files:**
- Create: `lib/features/search/domain/entry_filter.dart`
- Create: `test/features/search/domain/entry_filter_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/search/domain/entry_filter.dart';

void main() {
  test('empty filter has no active dimensions', () {
    expect(EntryFilter.empty.isActive, isFalse);
    expect(EntryFilter.empty.activeCount, 0);
  });

  test('text-only filter is active with count 1', () {
    const f = EntryFilter(text: 'hike');
    expect(f.isActive, isTrue);
    expect(f.activeCount, 1);
  });

  test('empty-string text is not active', () {
    const f = EntryFilter(text: '');
    expect(f.isActive, isFalse);
    expect(f.activeCount, 0);
  });

  test('multi-dimension filter increments activeCount', () {
    final f = EntryFilter(
      text: 'note',
      moodRange: (min: Mood.bad, max: Mood.good),
      tagIds: const ['t1'],
    );
    expect(f.activeCount, 3);
  });

  test('toEntryQuery passes fields through (tagIds becomes null when empty)', () {
    const f = EntryFilter(
      text: 'x',
      tagIds: [],
    );
    final q = f.toEntryQuery();
    expect(q.text, 'x');
    expect(q.tagIds, isNull);
  });

  test('toEntryQuery preserves non-empty tagIds', () {
    const f = EntryFilter(tagIds: ['a', 'b']);
    expect(f.toEntryQuery().tagIds, ['a', 'b']);
  });

  test('copyWith updates one dimension at a time', () {
    const a = EntryFilter(text: 'one');
    final b = a.copyWith(text: 'two');
    expect(b.text, 'two');
    final c = b.copyWith(text: null);
    expect(c.text, isNull);
  });

  test('equality is value-based', () {
    const a = EntryFilter(text: 'x', tagIds: ['t1']);
    const b = EntryFilter(text: 'x', tagIds: ['t1']);
    expect(a, b);
  });
}
```

- [ ] **Step 2: FAIL**

Run: `flutter test test/features/search/domain/entry_filter_test.dart`
Expected: FAIL — `EntryFilter` undefined.

- [ ] **Step 3: Implement `lib/features/search/domain/entry_filter.dart`**

```dart
import 'package:flutter/foundation.dart';

import '../../mood_entry/domain/enums/mood.dart';
import '../../mood_entry/domain/repositories/entry_query.dart';

@immutable
class EntryFilter {
  const EntryFilter({
    this.text,
    this.moodRange,
    this.dateRange,
    this.tagIds = const [],
  });

  static const EntryFilter empty = EntryFilter();

  final String? text;
  final ({Mood min, Mood max})? moodRange;
  final DateTimeRange? dateRange;
  final List<String> tagIds;

  bool get isActive =>
      (text != null && text!.isNotEmpty) ||
      moodRange != null ||
      dateRange != null ||
      tagIds.isNotEmpty;

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

  EntryFilter copyWith({
    Object? text = _unset,
    Object? moodRange = _unset,
    Object? dateRange = _unset,
    List<String>? tagIds,
  }) {
    return EntryFilter(
      text: identical(text, _unset) ? this.text : text as String?,
      moodRange: identical(moodRange, _unset)
          ? this.moodRange
          : moodRange as ({Mood min, Mood max})?,
      dateRange:
          identical(dateRange, _unset) ? this.dateRange : dateRange as DateTimeRange?,
      tagIds: tagIds ?? this.tagIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryFilter &&
          text == other.text &&
          moodRange == other.moodRange &&
          dateRange == other.dateRange &&
          listEquals(tagIds, other.tagIds);

  @override
  int get hashCode => Object.hash(text, moodRange, dateRange, Object.hashAll(tagIds));
}

const Object _unset = Object();
```

The `_unset` sentinel lets `copyWith` distinguish between "field omitted" and "field explicitly set to null" — needed so `copyWith(text: null)` clears the text rather than being a no-op.

- [ ] **Step 4: Verify + commit**

- `flutter test test/features/search/domain/entry_filter_test.dart` → 8 tests pass
- `flutter analyze` → 0 issues
- Full suite: 88 tests pass

```bash
git add lib/features/search/domain/entry_filter.dart test/features/search/domain/entry_filter_test.dart
git commit -m "feat(search): add EntryFilter value class with isActive/activeCount/toEntryQuery"
```

---

## Task 3: `EntryFilterController`

**Files:**
- Create: `lib/features/search/providers/entry_filter_controller.dart`
- Create: `test/features/search/providers/entry_filter_controller_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/search/domain/entry_filter.dart';
import 'package:mood_tracker/features/search/providers/entry_filter_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });
  tearDown(() => container.dispose());

  test('initial state is empty filter', () {
    expect(container.read(entryFilterProvider), EntryFilter.empty);
  });

  test('setText normalizes empty string to null', () {
    final n = container.read(entryFilterProvider.notifier);
    n.setText('');
    expect(container.read(entryFilterProvider).text, isNull);
    expect(container.read(entryFilterProvider).isActive, isFalse);
  });

  test('setText sets non-empty value', () {
    final n = container.read(entryFilterProvider.notifier);
    n.setText('hike');
    expect(container.read(entryFilterProvider).text, 'hike');
    expect(container.read(entryFilterProvider).isActive, isTrue);
  });

  test('setMoodRange/setDateRange/setTagIds update the filter', () {
    final n = container.read(entryFilterProvider.notifier);
    n.setMoodRange((min: Mood.bad, max: Mood.good));
    n.setTagIds(['t1', 't2']);
    final f = container.read(entryFilterProvider);
    expect(f.moodRange, (min: Mood.bad, max: Mood.good));
    expect(f.tagIds, ['t1', 't2']);
  });

  test('clear resets to empty', () {
    final n = container.read(entryFilterProvider.notifier);
    n.setText('x');
    n.setTagIds(['t1']);
    n.clear();
    expect(container.read(entryFilterProvider), EntryFilter.empty);
  });

  test('replace overwrites the whole filter', () {
    final n = container.read(entryFilterProvider.notifier);
    n.setText('first');
    n.replace(const EntryFilter(text: 'second'));
    expect(container.read(entryFilterProvider).text, 'second');
  });
}
```

- [ ] **Step 2: FAIL**

Run: `flutter test test/features/search/providers/entry_filter_controller_test.dart` → FAIL.

- [ ] **Step 3: Implement `lib/features/search/providers/entry_filter_controller.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood_entry/domain/enums/mood.dart';
import '../../mood_entry/domain/repositories/entry_query.dart';
import '../domain/entry_filter.dart';

class EntryFilterController extends Notifier<EntryFilter> {
  @override
  EntryFilter build() => EntryFilter.empty;

  void setText(String? text) {
    final normalized = (text == null || text.isEmpty) ? null : text;
    state = state.copyWith(text: normalized);
  }

  void setMoodRange(({Mood min, Mood max})? range) {
    state = state.copyWith(moodRange: range);
  }

  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(dateRange: range);
  }

  void setTagIds(List<String> ids) {
    state = state.copyWith(tagIds: ids);
  }

  void replace(EntryFilter filter) {
    state = filter;
  }

  void clear() {
    state = EntryFilter.empty;
  }
}

final entryFilterProvider =
    NotifierProvider<EntryFilterController, EntryFilter>(EntryFilterController.new);
```

- [ ] **Step 4: Verify + commit**

- `flutter test test/features/search/providers/entry_filter_controller_test.dart` → 6 tests pass
- `flutter analyze` → 0 issues
- Full suite: 94 tests pass

```bash
git add lib/features/search/providers/entry_filter_controller.dart test/features/search/providers/entry_filter_controller_test.dart
git commit -m "feat(search): add EntryFilterController shared by History + Calendar"
```

---

## Task 4: `allTagsProvider`

**Files:**
- Create: `lib/features/search/providers/all_tags_provider.dart`
- Create: `test/features/search/providers/all_tags_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
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
import 'package:mood_tracker/features/search/providers/all_tags_provider.dart';

class _StubRepo implements MoodEntryRepository {
  _StubRepo(this._entries);
  final List<MoodEntry> _entries;
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) =>
      Stream.value(_entries);
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (_entries, null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry e) async => (e, null);
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry e) async => (e, null);
  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      (null, NotFoundFailure(id: id));
}

MoodEntry _entry({required String id, List<Tag> tags = const []}) {
  final now = DateTime(2026, 5, 18);
  return MoodEntry(
    id: id,
    occurredAt: now,
    mood: Mood.good,
    intensity: 5,
    note: null,
    tags: tags,
    sleepHours: null,
    energy: EnergyLevel.medium,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('emits sorted distinct tags across all entries', () async {
    const work = Tag(id: 't_work', slug: 'work', label: 'Work');
    const sleep = Tag(id: 't_sleep', slug: 'sleep', label: 'Sleep');
    const calm = Tag(id: 't_calm', slug: 'calm', label: 'Calm');

    final repo = _StubRepo([
      _entry(id: 'a', tags: [work, calm]),
      _entry(id: 'b', tags: [sleep]),
      _entry(id: 'c', tags: [work]),
    ]);

    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final tags = await container.read(allTagsProvider.future);
    expect(tags.map((t) => t.label), ['Calm', 'Sleep', 'Work']);
  });

  test('emits empty list when no entries have tags', () async {
    final repo = _StubRepo([_entry(id: 'a'), _entry(id: 'b')]);
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final tags = await container.read(allTagsProvider.future);
    expect(tags, isEmpty);
  });
}
```

- [ ] **Step 2: FAIL**

Run: `flutter test test/features/search/providers/all_tags_provider_test.dart` → FAIL.

- [ ] **Step 3: Implement `lib/features/search/providers/all_tags_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood_entry/data/mood_entry_repository_provider.dart';
import '../../mood_entry/domain/entities/tag.dart';

final allTagsProvider = StreamProvider<List<Tag>>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  return repo.watchAll().map((entries) {
    final byId = <String, Tag>{};
    for (final e in entries) {
      for (final t in e.tags) {
        byId[t.id] = t;
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return list;
  });
});
```

- [ ] **Step 4: Verify + commit**

- `flutter test test/features/search/providers/all_tags_provider_test.dart` → 2 tests pass
- `flutter analyze` → 0 issues
- Full suite: 96 tests pass

```bash
git add lib/features/search/providers/all_tags_provider.dart test/features/search/providers/all_tags_provider_test.dart
git commit -m "feat(search): add allTagsProvider derived from entries"
```

---

## Task 5: EN ARB additions (~20 keys)

**Files:**
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Append the new keys to `lib/l10n/app_en.arb`**

Insert these entries before the final closing `}` (preserve all existing keys):

```json
,

  "filterTitle": "Filter",
  "@filterTitle": {},
  "filterTextHint": "Search notes…",
  "@filterTextHint": {},
  "filterMoodRange": "Mood range",
  "@filterMoodRange": {},
  "filterDateRange": "Date range",
  "@filterDateRange": {},
  "filterDateAny": "Any date",
  "@filterDateAny": {},
  "filterTags": "Tags",
  "@filterTags": {},
  "filterApply": "Apply",
  "@filterApply": {},
  "filterClear": "Clear",
  "@filterClear": {},
  "filterActiveCount": "{count, plural, =1{1 filter active} other{{count} filters active}}",
  "@filterActiveCount": {
    "placeholders": {
      "count": {"type": "int"}
    }
  },
  "historyNoMatchesTitle": "No matches",
  "@historyNoMatchesTitle": {},
  "historyNoMatchesMessage": "Nothing matches the current filter.",
  "@historyNoMatchesMessage": {},
  "historySearchTooltip": "Filter entries",
  "@historySearchTooltip": {},
  "calendarPrevMonth": "Previous month",
  "@calendarPrevMonth": {},
  "calendarNextMonth": "Next month",
  "@calendarNextMonth": {},
  "calendarJumpToToday": "Jump to today",
  "@calendarJumpToToday": {},
  "calendarDayEmpty": "No entries on this day.",
  "@calendarDayEmpty": {}
```

The leading `,` at the very top of the chunk separates this new run of keys from the existing last entry (`"@onboardingPrivacyBody": {}`). The chunk has no trailing comma because the file's existing closing `}` immediately follows.

Verify the resulting file is valid JSON with `python3 -c 'import json;json.load(open("lib/l10n/app_en.arb"))'` — must complete with no error.

- [ ] **Step 2: Regenerate l10n**

Run: `flutter gen-l10n`
Expected: writes `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_en.dart` (gitignored).

- [ ] **Step 3: Verify + commit**

- `flutter analyze` → 0 issues
- `flutter test` → 96 tests pass (no consumers of new keys yet)
- `git status --short` shows no staged `app_localizations*.dart` files

```bash
git add lib/l10n/app_en.arb
git commit -m "feat(l10n): add Phase 3 ARB keys (filter sheet, no-matches, calendar nav)"
```

---

## Task 6: Spanish translations for Phase 3 keys

**Files:**
- Modify: `lib/l10n/app_es.arb`

- [ ] **Step 1: Append the new keys to `lib/l10n/app_es.arb`**

Insert these entries before the final closing `}`:

```json
,

  "filterTitle": "Filtro",
  "@filterTitle": {},
  "filterTextHint": "Buscar en las notas…",
  "@filterTextHint": {},
  "filterMoodRange": "Rango de ánimo",
  "@filterMoodRange": {},
  "filterDateRange": "Rango de fechas",
  "@filterDateRange": {},
  "filterDateAny": "Cualquier fecha",
  "@filterDateAny": {},
  "filterTags": "Etiquetas",
  "@filterTags": {},
  "filterApply": "Aplicar",
  "@filterApply": {},
  "filterClear": "Limpiar",
  "@filterClear": {},
  "filterActiveCount": "{count, plural, =1{1 filtro activo} other{{count} filtros activos}}",
  "@filterActiveCount": {
    "placeholders": {
      "count": {"type": "int"}
    }
  },
  "historyNoMatchesTitle": "Sin resultados",
  "@historyNoMatchesTitle": {},
  "historyNoMatchesMessage": "Nada coincide con el filtro actual.",
  "@historyNoMatchesMessage": {},
  "historySearchTooltip": "Filtrar entradas",
  "@historySearchTooltip": {},
  "calendarPrevMonth": "Mes anterior",
  "@calendarPrevMonth": {},
  "calendarNextMonth": "Mes siguiente",
  "@calendarNextMonth": {},
  "calendarJumpToToday": "Ir a hoy",
  "@calendarJumpToToday": {},
  "calendarDayEmpty": "Sin entradas en este día.",
  "@calendarDayEmpty": {}
```

The leading `,` at the top of the chunk separates from the existing last entry; the chunk has no trailing comma because the file's existing `}` immediately follows. Verify with `python3 -c 'import json;json.load(open("lib/l10n/app_es.arb"))'`.

- [ ] **Step 2: Regenerate l10n**

Run `flutter gen-l10n` again. Both `app_localizations_en.dart` and `app_localizations_es.dart` regenerate. They stay gitignored.

- [ ] **Step 3: Verify + commit**

- `flutter analyze` → 0 issues
- `flutter test` → 96 tests pass

```bash
git add lib/l10n/app_es.arb
git commit -m "feat(l10n): add Spanish translations for Phase 3 ARB keys"
```

---

## Task 7: Filter-sheet subcomponents

Three small widgets used inside `FilterSheet`. Implement together since none has logic worth a dedicated test — they're exercised via the sheet test in Task 8.

**Files:**
- Create: `lib/features/search/presentation/widgets/mood_range_slider.dart`
- Create: `lib/features/search/presentation/widgets/date_range_field.dart`
- Create: `lib/features/search/presentation/widgets/tag_filter_chips.dart`

- [ ] **Step 1: Implement `mood_range_slider.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mood_face.dart';
import '../../../mood_entry/domain/enums/mood.dart';

class MoodRangeSlider extends StatelessWidget {
  const MoodRangeSlider({
    super.key,
    required this.range,
    required this.onChanged,
  });

  /// `null` means the full range (filter not active on the mood dimension).
  final ({Mood min, Mood max})? range;
  final ValueChanged<({Mood min, Mood max})?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final effective = range ?? (min: Mood.awful, max: Mood.great);
    final values = RangeValues(
      effective.min.index.toDouble(),
      effective.max.index.toDouble(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MoodFace(mood: effective.min, color: colors.onSurface, size: 28),
              Text(
                _label(effective),
                style: AppTextStyles.label.copyWith(color: colors.onMuted),
              ),
              MoodFace(mood: effective.max, color: colors.onSurface, size: 28),
            ],
          ),
        ),
        RangeSlider(
          min: 0,
          max: Mood.values.length - 1,
          divisions: Mood.values.length - 1,
          values: values,
          onChanged: (v) {
            final next = (
              min: Mood.values[v.start.round()],
              max: Mood.values[v.end.round()],
            );
            final isFullRange =
                next.min == Mood.awful && next.max == Mood.great;
            onChanged(isFullRange ? null : next);
          },
        ),
      ],
    );
  }

  String _label(({Mood min, Mood max}) r) {
    if (r.min == r.max) return r.min.name;
    return '${r.min.name} – ${r.max.name}';
  }
}
```

`max: Mood.values.length - 1` is the index of the last enum value; with `divisions: 4`, the slider snaps to exactly the 5 mood positions.

- [ ] **Step 2: Implement `date_range_field.dart`**

```dart
import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:flutter/material.dart' as material show DateTimeRange;
import 'package:intl/intl.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../mood_entry/domain/repositories/entry_query.dart';

class DateRangeField extends StatelessWidget {
  const DateRangeField({super.key, required this.range, required this.onChanged});

  final DateTimeRange? range;
  final ValueChanged<DateTimeRange?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final fmt = DateFormat.yMMMd(Localizations.localeOf(context).languageCode);
    final label = range == null
        ? l10n.filterDateAny
        : '${fmt.format(range!.start)} – ${fmt.format(range!.end)}';

    return InkWell(
      borderRadius: AppRadius.cardBR,
      onTap: () => _pick(context),
      onLongPress: () => onChanged(null),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: AppRadius.cardBR,
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, color: colors.onMuted, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(label, style: AppTextStyles.body),
            ),
            if (range != null)
              Icon(Icons.clear, color: colors.onMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = range == null
        ? null
        : material.DateTimeRange(start: range!.start, end: range!.end);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
    );
    if (picked != null) {
      onChanged(DateTimeRange(start: picked.start, end: picked.end));
    }
  }
}
```

The `hide ... as material show` dance is necessary because the project's domain `DateTimeRange` (in `lib/features/mood_entry/domain/repositories/entry_query.dart`) shadows Material's `DateTimeRange`. The widget interface uses the project's type; only the `showDateRangePicker` call internally needs Material's type.

- [ ] **Step 3: Implement `tag_filter_chips.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../providers/all_tags_provider.dart';

class TagFilterChips extends ConsumerWidget {
  const TagFilterChips({super.key, required this.selectedIds, required this.onChanged});

  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allTagsProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tags) {
        if (tags.isEmpty) return const SizedBox(height: AppSpacing.xs);
        return Wrap(
          spacing: AppSpacing.xxs,
          runSpacing: AppSpacing.xxs,
          children: [
            for (final tag in tags)
              AppChip(
                label: tag.label,
                selected: selectedIds.contains(tag.id),
                onTap: () {
                  final next = selectedIds.contains(tag.id)
                      ? selectedIds.where((id) => id != tag.id).toList()
                      : [...selectedIds, tag.id];
                  onChanged(next);
                },
              ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 4: Verify + commit**

- `flutter analyze` → 0 issues
- `flutter test` → 96 tests pass

```bash
git add lib/features/search/presentation/widgets/mood_range_slider.dart lib/features/search/presentation/widgets/date_range_field.dart lib/features/search/presentation/widgets/tag_filter_chips.dart
git commit -m "feat(search): add MoodRangeSlider, DateRangeField, TagFilterChips subcomponents"
```

---

## Task 8: `FilterSheet`

**Files:**
- Create: `lib/features/search/presentation/widgets/filter_sheet.dart`
- Create: `test/features/search/presentation/filter_sheet_test.dart`

- [ ] **Step 1: Implement `filter_sheet.dart`**

```dart
import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entry_filter.dart';
import '../../providers/entry_filter_controller.dart';
import 'date_range_field.dart';
import 'mood_range_slider.dart';
import 'tag_filter_chips.dart';

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBR),
      builder: (_) => const FilterSheet(),
    );
  }

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late EntryFilter _draft;
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(entryFilterProvider);
    _textController = TextEditingController(text: _draft.text ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _apply() {
    ref.read(entryFilterProvider.notifier).replace(_draft);
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _draft = EntryFilter.empty;
      _textController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          children: [
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.filterTitle, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.filterTextHint,
              ),
              onChanged: (v) => setState(() => _draft = _draft.copyWith(text: v.isEmpty ? null : v)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.filterMoodRange, style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            MoodRangeSlider(
              range: _draft.moodRange,
              onChanged: (v) => setState(() => _draft = _draft.copyWith(moodRange: v)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.filterDateRange, style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            DateRangeField(
              range: _draft.dateRange,
              onChanged: (v) => setState(() => _draft = _draft.copyWith(dateRange: v)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.filterTags, style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            TagFilterChips(
              selectedIds: _draft.tagIds,
              onChanged: (v) => setState(() => _draft = _draft.copyWith(tagIds: v)),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                TextButton(
                  onPressed: _clear,
                  child: Text(l10n.filterClear),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _apply,
                  child: Text(l10n.filterApply),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:mood_tracker/features/search/presentation/widgets/filter_sheet.dart';
import 'package:mood_tracker/features/search/providers/entry_filter_controller.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

class _EmptyRepo implements MoodEntryRepository {
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) => Stream.value(const []);
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (const <MoodEntry>[], null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry e) async => (e, null);
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry e) async => (e, null);
  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      (null, NotFoundFailure(id: id));
}

Widget _host({required Widget child, required ProviderContainer container}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => FilterSheet.show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Apply writes draft into entryFilterProvider and dismisses', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(child: const SizedBox(), container: container));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Type into the search field
    await tester.enterText(find.byType(TextField), 'hike');
    await tester.pump();

    // Apply
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(container.read(entryFilterProvider).text, 'hike');
    expect(find.byType(FilterSheet), findsNothing); // sheet dismissed
  });

  testWidgets('Clear resets the draft without dismissing', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
    ]);
    container.read(entryFilterProvider.notifier).setText('preset');
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(child: const SizedBox(), container: container));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('preset'), findsOneWidget); // pre-filled

    await tester.tap(find.text('Clear'));
    await tester.pump();

    // Sheet still open; field empty
    expect(find.byType(FilterSheet), findsOneWidget);
    expect(find.text('preset'), findsNothing);
  });
}
```

- [ ] **Step 3: Verify + commit**

- `flutter test test/features/search/presentation/filter_sheet_test.dart` → 2 tests pass
- `flutter analyze` → 0 issues
- Full suite: 98 tests pass

```bash
git add lib/features/search/presentation/widgets/filter_sheet.dart test/features/search/presentation/filter_sheet_test.dart
git commit -m "feat(search): add FilterSheet modal with draft state and apply-on-tap"
```

---

## Task 9: History wiring — filter integration, search icon, banner, no-matches state

**Files:**
- Modify: `lib/features/history/providers/history_controller.dart`
- Create: `lib/features/history/presentation/widgets/active_filter_banner.dart`
- Modify: `lib/features/history/presentation/screens/history_screen.dart`
- Create: `test/features/history/active_filter_banner_test.dart`
- Modify: `test/features/history/history_screen_test.dart`

- [ ] **Step 1: Update `history_controller.dart`**

Replace the file with:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood_entry/data/mood_entry_repository_provider.dart';
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../search/providers/entry_filter_controller.dart';

final historyProvider = StreamProvider<List<MoodEntry>>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  final filter = ref.watch(entryFilterProvider);
  return repo.watchAll(query: filter.toEntryQuery());
});
```

- [ ] **Step 2: Implement `active_filter_banner.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../search/providers/entry_filter_controller.dart';

class ActiveFilterBanner extends ConsumerWidget {
  const ActiveFilterBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(entryFilterProvider);
    if (!filter.isActive) return const SizedBox.shrink();

    final l10n = context.l10n;
    final colors = context.appColors;

    return Container(
      color: colors.muted,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined, size: 18, color: colors.onMuted),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              l10n.filterActiveCount(filter.activeCount),
              style: AppTextStyles.bodySmall.copyWith(color: colors.onMuted),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(entryFilterProvider.notifier).clear(),
            child: Text(l10n.filterClear),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Replace `history_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../mood_entry/domain/entities/mood_entry.dart';
import '../../../mood_entry/domain/entities/tag.dart';
import '../../../mood_entry/domain/enums/energy_level.dart';
import '../../../mood_entry/domain/enums/mood.dart';
import '../../../search/presentation/widgets/filter_sheet.dart';
import '../../../search/providers/entry_filter_controller.dart';
import '../../providers/history_controller.dart';
import '../widgets/active_filter_banner.dart';
import '../widgets/history_row.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(historyProvider);
    final filter = ref.watch(entryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.historySearchTooltip,
            onPressed: () => FilterSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const ActiveFilterBanner(),
          Expanded(
            child: async.when(
              loading: () => Skeletonizer(
                child: ListView.builder(
                  itemCount: 8,
                  itemBuilder: (_, __) => HistoryRow(
                    entry: _skeletonEntry,
                    onTap: () {},
                  ),
                ),
              ),
              error: (e, _) => ErrorView(
                failure: e is Failure ? e : UnknownFailure(cause: e),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  if (filter.isActive) {
                    return EmptyStateView(
                      title: l10n.historyNoMatchesTitle,
                      message: l10n.historyNoMatchesMessage,
                      action: FilledButton(
                        onPressed: () =>
                            ref.read(entryFilterProvider.notifier).clear(),
                        child: Text(l10n.filterClear),
                      ),
                    );
                  }
                  return EmptyStateView(
                    title: l10n.historyTitle,
                    message: l10n.historyEmpty,
                  );
                }
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return HistoryRow(
                      entry: e,
                      onTap: () => context.push(AppRoutes.entryDetailFor(e.id)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final _skeletonEntry = MoodEntry(
  id: 'skel',
  occurredAt: DateTime(2026, 5, 17),
  mood: Mood.okay,
  intensity: 5,
  note: 'placeholder text',
  tags: const <Tag>[],
  sleepHours: null,
  energy: EnergyLevel.medium,
  createdAt: DateTime(2026, 5, 17),
  updatedAt: DateTime(2026, 5, 17),
);
```

- [ ] **Step 4: ActiveFilterBanner widget test**

```dart
// test/features/history/active_filter_banner_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/history/presentation/widgets/active_filter_banner.dart';
import 'package:mood_tracker/features/search/providers/entry_filter_controller.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders nothing when filter is inactive', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ActiveFilterBanner()),
      ),
    ));
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('renders count + Clear button when filter is active', (tester) async {
    final container = ProviderContainer();
    container.read(entryFilterProvider.notifier).setText('hike');
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ActiveFilterBanner()),
      ),
    ));

    expect(find.text('1 filter active'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(container.read(entryFilterProvider).isActive, isFalse);
  });
}
```

- [ ] **Step 5: Extend `history_screen_test.dart` with the no-matches case**

Inside the existing `main()` (after the existing test), add:

```dart
  testWidgets('shows no-matches empty state when filter is active and list is empty',
      (tester) async {
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
    ]);
    container.read(entryFilterProvider.notifier).setText('nonexistent');
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HistoryScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No matches'), findsOneWidget);
    expect(find.text('Nothing matches the current filter.'), findsOneWidget);
    // The "Clear" action button inside the empty state
    expect(find.text('Clear'), findsWidgets);
  });
```

Add the new import at the top of the test file:

```dart
import 'package:mood_tracker/features/search/providers/entry_filter_controller.dart';
```

- [ ] **Step 6: Verify + commit**

- `flutter test test/features/history/` → all history tests pass
- `flutter analyze` → 0 issues
- Full suite: 101 tests pass (98 + 2 banner + 1 history)

```bash
git add lib/features/history/providers/history_controller.dart lib/features/history/presentation/widgets/active_filter_banner.dart lib/features/history/presentation/screens/history_screen.dart test/features/history/active_filter_banner_test.dart test/features/history/history_screen_test.dart
git commit -m "feat(history): wire filter, add search icon + ActiveFilterBanner + no-matches state"
```

---

## Task 10: `YearMonth` + `DayMoodSummary` value objects

**Files:**
- Create: `lib/features/calendar/domain/year_month.dart`
- Create: `lib/features/calendar/domain/day_mood_summary.dart`
- Create: `test/features/calendar/domain/year_month_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/calendar/domain/year_month.dart';

void main() {
  test('fromDate extracts year and month', () {
    expect(YearMonth.fromDate(DateTime(2026, 5, 18)), const YearMonth(2026, 5));
  });

  test('next wraps Dec → Jan + year++', () {
    expect(const YearMonth(2026, 12).next, const YearMonth(2027, 1));
    expect(const YearMonth(2026, 5).next, const YearMonth(2026, 6));
  });

  test('previous wraps Jan → Dec + year--', () {
    expect(const YearMonth(2026, 1).previous, const YearMonth(2025, 12));
    expect(const YearMonth(2026, 5).previous, const YearMonth(2026, 4));
  });

  test('firstDay is day 1 at midnight', () {
    expect(const YearMonth(2026, 2).firstDay, DateTime(2026, 2, 1));
  });

  test('lastDay handles February in a non-leap year (2026)', () {
    expect(const YearMonth(2026, 2).lastDay, DateTime(2026, 2, 28));
  });

  test('lastDay handles February in a leap year (2024)', () {
    expect(const YearMonth(2024, 2).lastDay, DateTime(2024, 2, 29));
  });

  test('lastDay handles December', () {
    expect(const YearMonth(2026, 12).lastDay, DateTime(2026, 12, 31));
  });

  test('equality is by year and month', () {
    expect(const YearMonth(2026, 5), const YearMonth(2026, 5));
    expect(const YearMonth(2026, 5) == const YearMonth(2026, 6), isFalse);
  });
}
```

- [ ] **Step 2: FAIL**

Run: `flutter test test/features/calendar/domain/year_month_test.dart` → FAIL.

- [ ] **Step 3: Implement `year_month.dart`**

```dart
import 'package:flutter/foundation.dart';

@immutable
class YearMonth {
  const YearMonth(this.year, this.month);

  factory YearMonth.fromDate(DateTime d) => YearMonth(d.year, d.month);

  final int year;
  final int month;

  YearMonth get next =>
      month == 12 ? YearMonth(year + 1, 1) : YearMonth(year, month + 1);

  YearMonth get previous =>
      month == 1 ? YearMonth(year - 1, 12) : YearMonth(year, month - 1);

  DateTime get firstDay => DateTime(year, month);
  DateTime get lastDay => DateTime(year, month + 1, 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearMonth && year == other.year && month == other.month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => 'YearMonth($year, $month)';
}
```

`DateTime(year, month + 1, 0)` returns the last day of the previous month — passing month+1 with day 0 normalizes to the last day of `month`. Standard Dart idiom.

- [ ] **Step 4: Implement `day_mood_summary.dart`**

```dart
import 'package:flutter/foundation.dart';

import '../../mood_entry/domain/enums/mood.dart';

@immutable
class DayMoodSummary {
  const DayMoodSummary({
    required this.date,
    required this.averageMood,
    required this.entryCount,
  });

  final DateTime date;
  final Mood averageMood;
  final int entryCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayMoodSummary &&
          date == other.date &&
          averageMood == other.averageMood &&
          entryCount == other.entryCount;

  @override
  int get hashCode => Object.hash(date, averageMood, entryCount);
}
```

- [ ] **Step 5: Verify + commit**

- `flutter test test/features/calendar/domain/year_month_test.dart` → 8 tests pass
- `flutter analyze` → 0 issues
- Full suite: 109 tests pass

```bash
git add lib/features/calendar/domain/year_month.dart lib/features/calendar/domain/day_mood_summary.dart test/features/calendar/domain/year_month_test.dart
git commit -m "feat(calendar): add YearMonth and DayMoodSummary value objects"
```

---

## Task 11: `SelectedMonthController`

**Files:**
- Create: `lib/features/calendar/providers/selected_month_controller.dart`
- Create: `test/features/calendar/providers/selected_month_controller_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/calendar/domain/year_month.dart';
import 'package:mood_tracker/features/calendar/providers/selected_month_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('initial state matches current month', () {
    final now = DateTime.now();
    expect(
      container.read(selectedMonthControllerProvider),
      YearMonth(now.year, now.month),
    );
  });

  test('nextMonth advances state', () {
    final n = container.read(selectedMonthControllerProvider.notifier);
    n.setMonth(const YearMonth(2026, 5));
    n.nextMonth();
    expect(container.read(selectedMonthControllerProvider),
        const YearMonth(2026, 6));
  });

  test('previousMonth moves back across year boundary', () {
    final n = container.read(selectedMonthControllerProvider.notifier);
    n.setMonth(const YearMonth(2026, 1));
    n.previousMonth();
    expect(container.read(selectedMonthControllerProvider),
        const YearMonth(2025, 12));
  });

  test('jumpToToday resets to current month', () {
    final n = container.read(selectedMonthControllerProvider.notifier);
    n.setMonth(const YearMonth(2020, 7));
    n.jumpToToday();
    final now = DateTime.now();
    expect(container.read(selectedMonthControllerProvider),
        YearMonth(now.year, now.month));
  });
}
```

- [ ] **Step 2: FAIL + implement**

```dart
// lib/features/calendar/providers/selected_month_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/year_month.dart';

class SelectedMonthController extends Notifier<YearMonth> {
  @override
  YearMonth build() => YearMonth.fromDate(DateTime.now());

  void setMonth(YearMonth month) => state = month;
  void nextMonth() => state = state.next;
  void previousMonth() => state = state.previous;
  void jumpToToday() => state = YearMonth.fromDate(DateTime.now());
}

final selectedMonthControllerProvider =
    NotifierProvider<SelectedMonthController, YearMonth>(SelectedMonthController.new);
```

- [ ] **Step 3: Verify + commit**

- `flutter test test/features/calendar/providers/selected_month_controller_test.dart` → 4 tests pass
- `flutter analyze` → 0 issues
- Full suite: 113 tests pass

```bash
git add lib/features/calendar/providers/selected_month_controller.dart test/features/calendar/providers/selected_month_controller_test.dart
git commit -m "feat(calendar): add SelectedMonthController for month navigation"
```

---

## Task 12: `calendarEntriesProvider` + `daySummariesProvider`

**Files:**
- Create: `lib/features/calendar/providers/calendar_entries_provider.dart`
- Create: `lib/features/calendar/providers/day_summaries_provider.dart`
- Create: `test/features/calendar/providers/day_summaries_provider_test.dart`

- [ ] **Step 1: Implement `calendar_entries_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood_entry/data/mood_entry_repository_provider.dart';
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/repositories/entry_query.dart';
import '../../search/providers/entry_filter_controller.dart';
import 'selected_month_controller.dart';

/// Entries within the currently-selected month, also respecting the global
/// filter (mood range, tags, text). The selected month's date bounds intersect
/// with the filter's dateRange (if any).
final calendarEntriesProvider = StreamProvider<List<MoodEntry>>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  final month = ref.watch(selectedMonthControllerProvider);
  final filter = ref.watch(entryFilterProvider);

  final monthStart = month.firstDay;
  final monthEnd = DateTime(month.year, month.month, month.lastDay.day, 23, 59, 59, 999);

  DateTimeRange combinedDateRange() {
    final filterRange = filter.dateRange;
    if (filterRange == null) {
      return DateTimeRange(start: monthStart, end: monthEnd);
    }
    final start =
        filterRange.start.isAfter(monthStart) ? filterRange.start : monthStart;
    final end =
        filterRange.end.isBefore(monthEnd) ? filterRange.end : monthEnd;
    return DateTimeRange(start: start, end: end);
  }

  final query = EntryQuery(
    dateRange: combinedDateRange(),
    moodRange: filter.moodRange,
    tagIds: filter.tagIds.isEmpty ? null : filter.tagIds,
    text: filter.text,
  );

  return repo.watchAll(query: query);
});
```

- [ ] **Step 2: Implement `day_summaries_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_helpers.dart';
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/enums/mood.dart';
import '../domain/day_mood_summary.dart';
import 'calendar_entries_provider.dart';

/// Map of startOfDay → DayMoodSummary for the currently-selected month's entries.
/// Days without entries are absent from the map.
final daySummariesProvider = Provider<Map<DateTime, DayMoodSummary>>((ref) {
  final asyncEntries = ref.watch(calendarEntriesProvider);
  final entries = asyncEntries.maybeWhen(
    data: (list) => list,
    orElse: () => const <MoodEntry>[],
  );

  final groups = <DateTime, List<MoodEntry>>{};
  for (final e in entries) {
    final key = startOfDay(e.occurredAt);
    (groups[key] ??= <MoodEntry>[]).add(e);
  }

  return {
    for (final entry in groups.entries)
      entry.key: DayMoodSummary(
        date: entry.key,
        averageMood: _averageMood(entry.value),
        entryCount: entry.value.length,
      ),
  };
});

Mood _averageMood(List<MoodEntry> entries) {
  if (entries.isEmpty) return Mood.okay;
  final total = entries.fold<int>(0, (sum, e) => sum + e.mood.score);
  // Rounding to nearest; ties round up (towards great).
  final avg = (total / entries.length + 0.0001).round();
  final clamped = avg.clamp(1, 5);
  return Mood.values[clamped - 1];
}
```

- [ ] **Step 3: Write the day-summaries test**

```dart
// test/features/calendar/providers/day_summaries_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/features/calendar/providers/day_summaries_provider.dart';
import 'package:mood_tracker/features/calendar/providers/selected_month_controller.dart';
import 'package:mood_tracker/features/calendar/domain/year_month.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';

class _StubRepo implements MoodEntryRepository {
  _StubRepo(this._entries);
  final List<MoodEntry> _entries;
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) =>
      Stream.value(_entries);
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (_entries, null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry e) async => (e, null);
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry e) async => (e, null);
  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      (null, NotFoundFailure(id: id));
}

MoodEntry _entry({required String id, required DateTime at, required Mood mood}) {
  return MoodEntry(
    id: id,
    occurredAt: at,
    mood: mood,
    intensity: 5,
    note: null,
    tags: const <Tag>[],
    sleepHours: null,
    energy: EnergyLevel.medium,
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  test('groups entries by startOfDay with rounded average mood', () async {
    final day1 = DateTime(2026, 5, 17, 9);
    final day1Evening = DateTime(2026, 5, 17, 21);
    final day2 = DateTime(2026, 5, 18, 12);

    final repo = _StubRepo([
      _entry(id: 'a', at: day1, mood: Mood.good),         // score 4
      _entry(id: 'b', at: day1Evening, mood: Mood.okay),  // score 3
      // Day 1 avg = 3.5 → rounds up to 4 (good)
      _entry(id: 'c', at: day2, mood: Mood.bad),          // score 2
    ]);

    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    // Force the selected month to May 2026 (default would be today)
    container
        .read(selectedMonthControllerProvider.notifier)
        .setMonth(const YearMonth(2026, 5));

    // Trigger the stream to emit at least once
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final summaries = container.read(daySummariesProvider);
    final day1Key = DateTime(2026, 5, 17);
    final day2Key = DateTime(2026, 5, 18);

    expect(summaries[day1Key]?.entryCount, 2);
    expect(summaries[day1Key]?.averageMood, Mood.good);
    expect(summaries[day2Key]?.entryCount, 1);
    expect(summaries[day2Key]?.averageMood, Mood.bad);
  });

  test('empty entries → empty map', () async {
    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_StubRepo(const [])),
    ]);
    addTearDown(container.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(daySummariesProvider), isEmpty);
  });
}
```

- [ ] **Step 4: Verify + commit**

- `flutter test test/features/calendar/providers/day_summaries_provider_test.dart` → 2 tests pass
- `flutter analyze` → 0 issues
- Full suite: 115 tests pass

```bash
git add lib/features/calendar/providers/calendar_entries_provider.dart lib/features/calendar/providers/day_summaries_provider.dart test/features/calendar/providers/day_summaries_provider_test.dart
git commit -m "feat(calendar): add calendarEntriesProvider + daySummariesProvider derivations"
```

---

## Task 13: `CalendarDayCell` + `CalendarDaySheet` + `CalendarMonth`

**Files:**
- Create: `lib/features/calendar/presentation/widgets/calendar_day_cell.dart`
- Create: `lib/features/calendar/presentation/widgets/calendar_day_sheet.dart`
- Create: `lib/features/calendar/presentation/widgets/calendar_month.dart`
- Create: `test/features/calendar/presentation/widgets/calendar_day_cell_test.dart`
- Create: `test/features/calendar/presentation/widgets/calendar_month_test.dart`

- [ ] **Step 1: Implement `calendar_day_cell.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mood_dot.dart';
import '../../domain/day_mood_summary.dart';

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.summary,
    required this.isCurrentMonth,
    required this.isToday,
    this.onTap,
  });

  final DateTime date;
  final DayMoodSummary? summary;
  final bool isCurrentMonth;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final opacity = isCurrentMonth ? 1.0 : 0.4;
    final dayNumberStyle = AppTextStyles.caption.copyWith(
      color: colors.onSurface,
      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
    );

    return InkWell(
      onTap: (isCurrentMonth && summary != null) ? onTap : null,
      child: Opacity(
        opacity: opacity,
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 6,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: isToday
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.primary, width: 1.5),
                      )
                    : null,
                child: Text('${date.day}', style: dayNumberStyle),
              ),
            ),
            if (summary != null) ...[
              Center(child: MoodDot(mood: summary!.averageMood, size: 12)),
              if (summary!.entryCount > 1)
                Positioned(
                  top: 4,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '×${summary!.entryCount}',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.onMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `CalendarDayCell` widget test**

```dart
// test/features/calendar/presentation/widgets/calendar_day_cell_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/calendar/domain/day_mood_summary.dart';
import 'package:mood_tracker/features/calendar/presentation/widgets/calendar_day_cell.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders MoodDot when summary is set, no badge for single entry',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: CalendarDayCell(
          date: DateTime(2026, 5, 17),
          summary: DayMoodSummary(
            date: DateTime(2026, 5, 17),
            averageMood: Mood.good,
            entryCount: 1,
          ),
          isCurrentMonth: true,
          isToday: false,
        ),
      ),
    ));
    expect(find.text('17'), findsOneWidget);
    expect(find.text('×1'), findsNothing);
  });

  testWidgets('renders ×N badge when entryCount > 1', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: CalendarDayCell(
          date: DateTime(2026, 5, 17),
          summary: DayMoodSummary(
            date: DateTime(2026, 5, 17),
            averageMood: Mood.good,
            entryCount: 3,
          ),
          isCurrentMonth: true,
          isToday: false,
        ),
      ),
    ));
    expect(find.text('×3'), findsOneWidget);
  });

  testWidgets('is non-tappable when outside current month', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: CalendarDayCell(
          date: DateTime(2026, 4, 30),
          summary: DayMoodSummary(
            date: DateTime(2026, 4, 30),
            averageMood: Mood.good,
            entryCount: 1,
          ),
          isCurrentMonth: false,
          isToday: false,
          onTap: () => taps++,
        ),
      ),
    ));
    await tester.tap(find.byType(CalendarDayCell));
    await tester.pump();
    expect(taps, 0);
  });
}
```

- [ ] **Step 3: Implement `calendar_day_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../history/presentation/widgets/history_row.dart';
import '../../../mood_entry/domain/entities/mood_entry.dart';

class CalendarDaySheet extends StatelessWidget {
  const CalendarDaySheet({
    super.key,
    required this.date,
    required this.entries,
  });

  final DateTime date;
  final List<MoodEntry> entries;

  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    required List<MoodEntry> entries,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBR),
      builder: (_) => CalendarDaySheet(date: date, entries: entries),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final fmt =
        DateFormat.yMMMMd(Localizations.localeOf(context).languageCode);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(fmt.format(date), style: AppTextStyles.title),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  l10n.calendarDayEmpty,
                  style:
                      AppTextStyles.body.copyWith(color: colors.onMuted),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return HistoryRow(
                      entry: e,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.entryDetailFor(e.id));
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement `calendar_month.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_helpers.dart';
import '../../domain/year_month.dart';
import '../../providers/calendar_entries_provider.dart';
import '../../providers/day_summaries_provider.dart';
import 'calendar_day_cell.dart';
import 'calendar_day_sheet.dart';

class CalendarMonth extends ConsumerWidget {
  const CalendarMonth({super.key, required this.month});

  final YearMonth month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(daySummariesProvider);
    final asyncEntries = ref.watch(calendarEntriesProvider);
    final entries = asyncEntries.maybeWhen(data: (e) => e, orElse: () => const []);

    final firstDayOfMonth = month.firstDay;
    final daysInMonth = month.lastDay.day;
    final weekdayOfFirst = firstDayOfMonth.weekday % 7;  // Sun = 0
    final today = startOfDay(DateTime.now());
    final locale = Localizations.localeOf(context).languageCode;
    final weekdayLabels = _weekdayLabels(locale);

    final cells = <Widget>[];
    final totalCells = 42; // 6 rows × 7 cols
    for (var i = 0; i < totalCells; i++) {
      final dayOffset = i - weekdayOfFirst;
      final cellDate = firstDayOfMonth.add(Duration(days: dayOffset));
      final isCurrentMonth = dayOffset >= 0 && dayOffset < daysInMonth;
      final isToday = cellDate.year == today.year &&
          cellDate.month == today.month &&
          cellDate.day == today.day;
      final key = startOfDay(cellDate);
      final summary = isCurrentMonth ? summaries[key] : null;

      cells.add(
        CalendarDayCell(
          date: cellDate,
          summary: summary,
          isCurrentMonth: isCurrentMonth,
          isToday: isToday,
          onTap: () {
            final dayEntries =
                entries.where((e) => startOfDay(e.occurredAt) == key).toList();
            CalendarDaySheet.show(context, date: cellDate, entries: dayEntries);
          },
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: weekdayLabels
              .map((label) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(label, textAlign: TextAlign.center),
                    ),
                  ))
              .toList(),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            childAspectRatio: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
        ),
      ],
    );
  }

  List<String> _weekdayLabels(String localeTag) {
    final fmt = DateFormat.E(localeTag);
    // Build labels starting from a known Sunday.
    final sunday = DateTime(2024, 1, 7); // Jan 7 2024 was a Sunday.
    return List.generate(7, (i) => fmt.format(sunday.add(Duration(days: i))));
  }
}
```

- [ ] **Step 5: `CalendarMonth` widget test**

```dart
// test/features/calendar/presentation/widgets/calendar_month_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/calendar/domain/year_month.dart';
import 'package:mood_tracker/features/calendar/presentation/widgets/calendar_day_cell.dart';
import 'package:mood_tracker/features/calendar/presentation/widgets/calendar_month.dart';
import 'package:mood_tracker/features/calendar/providers/selected_month_controller.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

class _StubRepo implements MoodEntryRepository {
  _StubRepo(this._entries);
  final List<MoodEntry> _entries;
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) => Stream.value(_entries);
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (_entries, null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry e) async => (e, null);
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry e) async => (e, null);
  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      (null, NotFoundFailure(id: id));
}

MoodEntry _entry({required String id, required DateTime at, Mood mood = Mood.good}) =>
    MoodEntry(
      id: id,
      occurredAt: at,
      mood: mood,
      intensity: 5,
      note: null,
      tags: const <Tag>[],
      sleepHours: null,
      energy: EnergyLevel.medium,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders 42 day cells in a month grid', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_StubRepo(const [])),
    ]);
    container
        .read(selectedMonthControllerProvider.notifier)
        .setMonth(const YearMonth(2026, 5));
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: CalendarMonth(month: YearMonth(2026, 5))),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDayCell), findsNWidgets(42));
  });

  testWidgets('shows ×3 badge for a day with 3 entries', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_StubRepo([
        _entry(id: 'a', at: DateTime(2026, 5, 10, 9)),
        _entry(id: 'b', at: DateTime(2026, 5, 10, 14)),
        _entry(id: 'c', at: DateTime(2026, 5, 10, 21)),
      ])),
    ]);
    container
        .read(selectedMonthControllerProvider.notifier)
        .setMonth(const YearMonth(2026, 5));
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: CalendarMonth(month: YearMonth(2026, 5))),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('×3'), findsOneWidget);
  });
}
```

- [ ] **Step 6: Verify + commit**

- `flutter test test/features/calendar/presentation/widgets/` → 5 tests pass
- `flutter analyze` → 0 issues
- Full suite: 120 tests pass

```bash
git add lib/features/calendar/presentation/widgets/calendar_day_cell.dart lib/features/calendar/presentation/widgets/calendar_day_sheet.dart lib/features/calendar/presentation/widgets/calendar_month.dart test/features/calendar/presentation/widgets/calendar_day_cell_test.dart test/features/calendar/presentation/widgets/calendar_month_test.dart
git commit -m "feat(calendar): add CalendarMonth grid, CalendarDayCell, CalendarDaySheet"
```

---

## Task 14: `CalendarScreen`

**Files:**
- Create: `lib/features/calendar/presentation/screens/calendar_screen.dart`
- Create: `test/features/calendar/presentation/calendar_screen_test.dart`

- [ ] **Step 1: Implement `calendar_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../providers/selected_month_controller.dart';
import '../widgets/calendar_month.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = ref.watch(selectedMonthControllerProvider);
    final notifier = ref.read(selectedMonthControllerProvider.notifier);
    final locale = Localizations.localeOf(context).languageCode;
    final title = DateFormat.yMMMM(locale).format(month.firstDay);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.calendarPrevMonth,
            onPressed: notifier.previousMonth,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.calendarNextMonth,
            onPressed: notifier.nextMonth,
          ),
          PopupMenuButton<String>(
            onSelected: (_) => notifier.jumpToToday(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'today',
                child: Text(l10n.calendarJumpToToday),
              ),
            ],
          ),
        ],
      ),
      body: CalendarMonth(month: month),
    );
  }
}
```

- [ ] **Step 2: Widget test**

```dart
// test/features/calendar/presentation/calendar_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/calendar/domain/year_month.dart';
import 'package:mood_tracker/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:mood_tracker/features/calendar/providers/selected_month_controller.dart';
import 'package:mood_tracker/features/calendar/presentation/widgets/calendar_day_sheet.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

class _StubRepo implements MoodEntryRepository {
  _StubRepo(this._entries);
  final List<MoodEntry> _entries;
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) => Stream.value(_entries);
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (_entries, null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry e) async => (e, null);
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry e) async => (e, null);
  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      (null, NotFoundFailure(id: id));
}

MoodEntry _entry({required String id, required DateTime at}) => MoodEntry(
      id: id,
      occurredAt: at,
      mood: Mood.good,
      intensity: 5,
      note: 'sample',
      tags: const <Tag>[],
      sleepHours: null,
      energy: EnergyLevel.medium,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders month title and navigation actions', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_StubRepo(const [])),
    ]);
    container
        .read(selectedMonthControllerProvider.notifier)
        .setMonth(const YearMonth(2026, 5));
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalendarScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('May 2026'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('tapping a day with entries opens CalendarDaySheet', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(_StubRepo([
        _entry(id: 'a', at: DateTime(2026, 5, 10, 14)),
      ])),
    ]);
    container
        .read(selectedMonthControllerProvider.notifier)
        .setMonth(const YearMonth(2026, 5));
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalendarScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDaySheet), findsOneWidget);
  });
}
```

- [ ] **Step 3: Verify + commit**

- `flutter test test/features/calendar/presentation/calendar_screen_test.dart` → 2 tests pass
- `flutter analyze` → 0 issues
- Full suite: 122 tests pass

```bash
git add lib/features/calendar/presentation/screens/calendar_screen.dart test/features/calendar/presentation/calendar_screen_test.dart
git commit -m "feat(calendar): implement CalendarScreen with month title + prev/next/jump-to-today"
```

---

## Task 15: Router — swap Calendar placeholder for `CalendarScreen`

**Files:**
- Modify: `lib/core/navigation/app_router.dart`

- [ ] **Step 1: Add the import and swap the route builder**

Add to the imports (alphabetically):

```dart
import '../../features/calendar/presentation/screens/calendar_screen.dart';
```

Replace the Calendar branch's builder:

```dart
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.calendar,
              builder: (context, _) => const CalendarScreen(),
            ),
          ]),
```

The `_PlaceholderScreen('Calendar')` reference is gone; `_PlaceholderScreen` stays in the file because the `Insights` branch (Phase 4) still uses it.

- [ ] **Step 2: Verify + commit**

- `flutter analyze` → 0 issues
- `flutter test` → 122 tests pass (no test depends on the placeholder)

```bash
git add lib/core/navigation/app_router.dart
git commit -m "feat(navigation): swap Calendar placeholder for real CalendarScreen"
```

---

## Task 16: Final validation pass

- [ ] **Step 1: Analyze must be clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Full test suite must pass**

Run: `flutter test`
Expected: 122 tests pass (75 Phase 1+2 + 47 Phase 3).

If a test fails, fix it before declaring Phase 3 complete. Likely sources of trouble:
- Viewport too small in widget tests rendering the calendar grid — bump to `Size(1080, 1920)`.
- ARB JSON syntax errors — `flutter gen-l10n` will surface them at the line.
- Drift `.watch()` test timing — increase the `Future.delayed` in `day_summaries_provider_test.dart` if flaky.

- [ ] **Step 3: Manual smoke run (optional — skip if no device)**

If a simulator or device is available:

```bash
flutter run -d <device>
```

Verify:
- History tab → tap search icon → FilterSheet opens. Type "hike" → tap Apply → list filters; banner reads "1 filter active"; tap Clear → restored.
- History with active filter that yields zero matches → "No matches" empty state with Clear button.
- Calendar tab → current month renders; chevrons navigate to adjacent months; overflow → "Jump to today" returns to now.
- Calendar day with entries → tap → bottom sheet lists those entries; tap a row → entry detail.
- Apply a mood filter in History → Calendar dots also reflect only those moods (cross-tab filter).

- [ ] **Step 4: No commit needed unless issues surface**

If smoke-test issues surface, file them as follow-ups; do not silently amend.

---

## Phase 3 complete

When Task 16 passes, Phase 3 is done. Next plan to write is Phase 4 (Statistics & charts).
