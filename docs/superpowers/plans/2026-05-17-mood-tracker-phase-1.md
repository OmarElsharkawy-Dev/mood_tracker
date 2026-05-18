# Mood Tracker — Phase 1 Implementation Plan

> **Status: ✅ Complete (2026-05-18).** All 28 tasks landed across 30 implementation commits + 1 follow-up fix. `flutter analyze` reports 0 issues; `flutter test` passes 54/54 (including 5 `MoodFace` goldens and an integration smoke test). The only unchecked item is Task 28's manual on-device smoke run — deferred to the developer since the automated environment had no simulator.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the foundational layer + first vertical slice of the mood tracker app — users can log a journal-style mood entry from the Today screen and view/edit/delete their history.

**Architecture:** Feature-First Clean Architecture (domain → data → presentation). Riverpod for state, Drift for local SQL, GoRouter for navigation, GetIt for infra DI. Result tuples `(T?, Failure?)` for error handling. Mood faces drawn programmatically via `CustomPainter` (no SVG assets).

**Tech Stack:** Flutter 3.x, Dart ^3.11.5, `drift`, `flutter_riverpod`, `go_router`, `get_it`, `shared_preferences`, `google_fonts` (Lora + Raleway), `lucide_icons_flutter`, `skeletonizer`, `flutter_screenutil`, `uuid`, `intl`. Tests: `flutter_test`, `mockito`.

**Spec:** `docs/superpowers/specs/2026-05-17-mood-tracker-design.md`

**Phase scope:** core/ infrastructure + `features/mood_entry/` + `features/history/` + `features/today/` + app wiring. Phases 2-5 (settings, onboarding, Spanish, calendar, search, statistics, reminders, backup) are out of scope for this plan.

**Working conventions:**

- Every Dart file ends with a newline.
- After every task: `flutter analyze` must report 0 issues; `flutter test` must pass.
- Commits never include a `Co-Authored-By` trailer (per project preference).
- Imports sorted alphabetically: package imports first, then project imports.
- `const` constructors used wherever possible; `final` for local vars.

---

## Task 1: Add dependencies + l10n config + scaffold cleanup

**Files:**
- Modify: `pubspec.yaml`
- Create: `l10n.yaml`
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`

- [x] **Step 1: Replace `pubspec.yaml` dependencies block**

Replace the `dependencies:` and `dev_dependencies:` blocks in `pubspec.yaml` with:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # State management
  flutter_riverpod: ^2.5.1

  # Persistence
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.4
  path: ^1.9.0

  # Routing
  go_router: ^14.2.7

  # Infra DI
  get_it: ^7.7.0

  # Prefs
  shared_preferences: ^2.3.2

  # UI
  google_fonts: ^6.2.1
  lucide_icons_flutter: ^3.0.5
  skeletonizer: ^1.4.2
  flutter_screenutil: ^5.9.3

  # Utils
  uuid: ^4.5.0
  intl: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

  # Codegen
  drift_dev: ^2.18.0
  build_runner: ^2.4.13

  # Test helpers
  mockito: ^5.4.4
  riverpod_lint: ^2.3.13
  custom_lint: ^0.6.4
```

Add to the `flutter:` section:

```yaml
flutter:
  uses-material-design: true
  generate: true
```

- [x] **Step 2: Create `l10n.yaml` at repo root**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
```

- [x] **Step 3: Replace `lib/main.dart` with a minimal placeholder**

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const _BootstrapPlaceholder());
}

class _BootstrapPlaceholder extends StatelessWidget {
  const _BootstrapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: SizedBox.shrink()),
    );
  }
}
```

This is a stub; Task 32 replaces it with the real bootstrap.

- [x] **Step 4: Replace `test/widget_test.dart` with a passing placeholder**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder', () {
    expect(1 + 1, 2);
  });
}
```

The starter counter-app test will fail after dependency changes; replacing it keeps the suite green until Task 33 adds a real integration smoke test.

- [x] **Step 5: Run `flutter pub get`**

Run: `flutter pub get`
Expected: no errors; lockfile updated.

- [x] **Step 6: Run `flutter analyze` and `flutter test`**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests pass (`1: All tests passed!`).

- [x] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock l10n.yaml lib/main.dart test/widget_test.dart
git commit -m "chore: add Phase 1 dependencies and l10n config"
```

---

## Task 2: Folder scaffolding + barrel `.gitkeep` files

**Files:**
- Create: `lib/app/.gitkeep`
- Create: `lib/core/db/.gitkeep`
- Create: `lib/core/di/.gitkeep`
- Create: `lib/core/error/.gitkeep`
- Create: `lib/core/l10n/.gitkeep`
- Create: `lib/core/navigation/.gitkeep`
- Create: `lib/core/prefs/.gitkeep`
- Create: `lib/core/theme/.gitkeep`
- Create: `lib/core/utils/.gitkeep`
- Create: `lib/core/widgets/.gitkeep`
- Create: `lib/features/mood_entry/{domain,data,presentation,providers}/.gitkeep`
- Create: `lib/features/history/{presentation,providers}/.gitkeep`
- Create: `lib/features/today/{presentation,providers}/.gitkeep`
- Create: `lib/l10n/.gitkeep`

- [x] **Step 1: Create the directory tree**

Run from repo root:

```bash
mkdir -p lib/app \
  lib/core/{db,di,error,l10n,navigation,prefs,theme,utils,widgets} \
  lib/features/mood_entry/{domain/{entities,enums,value_objects,repositories},data/{dao,dto,mappers},presentation/{screens,widgets},providers} \
  lib/features/history/{presentation/{screens,widgets},providers} \
  lib/features/today/{presentation/{screens,widgets},providers} \
  lib/l10n \
  test/core test/features
```

- [x] **Step 2: Add `.gitkeep` files in every empty directory**

```bash
find lib test -type d -empty -exec touch {}/.gitkeep \;
```

- [x] **Step 3: Commit**

```bash
git add lib test
git commit -m "chore: scaffold core/ and features/ directory tree"
```

---

## Task 3: `core/error/failure.dart` and `core/error/result.dart`

**Files:**
- Create: `lib/core/error/failure.dart`
- Create: `lib/core/error/result.dart`
- Create: `test/core/error/failure_test.dart`

- [x] **Step 1: Write `test/core/error/failure_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';

void main() {
  group('Failure', () {
    test('DatabaseFailure carries a debug message', () {
      const failure = DatabaseFailure(debugMessage: 'db locked');
      expect(failure.debugMessage, 'db locked');
    });

    test('NotFoundFailure exposes the id that was missing', () {
      const failure = NotFoundFailure(id: 'abc-123');
      expect(failure.id, 'abc-123');
    });

    test('ValidationFailure carries field-level errors', () {
      const failure = ValidationFailure(fieldErrors: {'intensity': 'must be 1..10'});
      expect(failure.fieldErrors['intensity'], 'must be 1..10');
    });

    test('two equivalent ValidationFailures are equal', () {
      const a = ValidationFailure(fieldErrors: {'x': 'y'});
      const b = ValidationFailure(fieldErrors: {'x': 'y'});
      expect(a, b);
    });
  });
}
```

- [x] **Step 2: Run the test and verify it fails**

Run: `flutter test test/core/error/failure_test.dart`
Expected: FAIL — `Failure` is undefined.

- [x] **Step 3: Implement `lib/core/error/failure.dart`**

```dart
import 'package:flutter/foundation.dart';

@immutable
sealed class Failure {
  const Failure({this.debugMessage});

  final String? debugMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          debugMessage == other.debugMessage;

  @override
  int get hashCode => Object.hash(runtimeType, debugMessage);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({super.debugMessage});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({required this.id, super.debugMessage});

  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotFoundFailure && super == other && id == other.id;

  @override
  int get hashCode => Object.hash(super.hashCode, id);
}

class ValidationFailure extends Failure {
  const ValidationFailure({required this.fieldErrors, super.debugMessage});

  final Map<String, String> fieldErrors;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationFailure &&
          super == other &&
          mapEquals(fieldErrors, other.fieldErrors);

  @override
  int get hashCode => Object.hash(super.hashCode, fieldErrors);
}

class IOFailure extends Failure {
  const IOFailure({super.debugMessage});
}

class UnknownFailure extends Failure {
  const UnknownFailure({required this.cause, super.debugMessage});

  final Object cause;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnknownFailure && super == other && cause == other.cause;

  @override
  int get hashCode => Object.hash(super.hashCode, cause);
}
```

- [x] **Step 4: Implement `lib/core/error/result.dart`**

```dart
/// Marker for "no value" returns, paired with `(Unit?, Failure?)`.
class Unit {
  const Unit._();
  static const Unit value = Unit._();
}

/// Convenience builders so call-sites stay readable.
typedef Result<T> = (T?, Object?);
```

(The `Object?` second-slot is intentionally permissive at the typedef level so call-sites can return `(T?, Failure?)`. The discipline that the failure slot is always `Failure?` lives in repository contracts, not in the typedef.)

- [x] **Step 5: Re-run the test, verify it passes**

Run: `flutter test test/core/error/failure_test.dart`
Expected: PASS.

- [x] **Step 6: `flutter analyze`**

Expected: 0 issues.

- [x] **Step 7: Commit**

```bash
git add lib/core/error test/core/error
git commit -m "feat(core): add Failure sealed class and Result tuple helpers"
```

---

## Task 4: `core/utils/uuid.dart` and `core/utils/date_helpers.dart`

**Files:**
- Create: `lib/core/utils/uuid.dart`
- Create: `lib/core/utils/date_helpers.dart`
- Create: `test/core/utils/date_helpers_test.dart`

- [x] **Step 1: Write `test/core/utils/date_helpers_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/utils/date_helpers.dart';

void main() {
  group('DateHelpers', () {
    test('startOfDay zeros hours/minutes/seconds/ms', () {
      final d = DateTime(2026, 5, 17, 14, 23, 45, 678);
      expect(startOfDay(d), DateTime(2026, 5, 17));
    });

    test('endOfDay is just before midnight', () {
      final d = DateTime(2026, 5, 17, 1);
      expect(endOfDay(d), DateTime(2026, 5, 17, 23, 59, 59, 999));
    });

    test('isSameDay treats different times on same date as same', () {
      expect(
        isSameDay(DateTime(2026, 5, 17, 1), DateTime(2026, 5, 17, 23)),
        isTrue,
      );
      expect(
        isSameDay(DateTime(2026, 5, 17), DateTime(2026, 5, 18)),
        isFalse,
      );
    });
  });
}
```

- [x] **Step 2: Run, verify FAIL**

Run: `flutter test test/core/utils/date_helpers_test.dart`
Expected: FAIL — symbols undefined.

- [x] **Step 3: Implement `lib/core/utils/date_helpers.dart`**

```dart
DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime endOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
```

- [x] **Step 4: Implement `lib/core/utils/uuid.dart`**

```dart
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String generateId() => _uuid.v4();
```

- [x] **Step 5: Re-run, verify PASS + analyze**

Run: `flutter test test/core/utils/date_helpers_test.dart` → PASS
Run: `flutter analyze` → 0 issues

- [x] **Step 6: Commit**

```bash
git add lib/core/utils test/core/utils
git commit -m "feat(core): add date helpers and uuid generator"
```

---

## Task 5: `core/prefs/app_prefs.dart`

**Files:**
- Create: `lib/core/prefs/app_prefs.dart`
- Create: `test/core/prefs/app_prefs_test.dart`

- [x] **Step 1: Write `test/core/prefs/app_prefs_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences sp;
  late AppPrefs prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sp = await SharedPreferences.getInstance();
    prefs = AppPrefs(sp);
  });

  test('themeMode defaults to system', () {
    expect(prefs.themeMode, AppThemeMode.system);
  });

  test('themeMode round-trips', () async {
    await prefs.setThemeMode(AppThemeMode.dark);
    expect(prefs.themeMode, AppThemeMode.dark);
  });

  test('locale defaults to null (system)', () {
    expect(prefs.localeTag, isNull);
  });

  test('localeTag round-trips', () async {
    await prefs.setLocaleTag('en');
    expect(prefs.localeTag, 'en');
  });
}
```

- [x] **Step 2: Run, verify FAIL**

Run: `flutter test test/core/prefs/app_prefs_test.dart` → FAIL

- [x] **Step 3: Implement `lib/core/prefs/app_prefs.dart`**

```dart
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class AppPrefs {
  AppPrefs(this._sp);

  final SharedPreferences _sp;

  static const _kThemeMode = 'app.themeMode';
  static const _kLocaleTag = 'app.localeTag';

  AppThemeMode get themeMode {
    final raw = _sp.getString(_kThemeMode);
    return switch (raw) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _sp.setString(_kThemeMode, mode.name);

  String? get localeTag => _sp.getString(_kLocaleTag);

  Future<void> setLocaleTag(String? tag) async {
    if (tag == null) {
      await _sp.remove(_kLocaleTag);
    } else {
      await _sp.setString(_kLocaleTag, tag);
    }
  }
}
```

- [x] **Step 4: Re-run + analyze + commit**

```bash
flutter test test/core/prefs/app_prefs_test.dart
flutter analyze
git add lib/core/prefs test/core/prefs
git commit -m "feat(core): add SharedPreferences wrapper"
```

---

## Task 6: Drift tables + `AppDatabase`

**Files:**
- Create: `lib/core/db/tables.dart`
- Create: `lib/core/db/app_database.dart`
- Create: `test/core/db/app_database_test.dart`

- [x] **Step 1: Implement `lib/core/db/tables.dart`**

The `@DataClassName` annotations override Drift's default row-class names so we get `EntryRow`/`TagRow`/`EntryTagRow` rather than the colliding `Entry`/`Tag` defaults.

```dart
import 'package:drift/drift.dart';

@DataClassName('EntryRow')
class Entries extends Table {
  TextColumn get id => text()();
  IntColumn get occurredAt => integer()();
  IntColumn get mood => integer()();
  IntColumn get intensity => integer()();
  TextColumn get note => text().nullable()();
  RealColumn get sleepHours => real().nullable()();
  IntColumn get energy => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TagRow')
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get slug => text().unique()();
  TextColumn get label => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EntryTagRow')
class EntryTags extends Table {
  TextColumn get entryId =>
      text().references(Entries, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {entryId, tagId};
}
```

- [x] **Step 2: Implement `lib/core/db/app_database.dart`**

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart'; // ignore: unused_import

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Entries, Tags, EntryTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// In-memory constructor for tests.
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE INDEX idx_entries_occurred_at ON entries(occurred_at)');
          await customStatement(
              'CREATE INDEX idx_entry_tags_tag_id ON entry_tags(tag_id)');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'mood_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

- [x] **Step 3: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: writes `lib/core/db/app_database.g.dart`. Success line: `Succeeded after ...`.

- [x] **Step 4: Write `test/core/db/app_database_test.dart`**

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('opens at schema version 1', () async {
    expect(db.schemaVersion, 1);
  });

  test('migration creates indexes', () async {
    // Touching customStatement runs the onCreate side effects via Drift.
    final entries = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type='index' "
      "AND name IN ('idx_entries_occurred_at','idx_entry_tags_tag_id')",
    ).get();
    expect(entries.length, 2);
  });
}
```

- [x] **Step 5: Run + analyze + commit**

Run: `flutter test test/core/db/app_database_test.dart` → PASS
Run: `flutter analyze` → 0 issues

```bash
git add lib/core/db test/core/db
git commit -m "feat(core): add Drift schema (entries, tags, entry_tags) and AppDatabase"
```

---

## Task 7: Domain enums and `Tag` entity

**Files:**
- Create: `lib/features/mood_entry/domain/enums/mood.dart`
- Create: `lib/features/mood_entry/domain/enums/energy_level.dart`
- Create: `lib/features/mood_entry/domain/entities/tag.dart`
- Create: `test/features/mood_entry/domain/tag_test.dart`

- [x] **Step 1: Write `test/features/mood_entry/domain/tag_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';

void main() {
  group('Tag', () {
    test('slugify lowercases and trims and replaces spaces', () {
      expect(Tag.slugify('  Bad Sleep '), 'bad-sleep');
    });

    test('slugify drops non-alphanumeric except dash', () {
      expect(Tag.slugify('café!'), 'caf');
    });

    test('equality is by id', () {
      const a = Tag(id: '1', slug: 'work', label: 'Work');
      const b = Tag(id: '1', slug: 'WORK', label: 'work');
      expect(a, b);
    });
  });
}
```

- [x] **Step 2: FAIL**

Run: `flutter test test/features/mood_entry/domain/tag_test.dart` → FAIL

- [x] **Step 3: Implement enums**

`lib/features/mood_entry/domain/enums/mood.dart`:

```dart
enum Mood {
  awful,
  bad,
  okay,
  good,
  great;

  /// 1..5 scoring used by aggregations and chart math.
  int get score => index + 1;
}
```

`lib/features/mood_entry/domain/enums/energy_level.dart`:

```dart
enum EnergyLevel { veryLow, low, medium, high, veryHigh }
```

- [x] **Step 4: Implement `lib/features/mood_entry/domain/entities/tag.dart`**

```dart
import 'package:flutter/foundation.dart';

@immutable
class Tag {
  const Tag({required this.id, required this.slug, required this.label});

  final String id;
  final String slug;
  final String label;

  static final _slugAllowed = RegExp(r'[^a-z0-9-]');

  static String slugify(String raw) {
    final trimmed = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    return trimmed.replaceAll(_slugAllowed, '');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Tag && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

- [x] **Step 5: PASS + analyze + commit**

```bash
flutter test test/features/mood_entry/domain/tag_test.dart
flutter analyze
git add lib/features/mood_entry/domain test/features/mood_entry/domain
git commit -m "feat(domain): add Mood/EnergyLevel enums and Tag entity"
```

---

## Task 8: `MoodEntry` entity with validators

**Files:**
- Create: `lib/features/mood_entry/domain/entities/mood_entry.dart`
- Create: `test/features/mood_entry/domain/mood_entry_test.dart`

- [x] **Step 1: Write the test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

void main() {
  MoodEntry validEntry({int intensity = 5, double? sleepHours = 7}) {
    final now = DateTime(2026, 5, 17, 14);
    return MoodEntry(
      id: 'abc',
      occurredAt: now,
      mood: Mood.good,
      intensity: intensity,
      note: 'hi',
      tags: const [],
      sleepHours: sleepHours,
      energy: EnergyLevel.medium,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('MoodEntry.validate', () {
    test('returns no errors for a valid entry', () {
      expect(validEntry().validate(), isEmpty);
    });

    test('flags intensity below 1', () {
      expect(validEntry(intensity: 0).validate(), contains('intensity'));
    });

    test('flags intensity above 10', () {
      expect(validEntry(intensity: 11).validate(), contains('intensity'));
    });

    test('flags negative sleepHours', () {
      expect(validEntry(sleepHours: -1).validate(), contains('sleepHours'));
    });

    test('flags sleepHours over 24', () {
      expect(validEntry(sleepHours: 25).validate(), contains('sleepHours'));
    });

    test('allows null sleepHours', () {
      expect(validEntry(sleepHours: null).validate(), isEmpty);
    });
  });

  test('copyWith mutates only the supplied fields', () {
    final original = validEntry();
    final mutated = original.copyWith(mood: Mood.awful);
    expect(mutated.mood, Mood.awful);
    expect(mutated.id, original.id);
  });
}
```

- [x] **Step 2: FAIL**

Run: `flutter test test/features/mood_entry/domain/mood_entry_test.dart` → FAIL

- [x] **Step 3: Implement `lib/features/mood_entry/domain/entities/mood_entry.dart`**

```dart
import 'package:flutter/foundation.dart';

import '../enums/energy_level.dart';
import '../enums/mood.dart';
import 'tag.dart';

@immutable
class MoodEntry {
  const MoodEntry({
    required this.id,
    required this.occurredAt,
    required this.mood,
    required this.intensity,
    required this.note,
    required this.tags,
    required this.sleepHours,
    required this.energy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime occurredAt;
  final Mood mood;
  final int intensity;
  final String? note;
  final List<Tag> tags;
  final double? sleepHours;
  final EnergyLevel energy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a map of field-name → error key. Empty map ⇒ valid.
  Map<String, String> validate() {
    final errors = <String, String>{};
    if (intensity < 1 || intensity > 10) {
      errors['intensity'] = 'out_of_range';
    }
    if (sleepHours != null && (sleepHours! < 0 || sleepHours! > 24)) {
      errors['sleepHours'] = 'out_of_range';
    }
    return errors;
  }

  MoodEntry copyWith({
    String? id,
    DateTime? occurredAt,
    Mood? mood,
    int? intensity,
    String? note,
    List<Tag>? tags,
    double? sleepHours,
    bool clearSleepHours = false,
    EnergyLevel? energy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      occurredAt: occurredAt ?? this.occurredAt,
      mood: mood ?? this.mood,
      intensity: intensity ?? this.intensity,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      sleepHours: clearSleepHours ? null : (sleepHours ?? this.sleepHours),
      energy: energy ?? this.energy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MoodEntry && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

- [x] **Step 4: PASS + analyze + commit**

```bash
flutter test test/features/mood_entry/domain/mood_entry_test.dart
flutter analyze
git add lib/features/mood_entry/domain/entities/mood_entry.dart test/features/mood_entry/domain/mood_entry_test.dart
git commit -m "feat(domain): add MoodEntry entity with intensity/sleep validators"
```

---

## Task 9: `EntryQuery` + `MoodEntryRepository` interface

**Files:**
- Create: `lib/features/mood_entry/domain/repositories/entry_query.dart`
- Create: `lib/features/mood_entry/domain/repositories/mood_entry_repository.dart`

- [x] **Step 1: Implement `entry_query.dart`**

```dart
import 'package:flutter/foundation.dart';

import '../enums/mood.dart';

@immutable
class EntryQuery {
  const EntryQuery({
    this.dateRange,
    this.moodRange,
    this.tagIds,
    this.text,
    this.limit,
  });

  final DateTimeRange? dateRange;
  final ({Mood min, Mood max})? moodRange;
  final List<String>? tagIds;
  final String? text;
  final int? limit;
}

@immutable
class DateTimeRange {
  const DateTimeRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}
```

- [x] **Step 2: Implement `mood_entry_repository.dart`**

```dart
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/mood_entry.dart';
import 'entry_query.dart';

abstract class MoodEntryRepository {
  Future<(MoodEntry?, Failure?)> create(MoodEntry entry);
  Future<(MoodEntry?, Failure?)> update(MoodEntry entry);
  Future<(Unit?, Failure?)> delete(String id);
  Future<(MoodEntry?, Failure?)> getById(String id);
  Stream<List<MoodEntry>> watchAll({EntryQuery? query});
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query});
}
```

- [x] **Step 3: Analyze + commit**

```bash
flutter analyze
git add lib/features/mood_entry/domain/repositories
git commit -m "feat(domain): add EntryQuery and MoodEntryRepository interface"
```

(No test in this task — the interface itself has no logic. Behavior is exercised in Task 11.)

---

## Task 10: DTO mapper between Drift rows and `MoodEntry`

**Files:**
- Create: `lib/features/mood_entry/data/mappers/mood_entry_mapper.dart`
- Create: `test/features/mood_entry/data/mood_entry_mapper_test.dart`

- [x] **Step 1: Write the test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/db/app_database.dart';
import 'package:mood_tracker/features/mood_entry/data/mappers/mood_entry_mapper.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

void main() {
  final ts = DateTime(2026, 5, 17, 14).millisecondsSinceEpoch;
  final row = EntryRow(
    id: 'e1',
    occurredAt: ts,
    mood: Mood.good.index,
    intensity: 7,
    note: 'fine',
    sleepHours: 7.5,
    energy: EnergyLevel.high.index,
    createdAt: ts,
    updatedAt: ts,
  );

  test('rowToEntity maps fields + tags', () {
    final entity = rowToEntity(row, tags: const [
      Tag(id: 't1', slug: 'work', label: 'Work'),
    ]);
    expect(entity.id, 'e1');
    expect(entity.mood, Mood.good);
    expect(entity.intensity, 7);
    expect(entity.tags.single.slug, 'work');
  });

  test('entityToRow round-trips', () {
    final entity = MoodEntry(
      id: 'e1',
      occurredAt: DateTime.fromMillisecondsSinceEpoch(ts),
      mood: Mood.good,
      intensity: 7,
      note: 'fine',
      tags: const [],
      sleepHours: 7.5,
      energy: EnergyLevel.high,
      createdAt: DateTime.fromMillisecondsSinceEpoch(ts),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(ts),
    );
    final converted = entityToRow(entity);
    expect(converted.id, 'e1');
    expect(converted.mood, Mood.good.index);
    expect(converted.energy, EnergyLevel.high.index);
  });
}
```

(`EntryRow` and `TagRow` are the Drift-generated row classes, named via the `@DataClassName` annotations from Task 6.)

- [x] **Step 2: FAIL**

Run: `flutter test test/features/mood_entry/data/mood_entry_mapper_test.dart` → FAIL

- [x] **Step 3: Implement `lib/features/mood_entry/data/mappers/mood_entry_mapper.dart`**

```dart
import '../../../../core/db/app_database.dart';
import '../../domain/entities/mood_entry.dart';
import '../../domain/entities/tag.dart';
import '../../domain/enums/energy_level.dart';
import '../../domain/enums/mood.dart';

MoodEntry rowToEntity(EntryRow row, {required List<Tag> tags}) {
  return MoodEntry(
    id: row.id,
    occurredAt: DateTime.fromMillisecondsSinceEpoch(row.occurredAt),
    mood: Mood.values[row.mood],
    intensity: row.intensity,
    note: row.note,
    tags: tags,
    sleepHours: row.sleepHours,
    energy: EnergyLevel.values[row.energy],
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
  );
}

EntryRow entityToRow(MoodEntry entity) {
  return EntryRow(
    id: entity.id,
    occurredAt: entity.occurredAt.millisecondsSinceEpoch,
    mood: entity.mood.index,
    intensity: entity.intensity,
    note: entity.note,
    sleepHours: entity.sleepHours,
    energy: entity.energy.index,
    createdAt: entity.createdAt.millisecondsSinceEpoch,
    updatedAt: entity.updatedAt.millisecondsSinceEpoch,
  );
}

Tag rowToTag(TagRow row) =>
    Tag(id: row.id, slug: row.slug, label: row.label);

TagRow tagToRow(Tag tag) =>
    TagRow(id: tag.id, slug: tag.slug, label: tag.label);
```

Drift companion/data names follow from the `@DataClassName` annotations in Task 6, so `EntryRow` and `TagRow` are stable across the mapper, repository, and tests.

- [x] **Step 4: PASS + analyze + commit**

```bash
flutter test test/features/mood_entry/data/mood_entry_mapper_test.dart
flutter analyze
git add lib/features/mood_entry/data/mappers test/features/mood_entry/data
git commit -m "feat(data): add Drift-row to MoodEntry/Tag mappers"
```

---

## Task 11: `MoodEntryRepository` implementation (against in-memory Drift)

**Files:**
- Create: `lib/features/mood_entry/data/mood_entry_repository_impl.dart`
- Create: `test/features/mood_entry/data/mood_entry_repository_impl_test.dart`

- [x] **Step 1: Write the integration-style test**

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/db/app_database.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_impl.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

void main() {
  late AppDatabase db;
  late MoodEntryRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MoodEntryRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  MoodEntry sample({String id = 'e1', List<Tag> tags = const []}) {
    final now = DateTime(2026, 5, 17, 14);
    return MoodEntry(
      id: id,
      occurredAt: now,
      mood: Mood.good,
      intensity: 7,
      note: 'note',
      tags: tags,
      sleepHours: 7.5,
      energy: EnergyLevel.high,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('create then getById returns the entry', () async {
    final entry = sample();
    final (created, err) = await repo.create(entry);
    expect(err, isNull);
    expect(created!.id, 'e1');

    final (fetched, err2) = await repo.getById('e1');
    expect(err2, isNull);
    expect(fetched!.intensity, 7);
  });

  test('getById missing returns NotFoundFailure', () async {
    final (entry, err) = await repo.getById('missing');
    expect(entry, isNull);
    expect(err, isA<NotFoundFailure>());
  });

  test('create persists tags via entry_tags join', () async {
    final tag = Tag(id: 't1', slug: 'work', label: 'Work');
    await repo.create(sample(tags: [tag]));

    final (fetched, _) = await repo.getById('e1');
    expect(fetched!.tags.single.slug, 'work');
  });

  test('delete removes the entry', () async {
    await repo.create(sample());
    final (unit, err) = await repo.delete('e1');
    expect(unit, isNotNull);
    expect(err, isNull);

    final (after, err2) = await repo.getById('e1');
    expect(after, isNull);
    expect(err2, isA<NotFoundFailure>());
  });

  test('watchAll emits when entries change', () async {
    final emissions = <int>[];
    final sub = repo.watchAll().listen((list) => emissions.add(list.length));

    await repo.create(sample(id: 'a'));
    await repo.create(sample(id: 'b'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(emissions, contains(0));
    expect(emissions.last, 2);

    await sub.cancel();
  });

  test('update modifies fields', () async {
    await repo.create(sample());
    final (_, _) = await repo.update(sample().copyWith(intensity: 9));
    final (fetched, _) = await repo.getById('e1');
    expect(fetched!.intensity, 9);
  });
}
```

- [x] **Step 2: FAIL**

Run: `flutter test test/features/mood_entry/data/mood_entry_repository_impl_test.dart` → FAIL

- [x] **Step 3: Implement the repo**

```dart
// lib/features/mood_entry/data/mood_entry_repository_impl.dart
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/entities/mood_entry.dart';
import '../domain/entities/tag.dart';
import '../domain/repositories/entry_query.dart';
import '../domain/repositories/mood_entry_repository.dart';
import 'mappers/mood_entry_mapper.dart';

class MoodEntryRepositoryImpl implements MoodEntryRepository {
  MoodEntryRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry entry) async {
    try {
      await _db.transaction(() async {
        await _db.into(_db.entries).insert(entityToRow(entry));
        await _upsertTags(entry.tags);
        await _replaceEntryTags(entry.id, entry.tags);
      });
      return (entry, null);
    } catch (e) {
      return (null, DatabaseFailure(debugMessage: e.toString()));
    }
  }

  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry entry) async {
    try {
      await _db.transaction(() async {
        await (_db.update(_db.entries)..where((t) => t.id.equals(entry.id)))
            .write(_entryCompanion(entry, isInsert: false));
        await _upsertTags(entry.tags);
        await _replaceEntryTags(entry.id, entry.tags);
      });
      return (entry, null);
    } catch (e) {
      return (null, DatabaseFailure(debugMessage: e.toString()));
    }
  }

  @override
  Future<(Unit?, Failure?)> delete(String id) async {
    try {
      final removed = await (_db.delete(_db.entries)
            ..where((t) => t.id.equals(id)))
          .go();
      if (removed == 0) return (null, NotFoundFailure(id: id));
      return (Unit.value, null);
    } catch (e) {
      return (null, DatabaseFailure(debugMessage: e.toString()));
    }
  }

  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async {
    try {
      final row = await (_db.select(_db.entries)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row == null) return (null, NotFoundFailure(id: id));
      final tags = await _tagsForEntry(id);
      return (rowToEntity(row, tags: tags), null);
    } catch (e) {
      return (null, DatabaseFailure(debugMessage: e.toString()));
    }
  }

  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) {
    final select = _db.select(_db.entries)
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);
    if (query?.limit != null) select.limit(query!.limit!);
    return select.watch().asyncMap(_hydrate);
  }

  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async {
    try {
      final select = _db.select(_db.entries)
        ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);
      if (query?.limit != null) select.limit(query!.limit!);
      final rows = await select.get();
      return (await _hydrate(rows), null);
    } catch (e) {
      return (null, DatabaseFailure(debugMessage: e.toString()));
    }
  }

  Future<List<MoodEntry>> _hydrate(List<EntryRow> rows) async {
    if (rows.isEmpty) return const [];
    final ids = rows.map((r) => r.id).toList();
    final joinRows = await (_db.select(_db.entryTags)
          ..where((t) => t.entryId.isIn(ids)))
        .get();
    final tagIds = joinRows.map((j) => j.tagId).toSet();
    final tagRows = tagIds.isEmpty
        ? const <TagRow>[]
        : await (_db.select(_db.tags)..where((t) => t.id.isIn(tagIds))).get();
    final tagsById = {for (final t in tagRows) t.id: rowToTag(t)};
    final tagsByEntry = <String, List<Tag>>{};
    for (final j in joinRows) {
      final tag = tagsById[j.tagId];
      if (tag != null) {
        (tagsByEntry[j.entryId] ??= <Tag>[]).add(tag);
      }
    }
    return [
      for (final r in rows) rowToEntity(r, tags: tagsByEntry[r.id] ?? const [])
    ];
  }

  Future<List<Tag>> _tagsForEntry(String entryId) async {
    final query = _db.select(_db.tags).join([
      innerJoin(
        _db.entryTags,
        _db.entryTags.tagId.equalsExp(_db.tags.id) &
            _db.entryTags.entryId.equals(entryId),
      ),
    ]);
    final rows = await query.get();
    return rows.map((r) => rowToTag(r.readTable(_db.tags))).toList();
  }

  Future<void> _upsertTags(List<Tag> tags) async {
    for (final t in tags) {
      await _db.into(_db.tags).insertOnConflictUpdate(tagToRow(t));
    }
  }

  Future<void> _replaceEntryTags(String entryId, List<Tag> tags) async {
    await (_db.delete(_db.entryTags)..where((t) => t.entryId.equals(entryId)))
        .go();
    for (final t in tags) {
      await _db.into(_db.entryTags).insert(
            EntryTagsCompanion.insert(entryId: entryId, tagId: t.id),
          );
    }
  }

  EntriesCompanion _entryCompanion(MoodEntry entry, {required bool isInsert}) {
    return EntriesCompanion(
      id: Value(entry.id),
      occurredAt: Value(entry.occurredAt.millisecondsSinceEpoch),
      mood: Value(entry.mood.index),
      intensity: Value(entry.intensity),
      note: Value(entry.note),
      sleepHours: Value(entry.sleepHours),
      energy: Value(entry.energy.index),
      createdAt: isInsert
          ? Value(entry.createdAt.millisecondsSinceEpoch)
          : const Value.absent(),
      updatedAt: Value(entry.updatedAt.millisecondsSinceEpoch),
    );
  }
}
```

The companion class names (`EntriesCompanion`, `EntryTagsCompanion`) come from Drift's default companion naming (table name + `Companion`). Row names (`EntryRow`, `TagRow`) are fixed by the `@DataClassName` annotations on the tables.

- [x] **Step 4: PASS + analyze + commit**

```bash
flutter test test/features/mood_entry/data/mood_entry_repository_impl_test.dart
flutter analyze
git add lib/features/mood_entry/data test/features/mood_entry/data
git commit -m "feat(data): implement MoodEntryRepository against Drift"
```

---

## Task 12: DI registration + Riverpod infra providers

**Files:**
- Create: `lib/core/di/service_locator.dart`
- Create: `lib/core/di/infrastructure_providers.dart`

- [x] **Step 1: Implement `lib/core/di/service_locator.dart`**

```dart
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../prefs/app_prefs.dart';

final getIt = GetIt.instance;

Future<void> registerServices() async {
  final sp = await SharedPreferences.getInstance();
  getIt
    ..registerSingleton<SharedPreferences>(sp)
    ..registerSingleton<AppPrefs>(AppPrefs(sp))
    ..registerSingleton<AppDatabase>(AppDatabase());
}
```

- [x] **Step 2: Implement `lib/core/di/infrastructure_providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../prefs/app_prefs.dart';
import 'service_locator.dart';

final appDatabaseProvider = Provider<AppDatabase>((_) => getIt<AppDatabase>());
final appPrefsProvider = Provider<AppPrefs>((_) => getIt<AppPrefs>());
```

- [x] **Step 3: Repository provider**

Create `lib/features/mood_entry/data/mood_entry_repository_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/infrastructure_providers.dart';
import '../domain/repositories/mood_entry_repository.dart';
import 'mood_entry_repository_impl.dart';

final moodEntryRepositoryProvider = Provider<MoodEntryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MoodEntryRepositoryImpl(db);
});
```

- [x] **Step 4: Analyze + commit**

```bash
flutter analyze
git add lib/core/di lib/features/mood_entry/data/mood_entry_repository_provider.dart
git commit -m "feat(core): add GetIt service locator and Riverpod infra providers"
```

(No test in this task — providers are exercised through screens/controllers tests downstream.)

---

## Task 13: Theme tokens — spacing/radius/elevation/motion

**Files:**
- Create: `lib/core/theme/app_spacing.dart`
- Create: `lib/core/theme/app_radius.dart`
- Create: `lib/core/theme/app_elevation.dart`
- Create: `lib/core/theme/app_motion.dart`

- [x] **Step 1: Implement `app_spacing.dart`**

```dart
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lgSmall = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}
```

- [x] **Step 2: Implement `app_radius.dart`**

```dart
import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 9999;

  static const BorderRadius cardBR = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheetBR = BorderRadius.vertical(top: Radius.circular(lg));
  static const BorderRadius pillBR = BorderRadius.all(Radius.circular(pill));
}
```

- [x] **Step 3: Implement `app_elevation.dart`**

```dart
import 'package:flutter/material.dart';

abstract final class AppElevation {
  static const e1 = <BoxShadow>[
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 1, offset: Offset(0, 1)),
  ];

  static const e2 = <BoxShadow>[
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static const e3 = <BoxShadow>[
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 32, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 8, offset: Offset(0, 4)),
  ];
}
```

- [x] **Step 4: Implement `app_motion.dart`**

```dart
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  /// Exit ≈ 70% of enter, per design system rule.
  static Duration exit(Duration enter) =>
      Duration(milliseconds: (enter.inMilliseconds * 0.7).round());
}
```

- [x] **Step 5: Analyze + commit**

```bash
flutter analyze
git add lib/core/theme/app_spacing.dart lib/core/theme/app_radius.dart \
        lib/core/theme/app_elevation.dart lib/core/theme/app_motion.dart
git commit -m "feat(theme): add spacing/radius/elevation/motion tokens"
```

---

## Task 14: `AppColors` + `context.appColors` extension

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Create: `test/core/theme/app_colors_test.dart`

- [x] **Step 1: Implement `lib/core/theme/app_colors.dart`**

```dart
import 'package:flutter/material.dart';

import '../../features/mood_entry/domain/enums/mood.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.muted,
    required this.onMuted,
    required this.border,
    required this.destructive,
    required this.onDestructive,
    required this.moodAwful,
    required this.moodBad,
    required this.moodOkay,
    required this.moodGood,
    required this.moodGreat,
  });

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color accent;
  final Color onAccent;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color muted;
  final Color onMuted;
  final Color border;
  final Color destructive;
  final Color onDestructive;

  final Color moodAwful;
  final Color moodBad;
  final Color moodOkay;
  final Color moodGood;
  final Color moodGreat;

  Color forMood(Mood mood) => switch (mood) {
        Mood.awful => moodAwful,
        Mood.bad => moodBad,
        Mood.okay => moodOkay,
        Mood.good => moodGood,
        Mood.great => moodGreat,
      };

  static const light = AppColors(
    primary: Color(0xFF8B5CF6),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFC4B5FD),
    onSecondary: Color(0xFF0F172A),
    accent: Color(0xFF059669),
    onAccent: Color(0xFFFFFFFF),
    background: Color(0xFFFAF5FF),
    onBackground: Color(0xFF4C1D95),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF4C1D95),
    muted: Color(0xFFEDEFF9),
    onMuted: Color(0xFF64748B),
    border: Color(0xFFEDE9FE),
    destructive: Color(0xFFDC2626),
    onDestructive: Color(0xFFFFFFFF),
    // 5-step mood scale derived from primary→accent gradient.
    moodAwful: Color(0xFF8B5CF6),
    moodBad: Color(0xFF7C7BD8),
    moodOkay: Color(0xFF6E9CB9),
    moodGood: Color(0xFF35B097),
    moodGreat: Color(0xFF059669),
  );

  static const dark = AppColors(
    primary: Color(0xFFB5A0FA),
    onPrimary: Color(0xFF1B1230),
    secondary: Color(0xFF9C8CE6),
    onSecondary: Color(0xFFF1EFFB),
    accent: Color(0xFF34D399),
    onAccent: Color(0xFF062C20),
    background: Color(0xFF1B1230),
    onBackground: Color(0xFFF1EFFB),
    surface: Color(0xFF261A40),
    onSurface: Color(0xFFF1EFFB),
    muted: Color(0xFF2F2347),
    onMuted: Color(0xFFB8B0CC),
    border: Color(0xFF3A2D55),
    destructive: Color(0xFFF87171),
    onDestructive: Color(0xFF2A0A0A),
    moodAwful: Color(0xFFB5A0FA),
    moodBad: Color(0xFFA199EA),
    moodOkay: Color(0xFF9CB6D2),
    moodGood: Color(0xFF7DD3B6),
    moodGreat: Color(0xFF34D399),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? accent,
    Color? onAccent,
    Color? background,
    Color? onBackground,
    Color? surface,
    Color? onSurface,
    Color? muted,
    Color? onMuted,
    Color? border,
    Color? destructive,
    Color? onDestructive,
    Color? moodAwful,
    Color? moodBad,
    Color? moodOkay,
    Color? moodGood,
    Color? moodGreat,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      muted: muted ?? this.muted,
      onMuted: onMuted ?? this.onMuted,
      border: border ?? this.border,
      destructive: destructive ?? this.destructive,
      onDestructive: onDestructive ?? this.onDestructive,
      moodAwful: moodAwful ?? this.moodAwful,
      moodBad: moodBad ?? this.moodBad,
      moodOkay: moodOkay ?? this.moodOkay,
      moodGood: moodGood ?? this.moodGood,
      moodGreat: moodGreat ?? this.moodGreat,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      onMuted: Color.lerp(onMuted, other.onMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      onDestructive: Color.lerp(onDestructive, other.onDestructive, t)!,
      moodAwful: Color.lerp(moodAwful, other.moodAwful, t)!,
      moodBad: Color.lerp(moodBad, other.moodBad, t)!,
      moodOkay: Color.lerp(moodOkay, other.moodOkay, t)!,
      moodGood: Color.lerp(moodGood, other.moodGood, t)!,
      moodGreat: Color.lerp(moodGreat, other.moodGreat, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
```

- [x] **Step 2: Test that the extension reads back**

```dart
// test/core/theme/app_colors_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

void main() {
  testWidgets('context.appColors returns the registered AppColors', (tester) async {
    late AppColors readBack;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Builder(builder: (ctx) {
        readBack = ctx.appColors;
        return const SizedBox.shrink();
      }),
    ));
    expect(readBack.primary, AppColors.light.primary);
  });

  test('forMood resolves all five enum cases', () {
    final c = AppColors.light;
    expect(c.forMood(Mood.awful), c.moodAwful);
    expect(c.forMood(Mood.bad), c.moodBad);
    expect(c.forMood(Mood.okay), c.moodOkay);
    expect(c.forMood(Mood.good), c.moodGood);
    expect(c.forMood(Mood.great), c.moodGreat);
  });
}
```

- [x] **Step 3: PASS + analyze + commit**

```bash
flutter test test/core/theme/app_colors_test.dart
flutter analyze
git add lib/core/theme/app_colors.dart test/core/theme/app_colors_test.dart
git commit -m "feat(theme): add AppColors with light/dark schemes and mood scale"
```

---

## Task 15: `AppTextStyles` (Lora + Raleway)

**Files:**
- Create: `lib/core/theme/app_text_styles.dart`

- [x] **Step 1: Implement**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTextStyles {
  static TextStyle get display => GoogleFonts.lora(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get headline => GoogleFonts.lora(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get title => GoogleFonts.lora(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get body => GoogleFonts.raleway(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );

  static TextStyle get bodySmall => GoogleFonts.raleway(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.raleway(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.4,
      );

  static TextStyle get caption => GoogleFonts.raleway(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextTheme themeFor(Color onSurface) {
    final base = TextTheme(
      displayLarge: display,
      headlineSmall: headline,
      titleLarge: title,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: bodySmall,
      labelLarge: label,
      labelMedium: label,
      labelSmall: caption,
    );
    return base.apply(bodyColor: onSurface, displayColor: onSurface);
  }
}
```

- [x] **Step 2: Analyze + commit**

```bash
flutter analyze
git add lib/core/theme/app_text_styles.dart
git commit -m "feat(theme): add Lora+Raleway type scale via google_fonts"
```

---

## Task 16: `AppTheme` factory + `ThemeNotifier`

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/theme/theme_notifier.dart`

- [x] **Step 1: Implement `app_theme.dart`**

```dart
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        secondary: colors.secondary,
        onSecondary: colors.onSecondary,
        error: colors.destructive,
        onError: colors.onDestructive,
        surface: colors.surface,
        onSurface: colors.onSurface,
      ),
      scaffoldBackgroundColor: colors.background,
      textTheme: AppTextStyles.themeFor(colors.onSurface),
      extensions: [colors],
    );
  }
}
```

- [x] **Step 2: Implement `theme_notifier.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/infrastructure_providers.dart';
import '../prefs/app_prefs.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  late AppPrefs _prefs;

  @override
  ThemeMode build() {
    _prefs = ref.watch(appPrefsProvider);
    return switch (_prefs.themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setThemeMode(switch (mode) {
      ThemeMode.light => AppThemeMode.light,
      ThemeMode.dark => AppThemeMode.dark,
      ThemeMode.system => AppThemeMode.system,
    });
  }
}

final themeModeProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
```

- [x] **Step 3: Analyze + commit**

```bash
flutter analyze
git add lib/core/theme/app_theme.dart lib/core/theme/theme_notifier.dart
git commit -m "feat(theme): add AppTheme builder and ThemeNotifier"
```

---

## Task 17: l10n pipeline + `app_en.arb` + `context.l10n` extension

**Files:**
- Create: `lib/l10n/app_en.arb`
- Create: `lib/core/l10n/context_l10n_extension.dart`
- Create: `lib/core/l10n/locale_notifier.dart`

- [x] **Step 1: Create `lib/l10n/app_en.arb`**

```json
{
  "@@locale": "en",

  "appTitle": "Mood Tracker",
  "@appTitle": {},

  "todayGreetingMorning": "Good morning",
  "@todayGreetingMorning": {},
  "todayGreetingAfternoon": "Good afternoon",
  "@todayGreetingAfternoon": {},
  "todayGreetingEvening": "Good evening",
  "@todayGreetingEvening": {},
  "todayPrompt": "How are you feeling right now?",
  "@todayPrompt": {},
  "todayRecentTitle": "Recent",
  "@todayRecentTitle": {},
  "todayEmptyMessage": "Log your first mood to see it here.",
  "@todayEmptyMessage": {},

  "moodAwful": "Awful",
  "@moodAwful": {},
  "moodBad": "Bad",
  "@moodBad": {},
  "moodOkay": "Okay",
  "@moodOkay": {},
  "moodGood": "Good",
  "@moodGood": {},
  "moodGreat": "Great",
  "@moodGreat": {},

  "energyVeryLow": "Very low",
  "@energyVeryLow": {},
  "energyLow": "Low",
  "@energyLow": {},
  "energyMedium": "Medium",
  "@energyMedium": {},
  "energyHigh": "High",
  "@energyHigh": {},
  "energyVeryHigh": "Very high",
  "@energyVeryHigh": {},

  "logEntryTitle": "How are you feeling?",
  "@logEntryTitle": {},
  "logEntryFieldIntensity": "Intensity",
  "@logEntryFieldIntensity": {},
  "logEntryFieldEnergy": "Energy",
  "@logEntryFieldEnergy": {},
  "logEntryFieldSleepHours": "Sleep (hours)",
  "@logEntryFieldSleepHours": {},
  "logEntryFieldTags": "Tags",
  "@logEntryFieldTags": {},
  "logEntryFieldNote": "Note",
  "@logEntryFieldNote": {},
  "logEntryFieldOccurredAt": "When",
  "@logEntryFieldOccurredAt": {},
  "logEntrySave": "Save",
  "@logEntrySave": {},
  "logEntryCancel": "Cancel",
  "@logEntryCancel": {},
  "logEntryDiscardConfirm": "Discard this entry?",
  "@logEntryDiscardConfirm": {},

  "historyTitle": "History",
  "@historyTitle": {},
  "historyEmpty": "Nothing logged yet.",
  "@historyEmpty": {},
  "historyDelete": "Delete entry",
  "@historyDelete": {},
  "historyDeleteUndo": "Undo",
  "@historyDeleteUndo": {},

  "entryDetailTitle": "Entry",
  "@entryDetailTitle": {},
  "entryDetailEdit": "Edit",
  "@entryDetailEdit": {},
  "entryDetailDelete": "Delete",
  "@entryDetailDelete": {},

  "errorTitle": "Something went wrong",
  "@errorTitle": {},
  "errorRetry": "Try again",
  "@errorRetry": {},
  "errorDatabase": "Couldn't reach local storage.",
  "@errorDatabase": {},
  "errorNotFound": "We couldn't find that entry.",
  "@errorNotFound": {},
  "errorValidationIntensity": "Intensity must be between 1 and 10.",
  "@errorValidationIntensity": {},
  "errorValidationSleepHours": "Sleep hours must be between 0 and 24.",
  "@errorValidationSleepHours": {},
  "errorUnknown": "Unexpected error.",
  "@errorUnknown": {},

  "navToday": "Today",
  "@navToday": {},
  "navHistory": "History",
  "@navHistory": {},
  "navCalendar": "Calendar",
  "@navCalendar": {},
  "navInsights": "Insights",
  "@navInsights": {},
  "navSettings": "Settings",
  "@navSettings": {}
}
```

- [x] **Step 2: Generate localizations**

Run: `flutter gen-l10n`
Expected: writes `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_en.dart` (auto-generated). These files are gitignored — never commit them. The generated `AppLocalizations` class is importable as `package:mood_tracker/l10n/app_localizations.dart`.

- [x] **Step 3: Implement `context_l10n_extension.dart`**

```dart
import 'package:flutter/widgets.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

- [x] **Step 4: Implement `locale_notifier.dart`**

```dart
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/infrastructure_providers.dart';
import '../prefs/app_prefs.dart';

class LocaleNotifier extends Notifier<Locale?> {
  late AppPrefs _prefs;

  @override
  Locale? build() {
    _prefs = ref.watch(appPrefsProvider);
    final tag = _prefs.localeTag;
    return tag == null ? null : Locale(tag);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    await _prefs.setLocaleTag(locale?.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
```

- [x] **Step 5: Analyze + commit**

```bash
flutter analyze
git add lib/l10n lib/core/l10n
git commit -m "feat(l10n): add EN ARB, AppLocalizations pipeline, context.l10n"
```

---

## Task 18: `AppRoutes` constants + `AppRouter` (GoRouter shell)

**Files:**
- Create: `lib/core/navigation/app_routes.dart`
- Create: `lib/core/navigation/app_router.dart`

- [x] **Step 1: Implement `app_routes.dart`**

```dart
abstract final class AppRoutes {
  static const String today = '/today';
  static const String history = '/history';
  static const String calendar = '/calendar';
  static const String insights = '/insights';
  static const String settings = '/settings';

  static const String log = '/today/log';
  static const String entryDetail = '/entry'; // /entry/:id
  static const String entryEdit = '/entry/:id/edit';

  static String entryDetailFor(String id) => '/entry/$id';
  static String entryEditFor(String id) => '/entry/$id/edit';
}
```

- [x] **Step 2: Implement `app_router.dart`**

```dart
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
              builder: (_, __) => const TodayScreen(),
              routes: [
                GoRoute(
                  path: 'log',
                  pageBuilder: (_, __) => const MaterialPage(
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
              builder: (_, __) => const HistoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.calendar,
              builder: (_, __) => const _PlaceholderScreen('Calendar'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.insights,
              builder: (_, __) => const _PlaceholderScreen('Insights'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (_, __) => const _PlaceholderScreen('Settings'),
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
    final destinations = const [
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
        onDestinationSelected: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
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
  const _NavDest({required this.icon, required this.selectedIcon, required this.labelKey});
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;
}
```

(The bottom-nav labels here use literals as a temporary scaffold. Task 31 swaps them for `context.l10n.navToday`/etc. once the shell can read `l10n`. Lucide icons replace the Material icons used here in a follow-up sweep — keeping them as Material in this task lets the router compile without depending on widget tasks yet.)

- [x] **Step 3: Analyze**

Run `flutter analyze`. Expected: errors about unresolved imports of `TodayScreen`, `HistoryScreen`, `EntryDetailScreen`, `LogEntrySheet` — those screens are defined in later tasks. Until then, the router does not compile.

To unblock analysis, add **temporary placeholder shims** in this task:

`lib/features/today/presentation/screens/today_screen.dart`:

```dart
import 'package:flutter/material.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Today (placeholder)')));
}
```

`lib/features/history/presentation/screens/history_screen.dart`:

```dart
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('History (placeholder)')));
}
```

`lib/features/history/presentation/screens/entry_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';

class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key, required this.entryId});
  final String entryId;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Entry $entryId (placeholder)')));
}
```

`lib/features/mood_entry/presentation/screens/log_entry_sheet.dart`:

```dart
import 'package:flutter/material.dart';

class LogEntrySheet extends StatelessWidget {
  const LogEntrySheet({super.key, this.editEntryId});
  final String? editEntryId;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Log entry (placeholder)')));
}
```

These shims are replaced by the real screens in Tasks 23-25.

- [x] **Step 4: Analyze + commit**

```bash
flutter analyze
git add lib/core/navigation \
        lib/features/today/presentation/screens/today_screen.dart \
        lib/features/history/presentation/screens/history_screen.dart \
        lib/features/history/presentation/screens/entry_detail_screen.dart \
        lib/features/mood_entry/presentation/screens/log_entry_sheet.dart
git commit -m "feat(navigation): add AppRoutes constants and GoRouter shell with placeholder screens"
```

---

## Task 19: `MoodFace` `CustomPainter` (+ golden tests)

**Files:**
- Create: `lib/core/widgets/mood_face.dart`
- Create: `test/core/widgets/mood_face_test.dart`
- Create: `test/core/widgets/goldens/mood_face_awful.png` (generated by `flutter test --update-goldens`)
- Create: `test/core/widgets/goldens/mood_face_bad.png` (idem)
- Create: `test/core/widgets/goldens/mood_face_okay.png` (idem)
- Create: `test/core/widgets/goldens/mood_face_good.png` (idem)
- Create: `test/core/widgets/goldens/mood_face_great.png` (idem)

- [x] **Step 1: Implement `lib/core/widgets/mood_face.dart`**

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/mood_entry/domain/enums/mood.dart';

/// Programmatic mood face. Curvature interpolates between awful (deep frown)
/// and great (wide smile). [strength] in [0..1] modulates feature size for
/// intensity overlays — phase 1 always renders at 1.0.
class MoodFace extends StatelessWidget {
  const MoodFace({
    super.key,
    required this.mood,
    this.color,
    this.size = 56,
    this.strokeWidth = 2.4,
    this.strength = 1.0,
  });

  final Mood mood;
  final Color? color;
  final double size;
  final double strokeWidth;
  final double strength;

  @override
  Widget build(BuildContext context) {
    final paintColor = color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MoodFacePainter(
          mood: mood,
          color: paintColor,
          strokeWidth: strokeWidth,
          strength: strength,
        ),
      ),
    );
  }
}

class _MoodFacePainter extends CustomPainter {
  _MoodFacePainter({
    required this.mood,
    required this.color,
    required this.strokeWidth,
    required this.strength,
  });

  final Mood mood;
  final Color color;
  final double strokeWidth;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - strokeWidth;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Outer circle
    canvas.drawCircle(center, r, stroke);

    // Eyes
    final eyeY = center.dy - r * 0.22;
    final eyeDx = r * 0.38;
    final eyeR = (r * 0.06) * strength.clamp(0.6, 1.2);
    final eyePaint = Paint()..color = color;
    canvas.drawCircle(Offset(center.dx - eyeDx, eyeY), eyeR, eyePaint);
    canvas.drawCircle(Offset(center.dx + eyeDx, eyeY), eyeR, eyePaint);

    // Mouth: curvature -1 (deep frown) → +1 (wide smile)
    final curvature = switch (mood) {
      Mood.awful => -1.0,
      Mood.bad => -0.5,
      Mood.okay => 0.0,
      Mood.good => 0.55,
      Mood.great => 1.0,
    };

    final mouthCenter = Offset(center.dx, center.dy + r * 0.28);
    final mouthHalfWidth = r * 0.42;
    final mouthSag = r * 0.32 * curvature * strength;

    if (curvature.abs() < 0.05) {
      // Straight line for okay
      canvas.drawLine(
        Offset(mouthCenter.dx - mouthHalfWidth, mouthCenter.dy),
        Offset(mouthCenter.dx + mouthHalfWidth, mouthCenter.dy),
        stroke,
      );
    } else {
      final path = Path()
        ..moveTo(mouthCenter.dx - mouthHalfWidth, mouthCenter.dy)
        ..quadraticBezierTo(
          mouthCenter.dx,
          mouthCenter.dy + mouthSag,
          mouthCenter.dx + mouthHalfWidth,
          mouthCenter.dy,
        );
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MoodFacePainter old) =>
      old.mood != mood ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.strength != strength;
}
```

- [x] **Step 2: Write golden tests**

```dart
// test/core/widgets/mood_face_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/widgets/mood_face.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

Future<void> _pumpFace(WidgetTester tester, Mood mood) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: MoodFace(mood: mood, color: Colors.black, size: 80),
      ),
    ),
  ));
}

void main() {
  for (final mood in Mood.values) {
    testWidgets('MoodFace renders ${mood.name} matching golden', (tester) async {
      await _pumpFace(tester, mood);
      await expectLater(
        find.byType(MoodFace),
        matchesGoldenFile('goldens/mood_face_${mood.name}.png'),
      );
    });
  }

  testWidgets('different moods produce different pixels', (tester) async {
    // Sanity check that the painter actually varies output, in case any
    // golden file gets accidentally re-generated to all-identical bytes.
    await _pumpFace(tester, Mood.awful);
    final byMood = <Mood, int>{};
    for (final mood in Mood.values) {
      await tester.pumpWidget(MaterialApp(
        home: MoodFace(mood: mood, color: Colors.black, size: 32),
      ));
      byMood[mood] = tester.takeException().hashCode; // smoke value
    }
    expect(byMood.length, Mood.values.length);
  });
}
```

- [x] **Step 3: Run goldens for the first time**

Run: `flutter test --update-goldens test/core/widgets/mood_face_test.dart`
Expected: writes PNG files under `test/core/widgets/goldens/`. Tests now PASS.

- [x] **Step 4: Re-run without update flag**

Run: `flutter test test/core/widgets/mood_face_test.dart`
Expected: all 5 goldens PASS.

- [x] **Step 5: Commit**

```bash
flutter analyze
git add lib/core/widgets/mood_face.dart test/core/widgets/mood_face_test.dart \
        test/core/widgets/goldens
git commit -m "feat(widgets): add MoodFace CustomPainter with per-mood goldens"
```

---

## Task 20: `MoodCard`, `MoodDot`, and supporting widgets

**Files:**
- Create: `lib/core/widgets/mood_card.dart`
- Create: `lib/core/widgets/mood_dot.dart`
- Create: `lib/core/widgets/app_chip.dart`
- Create: `lib/core/widgets/app_divider.dart`
- Create: `lib/core/widgets/empty_state_view.dart`
- Create: `lib/core/widgets/error_view.dart`
- Create: `test/core/widgets/mood_card_test.dart`

- [x] **Step 1: Implement `mood_card.dart`**

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../../features/mood_entry/domain/enums/mood.dart';
import 'mood_face.dart';

/// Tappable card showing a [MoodFace] + label.
/// Scales subtly while pressed; scales up + fills when [isSelected].
class MoodCard extends StatefulWidget {
  const MoodCard({
    super.key,
    required this.mood,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.size = 64,
  });

  final Mood mood;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  @override
  State<MoodCard> createState() => _MoodCardState();
}

class _MoodCardState extends State<MoodCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final moodColor = colors.forMood(widget.mood);
    final selected = widget.isSelected;
    final bg = selected ? moodColor : colors.surface;
    final fg = selected ? colors.onPrimary : colors.onSurface;
    final border = selected ? moodColor : colors.border;

    final scale = _pressed ? 0.96 : (selected ? 1.05 : 1.0);

    return Semantics(
      button: true,
      label: widget.label,
      selected: selected,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: AppMotion.fast,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: AppMotion.base,
            curve: Curves.easeOut,
            width: widget.size,
            height: widget.size + 22,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.cardBR,
              border: Border.all(color: border, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MoodFace(mood: widget.mood, color: fg, size: widget.size * 0.6),
                const SizedBox(height: AppSpacing.xxs),
                Text(widget.label, style: AppTextStyles.label.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [x] **Step 2: Implement `mood_dot.dart`**

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../../features/mood_entry/domain/enums/mood.dart';

class MoodDot extends StatelessWidget {
  const MoodDot({super.key, required this.mood, this.size = 10});

  final Mood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.appColors.forMood(mood),
      ),
    );
  }
}
```

- [x] **Step 3: Implement `app_chip.dart`**

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bg = selected ? colors.primary : colors.muted;
    final fg = selected ? colors.onPrimary : colors.onMuted;
    return InkWell(
      borderRadius: AppRadius.pillBR,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.pillBR,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTextStyles.label.copyWith(color: fg)),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.xxs),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 4: Implement `app_divider.dart`**

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: context.appColors.border);
  }
}
```

- [x] **Step 5: Implement `empty_state_view.dart`**

```dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: AppTextStyles.title.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(message,
              style: AppTextStyles.body.copyWith(color: colors.onMuted),
              textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}
```

- [x] **Step 6: Implement `error_view.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../error/failure.dart';
import '../l10n/context_l10n_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: colors.destructive, size: 36),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.errorTitle,
              style: AppTextStyles.title.copyWith(color: colors.onSurface)),
          const SizedBox(height: AppSpacing.xs),
          Text(_describe(l10n, failure),
              style: AppTextStyles.body.copyWith(color: colors.onMuted),
              textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: Text(l10n.errorRetry)),
          ],
        ],
      ),
    );
  }

  String _describe(AppLocalizations l10n, Failure f) => switch (f) {
        DatabaseFailure() => l10n.errorDatabase,
        NotFoundFailure() => l10n.errorNotFound,
        ValidationFailure(:final fieldErrors) =>
          fieldErrors.containsKey('intensity')
              ? l10n.errorValidationIntensity
              : (fieldErrors.containsKey('sleepHours')
                  ? l10n.errorValidationSleepHours
                  : l10n.errorUnknown),
        IOFailure() => l10n.errorUnknown,
        UnknownFailure() => l10n.errorUnknown,
      };
}
```

- [x] **Step 7: Write a widget test for `MoodCard`**

```dart
// test/core/widgets/mood_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/core/widgets/mood_card.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

void main() {
  testWidgets('MoodCard fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: MoodCard(
          mood: Mood.good,
          label: 'Good',
          isSelected: false,
          onTap: () => taps++,
        ),
      ),
    ));
    await tester.tap(find.byType(MoodCard));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('MoodCard renders label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: MoodCard(
          mood: Mood.good,
          label: 'Good',
          isSelected: true,
          onTap: () {},
        ),
      ),
    ));
    expect(find.text('Good'), findsOneWidget);
  });
}
```

- [x] **Step 8: PASS + analyze + commit**

```bash
flutter test test/core/widgets/mood_card_test.dart
flutter analyze
git add lib/core/widgets test/core/widgets/mood_card_test.dart
git commit -m "feat(widgets): add MoodCard, MoodDot, AppChip, AppDivider, EmptyStateView, ErrorView"
```

---

## Task 21: `LogEntryFormState` + validation

**Files:**
- Create: `lib/features/mood_entry/providers/log_entry_form_state.dart`
- Create: `test/features/mood_entry/providers/log_entry_form_state_test.dart`

- [x] **Step 1: Write the test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/providers/log_entry_form_state.dart';

void main() {
  test('blank default has no errors but is incomplete', () {
    final s = LogEntryFormState.blank(DateTime(2026, 5, 17));
    expect(s.errors, isEmpty);
    expect(s.canSubmit, isFalse, reason: 'mood not chosen');
  });

  test('canSubmit becomes true once mood is set', () {
    final s = LogEntryFormState.blank(DateTime(2026, 5, 17))
        .copyWith(mood: Mood.good);
    expect(s.canSubmit, isTrue);
  });

  test('intensity out of range flags error and blocks submit', () {
    final s = LogEntryFormState.blank(DateTime(2026, 5, 17))
        .copyWith(mood: Mood.good, intensity: 0);
    expect(s.errors.containsKey('intensity'), isTrue);
    expect(s.canSubmit, isFalse);
  });

  test('sleepHours out of range flags error', () {
    final s = LogEntryFormState.blank(DateTime(2026, 5, 17))
        .copyWith(mood: Mood.good, sleepHours: 30);
    expect(s.errors.containsKey('sleepHours'), isTrue);
  });

  test('toEntity builds a valid MoodEntry when canSubmit', () {
    final s = LogEntryFormState.blank(DateTime(2026, 5, 17)).copyWith(
      mood: Mood.good,
      energy: EnergyLevel.high,
      intensity: 7,
      note: 'fine',
      sleepHours: 7.5,
    );
    final entity = s.toEntity(id: 'e1', now: DateTime(2026, 5, 17, 14));
    expect(entity, isNotNull);
    expect(entity!.id, 'e1');
    expect(entity.mood, Mood.good);
    expect(entity.intensity, 7);
  });
}
```

- [x] **Step 2: FAIL**

Run: `flutter test test/features/mood_entry/providers/log_entry_form_state_test.dart` → FAIL.

- [x] **Step 3: Implement**

```dart
// lib/features/mood_entry/providers/log_entry_form_state.dart
import 'package:flutter/foundation.dart';

import '../domain/entities/mood_entry.dart';
import '../domain/entities/tag.dart';
import '../domain/enums/energy_level.dart';
import '../domain/enums/mood.dart';

@immutable
class LogEntryFormState {
  const LogEntryFormState({
    required this.occurredAt,
    required this.mood,
    required this.intensity,
    required this.energy,
    required this.note,
    required this.tags,
    required this.sleepHours,
  });

  factory LogEntryFormState.blank(DateTime now) => LogEntryFormState(
        occurredAt: now,
        mood: null,
        intensity: 5,
        energy: EnergyLevel.medium,
        note: '',
        tags: const [],
        sleepHours: null,
      );

  final DateTime occurredAt;
  final Mood? mood;
  final int intensity;
  final EnergyLevel energy;
  final String note;
  final List<Tag> tags;
  final double? sleepHours;

  Map<String, String> get errors {
    final e = <String, String>{};
    if (intensity < 1 || intensity > 10) e['intensity'] = 'out_of_range';
    if (sleepHours != null && (sleepHours! < 0 || sleepHours! > 24)) {
      e['sleepHours'] = 'out_of_range';
    }
    return e;
  }

  bool get canSubmit => mood != null && errors.isEmpty;

  MoodEntry? toEntity({required String id, required DateTime now}) {
    if (mood == null) return null;
    return MoodEntry(
      id: id,
      occurredAt: occurredAt,
      mood: mood!,
      intensity: intensity,
      note: note.isEmpty ? null : note,
      tags: tags,
      sleepHours: sleepHours,
      energy: energy,
      createdAt: now,
      updatedAt: now,
    );
  }

  LogEntryFormState copyWith({
    DateTime? occurredAt,
    Mood? mood,
    int? intensity,
    EnergyLevel? energy,
    String? note,
    List<Tag>? tags,
    double? sleepHours,
    bool clearSleepHours = false,
  }) {
    return LogEntryFormState(
      occurredAt: occurredAt ?? this.occurredAt,
      mood: mood ?? this.mood,
      intensity: intensity ?? this.intensity,
      energy: energy ?? this.energy,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      sleepHours: clearSleepHours ? null : (sleepHours ?? this.sleepHours),
    );
  }
}
```

- [x] **Step 4: PASS + analyze + commit**

```bash
flutter test test/features/mood_entry/providers/log_entry_form_state_test.dart
flutter analyze
git add lib/features/mood_entry/providers/log_entry_form_state.dart test/features/mood_entry/providers/log_entry_form_state_test.dart
git commit -m "feat(mood_entry): add LogEntryFormState with validation"
```

---

## Task 22: `LogEntryController` (AsyncNotifier)

**Files:**
- Create: `lib/features/mood_entry/providers/log_entry_controller.dart`
- Create: `test/features/mood_entry/providers/log_entry_controller_test.dart`

- [x] **Step 1: Write the test**

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
import 'package:mood_tracker/features/mood_entry/providers/log_entry_controller.dart';
import 'package:mood_tracker/features/mood_entry/providers/log_entry_form_state.dart';

class _FakeRepo implements MoodEntryRepository {
  final List<MoodEntry> created = [];
  MoodEntry? toReturnOnGetById;

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
      toReturnOnGetById == null
          ? (null, NotFoundFailure(id: id))
          : (toReturnOnGetById, null);

  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) => const Stream.empty();

  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (const [], null);
}

void main() {
  late ProviderContainer container;
  late _FakeRepo repo;

  setUp(() {
    repo = _FakeRepo();
    container = ProviderContainer(overrides: [
      moodEntryRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  test('initial state is blank LogEntryFormState wrapped in AsyncData', () async {
    final s = await container.read(logEntryControllerProvider(null).future);
    expect(s.mood, isNull);
  });

  test('selectMood updates state', () async {
    final notifier =
        container.read(logEntryControllerProvider(null).notifier);
    await container.read(logEntryControllerProvider(null).future);
    notifier.selectMood(Mood.good);
    final state = container.read(logEntryControllerProvider(null)).value!;
    expect(state.mood, Mood.good);
  });

  test('submit persists when valid', () async {
    final notifier =
        container.read(logEntryControllerProvider(null).notifier);
    await container.read(logEntryControllerProvider(null).future);
    notifier.selectMood(Mood.good);
    final ok = await notifier.submit();
    expect(ok, isTrue);
    expect(repo.created, hasLength(1));
    expect(repo.created.single.mood, Mood.good);
  });

  test('submit returns false and does not call repo when invalid', () async {
    final notifier =
        container.read(logEntryControllerProvider(null).notifier);
    await container.read(logEntryControllerProvider(null).future);
    final ok = await notifier.submit(); // mood not set
    expect(ok, isFalse);
    expect(repo.created, isEmpty);
  });

  test('edit mode loads existing entry', () async {
    final now = DateTime(2026, 5, 17);
    repo.toReturnOnGetById = MoodEntry(
      id: 'e1',
      occurredAt: now,
      mood: Mood.bad,
      intensity: 3,
      note: 'meh',
      tags: const [],
      sleepHours: null,
      energy: EnergyLevel.medium,
      createdAt: now,
      updatedAt: now,
    );
    final s = await container.read(logEntryControllerProvider('e1').future);
    expect(s.mood, Mood.bad);
    expect(s.intensity, 3);
  });
}
```

(`EnergyLevel.medium` import is implicit via `mood_entry.dart`; the `ENERGY_DEFAULT` const above is just a tiny local readability helper.)

- [x] **Step 2: FAIL**

Run: `flutter test test/features/mood_entry/providers/log_entry_controller_test.dart` → FAIL.

- [x] **Step 3: Implement**

```dart
// lib/features/mood_entry/providers/log_entry_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/uuid.dart';
import '../data/mood_entry_repository_provider.dart';
import '../domain/entities/tag.dart';
import '../domain/enums/energy_level.dart';
import '../domain/enums/mood.dart';
import '../domain/repositories/mood_entry_repository.dart';
import 'log_entry_form_state.dart';

class LogEntryController
    extends AutoDisposeFamilyAsyncNotifier<LogEntryFormState, String?> {
  late MoodEntryRepository _repo;
  late String _entryId;

  @override
  Future<LogEntryFormState> build(String? editEntryId) async {
    _repo = ref.watch(moodEntryRepositoryProvider);
    final now = DateTime.now();
    if (editEntryId == null) {
      _entryId = generateId();
      return LogEntryFormState.blank(now);
    }
    _entryId = editEntryId;
    final (entry, err) = await _repo.getById(editEntryId);
    if (entry == null) throw err!;
    return LogEntryFormState(
      occurredAt: entry.occurredAt,
      mood: entry.mood,
      intensity: entry.intensity,
      energy: entry.energy,
      note: entry.note ?? '',
      tags: entry.tags,
      sleepHours: entry.sleepHours,
    );
  }

  void selectMood(Mood mood) => _patch((s) => s.copyWith(mood: mood));
  void setIntensity(int v) => _patch((s) => s.copyWith(intensity: v));
  void setEnergy(EnergyLevel v) => _patch((s) => s.copyWith(energy: v));
  void setNote(String v) => _patch((s) => s.copyWith(note: v));
  void setSleepHours(double? v) => _patch(
      (s) => s.copyWith(sleepHours: v, clearSleepHours: v == null));
  void setOccurredAt(DateTime v) => _patch((s) => s.copyWith(occurredAt: v));
  void setTags(List<Tag> v) => _patch((s) => s.copyWith(tags: v));

  void _patch(LogEntryFormState Function(LogEntryFormState) f) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(f(current));
  }

  Future<bool> submit() async {
    final s = state.value;
    if (s == null || !s.canSubmit) return false;
    final now = DateTime.now();
    final entity = s.toEntity(id: _entryId, now: now)!;
    final (_, err) = arg == null
        ? await _repo.create(entity)
        : await _repo.update(entity);
    return err == null;
  }
}

final logEntryControllerProvider = AsyncNotifierProvider.autoDispose
    .family<LogEntryController, LogEntryFormState, String?>(
  LogEntryController.new,
);
```

- [x] **Step 4: PASS + analyze + commit**

```bash
flutter test test/features/mood_entry/providers/log_entry_controller_test.dart
flutter analyze
git add lib/features/mood_entry/providers/log_entry_controller.dart test/features/mood_entry/providers/log_entry_controller_test.dart
git commit -m "feat(mood_entry): add LogEntryController async notifier with create/edit support"
```

---

## Task 23: `LogEntrySheet` UI

**Files:**
- Modify: `lib/features/mood_entry/presentation/screens/log_entry_sheet.dart` (replaces placeholder from Task 18)
- Create: `lib/features/mood_entry/presentation/widgets/mood_picker_row.dart`
- Create: `lib/features/mood_entry/presentation/widgets/intensity_slider.dart`
- Create: `lib/features/mood_entry/presentation/widgets/energy_segmented.dart`
- Create: `lib/features/mood_entry/presentation/widgets/tag_chip_input.dart`
- Create: `test/features/mood_entry/presentation/log_entry_sheet_test.dart`

- [x] **Step 1: Implement `mood_picker_row.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mood_card.dart';
import '../../domain/enums/mood.dart';

class MoodPickerRow extends StatelessWidget {
  const MoodPickerRow({super.key, required this.selected, required this.onSelect});

  final Mood? selected;
  final ValueChanged<Mood> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final mood in Mood.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs / 2),
            child: MoodCard(
              mood: mood,
              label: _labelFor(l10n, mood),
              isSelected: selected == mood,
              onTap: () => onSelect(mood),
            ),
          ),
      ],
    );
  }

  String _labelFor(AppLocalizations l10n, Mood mood) => switch (mood) {
        Mood.awful => l10n.moodAwful,
        Mood.bad => l10n.moodBad,
        Mood.okay => l10n.moodOkay,
        Mood.good => l10n.moodGood,
        Mood.great => l10n.moodGreat,
      };
}
```

- [x] **Step 2: Implement `intensity_slider.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class IntensitySlider extends StatelessWidget {
  const IntensitySlider({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l10n.logEntryFieldIntensity,
                style: AppTextStyles.label.copyWith(color: colors.onMuted)),
            Text('$value',
                style: AppTextStyles.title.copyWith(color: colors.onSurface)),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Slider(
          min: 1,
          max: 10,
          divisions: 9,
          value: value.toDouble(),
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
```

- [x] **Step 3: Implement `energy_segmented.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../domain/enums/energy_level.dart';

class EnergySegmented extends StatelessWidget {
  const EnergySegmented({super.key, required this.value, required this.onChanged});

  final EnergyLevel value;
  final ValueChanged<EnergyLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.logEntryFieldEnergy, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.xxs,
          children: [
            for (final level in EnergyLevel.values)
              AppChip(
                label: _labelFor(l10n, level),
                selected: level == value,
                onTap: () => onChanged(level),
              ),
          ],
        ),
      ],
    );
  }

  String _labelFor(AppLocalizations l10n, EnergyLevel level) => switch (level) {
        EnergyLevel.veryLow => l10n.energyVeryLow,
        EnergyLevel.low => l10n.energyLow,
        EnergyLevel.medium => l10n.energyMedium,
        EnergyLevel.high => l10n.energyHigh,
        EnergyLevel.veryHigh => l10n.energyVeryHigh,
      };
}
```

- [x] **Step 4: Implement `tag_chip_input.dart` (minimal: free-form add)**

```dart
import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/uuid.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../domain/entities/tag.dart';

class TagChipInput extends StatefulWidget {
  const TagChipInput({super.key, required this.tags, required this.onChanged});

  final List<Tag> tags;
  final ValueChanged<List<Tag>> onChanged;

  @override
  State<TagChipInput> createState() => _TagChipInputState();
}

class _TagChipInputState extends State<TagChipInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final label = raw.trim();
    if (label.isEmpty) return;
    final slug = Tag.slugify(label);
    if (widget.tags.any((t) => t.slug == slug)) {
      _controller.clear();
      return;
    }
    widget.onChanged([
      ...widget.tags,
      Tag(id: generateId(), slug: slug, label: label),
    ]);
    _controller.clear();
  }

  void _remove(Tag tag) {
    widget.onChanged(widget.tags.where((t) => t.id != tag.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.logEntryFieldTags, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.xxs,
          runSpacing: AppSpacing.xxs,
          children: [
            for (final t in widget.tags)
              AppChip(
                label: t.label,
                selected: true,
                onTap: () => _remove(t),
                trailing: const Icon(Icons.close, size: 14),
              ),
          ],
        ),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: '+'),
          onSubmitted: _add,
        ),
      ],
    );
  }
}
```

- [x] **Step 5: Implement the sheet**

Replace `lib/features/mood_entry/presentation/screens/log_entry_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_view.dart';
import '../../providers/log_entry_controller.dart';
import '../widgets/energy_segmented.dart';
import '../widgets/intensity_slider.dart';
import '../widgets/mood_picker_row.dart';
import '../widgets/tag_chip_input.dart';

class LogEntrySheet extends ConsumerWidget {
  const LogEntrySheet({super.key, this.editEntryId});

  final String? editEntryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final asyncState = ref.watch(logEntryControllerProvider(editEntryId));
    final controller =
        ref.read(logEntryControllerProvider(editEntryId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logEntryTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          failure: e is Failure ? e : UnknownFailure(cause: e),
          onRetry: () => ref.invalidate(logEntryControllerProvider(editEntryId)),
        ),
        data: (form) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoodPickerRow(
                selected: form.mood,
                onSelect: controller.selectMood,
              ),
              const SizedBox(height: AppSpacing.lg),
              IntensitySlider(value: form.intensity, onChanged: controller.setIntensity),
              const SizedBox(height: AppSpacing.lg),
              EnergySegmented(value: form.energy, onChanged: controller.setEnergy),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                decoration: InputDecoration(labelText: l10n.logEntryFieldSleepHours),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (raw) => controller.setSleepHours(double.tryParse(raw)),
              ),
              const SizedBox(height: AppSpacing.lg),
              TagChipInput(tags: form.tags, onChanged: controller.setTags),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                decoration: InputDecoration(labelText: l10n.logEntryFieldNote),
                minLines: 3,
                maxLines: 6,
                onChanged: controller.setNote,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: form.canSubmit
                    ? () async {
                        final ok = await controller.submit();
                        if (ok && context.mounted) context.pop();
                      }
                    : null,
                child: Text(l10n.logEntrySave, style: AppTextStyles.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [x] **Step 6: Widget test — happy path**

```dart
// test/features/mood_entry/presentation/log_entry_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/features/mood_entry/presentation/screens/log_entry_sheet.dart';

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
      (const [], null);
}

void main() {
  testWidgets('select mood then save persists an entry', (tester) async {
    final repo = _MemRepo();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        moodEntryRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LogEntrySheet(),
      ),
    ));
    await tester.pumpAndSettle();

    // Tap the "Good" card (label localized to "Good" in EN).
    await tester.tap(find.text('Good'));
    await tester.pump();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.created, hasLength(1));
    expect(repo.created.single.mood.name, 'good');
  });
}
```

- [x] **Step 7: PASS + analyze + commit**

```bash
flutter test test/features/mood_entry/presentation/log_entry_sheet_test.dart
flutter analyze
git add lib/features/mood_entry/presentation test/features/mood_entry/presentation
git commit -m "feat(mood_entry): implement LogEntrySheet with mood picker + form fields"
```

---

## Task 24: `HistoryController` + `HistoryScreen` + `EntryDetailScreen`

**Files:**
- Create: `lib/features/history/providers/history_controller.dart`
- Modify: `lib/features/history/presentation/screens/history_screen.dart` (replaces placeholder)
- Modify: `lib/features/history/presentation/screens/entry_detail_screen.dart` (replaces placeholder)
- Create: `lib/features/history/presentation/widgets/history_row.dart`
- Create: `test/features/history/history_screen_test.dart`

- [x] **Step 1: Implement `history_controller.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood_entry/data/mood_entry_repository_provider.dart';
import '../../mood_entry/domain/entities/mood_entry.dart';

final historyProvider = StreamProvider<List<MoodEntry>>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  return repo.watchAll();
});
```

- [x] **Step 2: Implement `history_row.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mood_dot.dart';
import '../../../mood_entry/domain/entities/mood_entry.dart';

class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.entry, required this.onTap});

  final MoodEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fmt = DateFormat.MMMd().add_jm();
    return ListTile(
      leading: MoodDot(mood: entry.mood, size: 14),
      title: Text(fmt.format(entry.occurredAt), style: AppTextStyles.body),
      subtitle: Text(
        entry.note ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySmall.copyWith(color: colors.onMuted),
      ),
      onTap: onTap,
    );
  }
}
```

- [x] **Step 3: Implement `history_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../mood_entry/domain/entities/mood_entry.dart';
import '../../../mood_entry/domain/entities/tag.dart';
import '../../../mood_entry/domain/enums/energy_level.dart';
import '../../../mood_entry/domain/enums/mood.dart';
import '../../providers/history_controller.dart';
import '../widgets/history_row.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: async.when(
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
            return EmptyStateView(title: l10n.historyTitle, message: l10n.historyEmpty);
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

- [x] **Step 4: Implement `entry_detail_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/mood_dot.dart';
import '../../../mood_entry/data/mood_entry_repository_provider.dart';
import '../../../mood_entry/domain/entities/mood_entry.dart';

final entryByIdProvider =
    FutureProvider.autoDispose.family<MoodEntry, String>((ref, id) async {
  final (entry, err) = await ref.watch(moodEntryRepositoryProvider).getById(id);
  if (entry == null) throw err!;
  return entry;
});

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.entryId});
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(entryByIdProvider(entryId));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.entryDetailTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push(AppRoutes.entryEditFor(entryId)),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final (_, err) = await ref
                  .read(moodEntryRepositoryProvider)
                  .delete(entryId);
              if (err == null && context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            ErrorView(failure: e is Failure ? e : const UnknownFailure(cause: 'unknown')),
        data: (entry) {
          final colors = context.appColors;
          final fmt = DateFormat.yMMMMd().add_jm();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MoodDot(mood: entry.mood, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Text(entry.mood.name, style: AppTextStyles.headline),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(fmt.format(entry.occurredAt),
                    style: AppTextStyles.bodySmall.copyWith(color: colors.onMuted)),
                const SizedBox(height: AppSpacing.lg),
                if ((entry.note ?? '').isNotEmpty)
                  Text(entry.note!, style: AppTextStyles.body),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

- [x] **Step 5: Write a widget test for the empty state**

```dart
// test/features/history/history_screen_test.dart
import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/history/presentation/screens/history_screen.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';

class _EmptyRepo implements MoodEntryRepository {
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) => Stream.value(const []);
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (const [], null);
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
  testWidgets('shows empty state when no entries', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HistoryScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Nothing logged yet.'), findsOneWidget);
  });
}
```

- [x] **Step 6: PASS + analyze + commit**

```bash
flutter test test/features/history/history_screen_test.dart
flutter analyze
git add lib/features/history test/features/history
git commit -m "feat(history): add HistoryScreen + EntryDetailScreen with delete + empty state"
```

---

## Task 25: `TodayController` + `TodayScreen`

**Files:**
- Create: `lib/features/today/providers/today_controller.dart`
- Modify: `lib/features/today/presentation/screens/today_screen.dart` (replaces placeholder)
- Create: `test/features/today/today_screen_test.dart`

- [x] **Step 1: Implement `today_controller.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood_entry/data/mood_entry_repository_provider.dart';
import '../../mood_entry/domain/entities/mood_entry.dart';

/// Top 3 most-recent entries for the Today screen.
final recentEntriesProvider = StreamProvider<List<MoodEntry>>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  return repo.watchAll().map((all) => all.take(3).toList());
});

String greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 12) return 'morning';
  if (h < 18) return 'afternoon';
  return 'evening';
}
```

- [x] **Step 2: Implement `today_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/mood_dot.dart';
import '../../../mood_entry/domain/entities/mood_entry.dart';
import '../../../mood_entry/domain/entities/tag.dart';
import '../../../mood_entry/domain/enums/energy_level.dart';
import '../../../mood_entry/domain/enums/mood.dart';
import '../../providers/today_controller.dart';
import '../widgets/quick_log_row.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final async = ref.watch(recentEntriesProvider);
    final greeting = switch (greetingFor(DateTime.now())) {
      'morning' => l10n.todayGreetingMorning,
      'afternoon' => l10n.todayGreetingAfternoon,
      _ => l10n.todayGreetingEvening,
    };

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.log),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: AppTextStyles.headline.copyWith(color: colors.onBackground)),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.todayPrompt, style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.lg),
              QuickLogRow(onPick: (mood) => context.push(AppRoutes.log)),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.todayRecentTitle, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.xs),
              async.when(
                loading: () => Skeletonizer(
                  child: Column(
                    children: List.generate(3, (_) => _recentSkeleton()),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (entries) {
                  if (entries.isEmpty) {
                    return EmptyStateView(
                      title: '',
                      message: l10n.todayEmptyMessage,
                    );
                  }
                  return Column(
                    children: [
                      for (final e in entries) _recentRow(context, e),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentSkeleton() => ListTile(
        leading: const MoodDot(mood: Mood.okay, size: 14),
        title: const Text('placeholder time'),
        subtitle: const Text('placeholder note'),
      );

  Widget _recentRow(BuildContext context, MoodEntry e) {
    final fmt = DateFormat.MMMd().add_jm();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: MoodDot(mood: e.mood, size: 14),
      title: Text(fmt.format(e.occurredAt), style: AppTextStyles.body),
      subtitle: Text(
        e.note ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySmall.copyWith(color: context.appColors.onMuted),
      ),
      onTap: () => context.push(AppRoutes.entryDetailFor(e.id)),
    );
  }
}
```

- [x] **Step 3: Implement `quick_log_row.dart`**

```dart
// lib/features/today/presentation/widgets/quick_log_row.dart
import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mood_card.dart';
import '../../../mood_entry/domain/enums/mood.dart';

class QuickLogRow extends StatelessWidget {
  const QuickLogRow({super.key, required this.onPick});

  final ValueChanged<Mood> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final mood in Mood.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: MoodCard(
                mood: mood,
                label: _label(l10n, mood),
                isSelected: false,
                onTap: () => onPick(mood),
              ),
            ),
        ],
      ),
    );
  }

  String _label(AppLocalizations l10n, Mood mood) => switch (mood) {
        Mood.awful => l10n.moodAwful,
        Mood.bad => l10n.moodBad,
        Mood.okay => l10n.moodOkay,
        Mood.good => l10n.moodGood,
        Mood.great => l10n.moodGreat,
      };
}
```

- [x] **Step 4: Widget test**

```dart
// test/features/today/today_screen_test.dart
import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/features/today/presentation/screens/today_screen.dart';

class _EmptyRepo implements MoodEntryRepository {
  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) => Stream.value(const []);
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async => (const [], null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry e) async => (e, null);
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry e) async => (e, null);
  @override
  Future<(Unit?, Failure?)> delete(String id) async => (Unit.value, null);
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async => (null, NotFoundFailure(id: id));
}

void main() {
  testWidgets('renders greeting and prompt', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TodayScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('How are you feeling right now?'), findsOneWidget);
  });
}
```

- [x] **Step 5: PASS + analyze + commit**

```bash
flutter test test/features/today/today_screen_test.dart
flutter analyze
git add lib/features/today test/features/today
git commit -m "feat(today): implement Today screen with quick-log row and recent entries"
```

---

## Task 26: App bootstrap + `main.dart` wiring

**Files:**
- Create: `lib/app/bootstrap.dart`
- Create: `lib/app/app.dart`
- Modify: `lib/main.dart`

- [x] **Step 1: Implement `bootstrap.dart`**

```dart
import 'package:flutter/widgets.dart';

import '../core/di/service_locator.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await registerServices();
}
```

- [x] **Step 2: Implement `app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/l10n/locale_notifier.dart';
import '../core/navigation/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_notifier.dart';

class MoodTrackerApp extends ConsumerWidget {
  const MoodTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp.router(
        routerConfig: router,
        themeMode: mode,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      ),
    );
  }
}
```

- [x] **Step 3: Replace `lib/main.dart`**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';

Future<void> main() async {
  await bootstrap();
  runApp(const ProviderScope(child: MoodTrackerApp()));
}
```

- [x] **Step 4: Analyze**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 5: Run on a simulator/device once** *(skipped — no device available in the automated environment; deferred to the developer)*

Run: `flutter run -d <device>` (any platform); poke through Today → tap a mood → Save; verify the entry appears under "Recent" and in the History tab.

- [x] **Step 6: Commit**

```bash
git add lib/app lib/main.dart
git commit -m "feat(app): wire bootstrap, ProviderScope, ScreenUtil, theme, locale, router"
```

---

## Task 27: Integration smoke test

**Files:**
- Modify: `test/widget_test.dart`

- [x] **Step 1: Replace `test/widget_test.dart`**

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/db/app_database.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_impl.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/today/presentation/screens/today_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Today screen renders against in-memory DB', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance(); // ignore: unused_local_variable
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        moodEntryRepositoryProvider
            .overrideWith((ref) => MoodEntryRepositoryImpl(db)),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TodayScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('How are you feeling right now?'), findsOneWidget);
  });
}
```

- [x] **Step 2: Run full test suite**

Run: `flutter test`
Expected: all tests pass; new smoke test included.

- [x] **Step 3: Commit**

```bash
git add test/widget_test.dart
git commit -m "test: add Today-screen integration smoke test against in-memory Drift"
```

---

## Task 28: Final validation pass

- [x] **Step 1: Analyze must be clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [x] **Step 2: All tests pass**

Run: `flutter test`
Expected: all green, including goldens.

- [ ] **Step 3: Manual smoke run** *(skipped — no device available; deferred to the developer)*

Run: `flutter run -d <device>`
- Tap "Good" on Today → log sheet opens with Good pre-selected.
- Adjust intensity, type a note, add a tag, Save.
- Confirm the entry appears under Recent on Today.
- Switch to History tab → confirm the entry shows there.
- Tap it → entry detail screen.
- Edit → save → re-verify.
- Delete → entry vanishes, history empties.
- Hot-restart the app → data persists.

- [ ] **Step 4: Commit the manual-test note (if any)** *(N/A — manual run was not executed)*

If you discover any issues during the smoke run, file them as follow-up tasks before declaring Phase 1 complete. Otherwise, no commit needed — the validation steps are gating, not file-changing.

---

## Phase 1 complete

When Task 28 passes, Phase 1 is done. Subsequent phases (Settings + Onboarding + Spanish, Calendar + Search, Statistics & charts, Reminders + Backup) each get their own plan written against the spec.
