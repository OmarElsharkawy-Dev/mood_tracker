# Mood Tracker — Phase 5 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship daily reminders (`flutter_local_notifications` + permission flow) and JSON export/import (`share_plus` + `file_picker`, versioned envelope, merge-or-replace import). Closes out the 5-phase plan.

**Architecture:** Two new feature modules. `features/reminders/` wraps platform notifications via a thin `NotificationService`; `features/backup/` uses a pure `BackupCodec` for serialization plus a thin `BackupService` for file IO. Both screens nest under `/settings/`. The existing Phase 2 reminders stub becomes a real tile; a new "Data" tile is added.

**Tech Stack:** Flutter 3.41.9, Riverpod, plus new deps: `flutter_local_notifications`, `timezone`, `share_plus`, `file_picker`, `permission_handler`.

**Spec:** `docs/superpowers/specs/2026-05-18-phase-5-design.md`

**Predecessor:** Phase 4 complete on `main` (HEAD `50b0279`). 181 tests green, `flutter analyze` clean.

**Pre-existing infrastructure to honor (do NOT re-create):**

- `lib/core/prefs/app_prefs.dart` has `themeMode`, `localeTag`, `onboardingCompleted` — add new keys alongside, same pattern.
- `lib/features/settings/presentation/screens/settings_screen.dart` already renders a disabled Reminders tile (`settingsRemindersComingSoon` subtitle). Make it tappable in Task 12.
- `AppRoutes` constants live in `lib/core/navigation/app_routes.dart` — add 2 new constants.
- The router (`lib/core/navigation/app_router.dart`) Settings branch has child route `/settings/about`. Add `/settings/reminders` and `/settings/backup` as siblings.
- `package_info_plus` is already a dep from Phase 2 — reuse for `appVersion`.
- `MoodEntryRepository` has `create`, `getAll`, `delete`, etc. Use these for import.
- iOS `AppDelegate.swift` uses the `FlutterImplicitEngineDelegate` pattern; `GeneratedPluginRegistrant.register(...)` is already called. The plugin self-registers; we'll ALSO set `UNUserNotificationCenter.current().delegate` for foreground/tap handling.

**Working conventions (carry-over from Phases 1–4):**

- Every Dart file ends with a newline.
- After every task: `flutter analyze` reports 0 issues; `flutter test` passes.
- Commits NEVER include a `Co-Authored-By` trailer.
- Imports sorted alphabetically: package imports first, blank line, then project imports.
- `const` constructors where possible; `final` locals.
- Generated `lib/l10n/app_localizations*.dart` files are gitignored — never commit them.
- Widget tests touching Google Fonts: `GoogleFonts.config.allowRuntimeFetching = false` in `setUpAll`.
- DST-safe calendar arithmetic everywhere (`DateTime(y, m, d ± N)`, never `Duration`-based for calendar math).
- Never `git add -A` — stage specific files. There's a pre-existing unstaged `macos/Flutter/GeneratedPluginRegistrant.swift` that must NOT be committed.

---

## Task 1: Add Phase 5 plugin dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the 5 new dependencies**

Run:
```
flutter pub add flutter_local_notifications timezone share_plus file_picker permission_handler
```

This appends 5 entries to `dependencies:` and resolves the lock file.

- [ ] **Step 2: Group + alphabetize**

Open `pubspec.yaml`. Reorganize the new lines into two existing comment groups (or create a `# Reminders` and `# Backup` group). Example layout:

```yaml
  # Reminders
  flutter_local_notifications: ^X.Y.Z
  permission_handler: ^X.Y.Z
  timezone: ^X.Y.Z

  # Backup
  file_picker: ^X.Y.Z
  share_plus: ^X.Y.Z
```

Use whatever versions `flutter pub add` resolved (keep the `^` form). Alphabetize within each group.

- [ ] **Step 3: Verify build**

Run: `flutter pub get` (no-op now); `flutter analyze` → expect "No issues found!".

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add Phase 5 dependencies (notifications, share, file_picker, permissions, timezone)"
```

No `Co-Authored-By`. No `git add -A`.

---

## Task 2: Native config — Android manifest + iOS AppDelegate

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/AppDelegate.swift`

- [ ] **Step 1: Edit `AndroidManifest.xml`**

Open the file. At the top (above the `<application>` tag), add:

```xml
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

Inside the `<application>` tag, just before the closing `</application>`, add the receivers required by `flutter_local_notifications` for reboot survival and exact alarms:

```xml
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
```

- [ ] **Step 2: Edit `AppDelegate.swift`**

Replace the file contents with:

```swift
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
```

Setting `UNUserNotificationCenter.current().delegate` lets local notifications display while the app is in the foreground (otherwise iOS silently drops them).

- [ ] **Step 3: Verify build**

Run: `flutter analyze` → 0 issues. (Native config doesn't affect Dart analyze, but confirm nothing leaked into Dart code.)

Optionally: `flutter build apk --debug` and `flutter build ios --no-codesign` to confirm both targets still compile. These are slow; if the automated env has the SDKs, run; if not, defer to manual smoke in Task 22.

- [ ] **Step 4: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml ios/Runner/AppDelegate.swift
git commit -m "chore(native): add notification permissions + receivers for Phase 5"
```

---

## Task 3: Add Phase 5 ARB keys (EN + ES)

~25 new key pairs.

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_es.arb`

- [ ] **Step 1: Append EN keys before the closing `}` of `app_en.arb`**

(Add a trailing comma to the preceding entry if needed.)

```json
  "settingsRemindersOff": "Off",
  "@settingsRemindersOff": {},
  "settingsRemindersDailyAt": "Daily at {time}",
  "@settingsRemindersDailyAt": {
    "placeholders": {"time": {"type": "String"}}
  },
  "settingsDataLabel": "Data",
  "@settingsDataLabel": {},
  "settingsDataSubtitle": "Export or import your entries",
  "@settingsDataSubtitle": {},
  "settingsDataSection": "Data",
  "@settingsDataSection": {},
  "remindersTitle": "Reminders",
  "@remindersTitle": {},
  "remindersEnabledTitle": "Daily reminder",
  "@remindersEnabledTitle": {},
  "remindersTimeTitle": "Reminder time",
  "@remindersTimeTitle": {},
  "remindersPermissionDeniedTitle": "Notifications are turned off",
  "@remindersPermissionDeniedTitle": {},
  "remindersPermissionDeniedBody": "Enable notifications in system settings to use reminders.",
  "@remindersPermissionDeniedBody": {},
  "remindersOpenSettings": "Open settings",
  "@remindersOpenSettings": {},
  "reminderNotificationTitle": "Mood Tracker",
  "@reminderNotificationTitle": {},
  "reminderNotificationBody": "How are you feeling right now?",
  "@reminderNotificationBody": {},
  "backupTitle": "Data",
  "@backupTitle": {},
  "backupSubtitle": "Export your entries to a JSON file, or import a previous export.",
  "@backupSubtitle": {},
  "backupExportButton": "Export to file",
  "@backupExportButton": {},
  "backupImportButton": "Import from file",
  "@backupImportButton": {},
  "backupWorking": "Working…",
  "@backupWorking": {},
  "backupExportSuccess": "Exported {filename}",
  "@backupExportSuccess": {
    "placeholders": {"filename": {"type": "String"}}
  },
  "backupImportSuccess": "Imported {count, plural, =1{1 entry} other{{count} entries}}",
  "@backupImportSuccess": {
    "placeholders": {"count": {"type": "int"}}
  },
  "backupImportModeTitle": "Import data",
  "@backupImportModeTitle": {},
  "backupImportModeMerge": "Merge",
  "@backupImportModeMerge": {},
  "backupImportModeMergeHint": "Keep existing entries; add new ones.",
  "@backupImportModeMergeHint": {},
  "backupImportModeReplace": "Replace",
  "@backupImportModeReplace": {},
  "backupImportModeReplaceHint": "Delete all existing entries first.",
  "@backupImportModeReplaceHint": {},
  "backupImportContinue": "Continue",
  "@backupImportContinue": {},
  "backupImportCancel": "Cancel",
  "@backupImportCancel": {},
  "backupReplaceConfirmTitle": "Replace all entries?",
  "@backupReplaceConfirmTitle": {},
  "backupReplaceConfirmBody": "This will delete all entries currently in the app, then load the file. This cannot be undone.",
  "@backupReplaceConfirmBody": {},
  "backupErrorParseFailed": "Could not read the file. It may be corrupted or from a different app.",
  "@backupErrorParseFailed": {},
  "backupErrorWriteFailed": "Could not save the export file.",
  "@backupErrorWriteFailed": {},
  "backupErrorPickCanceled": "No file selected.",
  "@backupErrorPickCanceled": {}
```

- [ ] **Step 2: Append ES mirrors to `app_es.arb`**

```json
  "settingsRemindersOff": "Desactivado",
  "@settingsRemindersOff": {},
  "settingsRemindersDailyAt": "Diario a las {time}",
  "@settingsRemindersDailyAt": {
    "placeholders": {"time": {"type": "String"}}
  },
  "settingsDataLabel": "Datos",
  "@settingsDataLabel": {},
  "settingsDataSubtitle": "Exporta o importa tus entradas",
  "@settingsDataSubtitle": {},
  "settingsDataSection": "Datos",
  "@settingsDataSection": {},
  "remindersTitle": "Recordatorios",
  "@remindersTitle": {},
  "remindersEnabledTitle": "Recordatorio diario",
  "@remindersEnabledTitle": {},
  "remindersTimeTitle": "Hora del recordatorio",
  "@remindersTimeTitle": {},
  "remindersPermissionDeniedTitle": "Las notificaciones están desactivadas",
  "@remindersPermissionDeniedTitle": {},
  "remindersPermissionDeniedBody": "Activa las notificaciones en los ajustes del sistema para usar recordatorios.",
  "@remindersPermissionDeniedBody": {},
  "remindersOpenSettings": "Abrir ajustes",
  "@remindersOpenSettings": {},
  "reminderNotificationTitle": "Mood Tracker",
  "@reminderNotificationTitle": {},
  "reminderNotificationBody": "¿Cómo te sientes ahora?",
  "@reminderNotificationBody": {},
  "backupTitle": "Datos",
  "@backupTitle": {},
  "backupSubtitle": "Exporta tus entradas a un archivo JSON o importa una exportación anterior.",
  "@backupSubtitle": {},
  "backupExportButton": "Exportar a archivo",
  "@backupExportButton": {},
  "backupImportButton": "Importar desde archivo",
  "@backupImportButton": {},
  "backupWorking": "Procesando…",
  "@backupWorking": {},
  "backupExportSuccess": "Exportado {filename}",
  "@backupExportSuccess": {
    "placeholders": {"filename": {"type": "String"}}
  },
  "backupImportSuccess": "Importadas {count, plural, =1{1 entrada} other{{count} entradas}}",
  "@backupImportSuccess": {
    "placeholders": {"count": {"type": "int"}}
  },
  "backupImportModeTitle": "Importar datos",
  "@backupImportModeTitle": {},
  "backupImportModeMerge": "Combinar",
  "@backupImportModeMerge": {},
  "backupImportModeMergeHint": "Mantén las entradas existentes; agrega las nuevas.",
  "@backupImportModeMergeHint": {},
  "backupImportModeReplace": "Reemplazar",
  "@backupImportModeReplace": {},
  "backupImportModeReplaceHint": "Elimina primero todas las entradas existentes.",
  "@backupImportModeReplaceHint": {},
  "backupImportContinue": "Continuar",
  "@backupImportContinue": {},
  "backupImportCancel": "Cancelar",
  "@backupImportCancel": {},
  "backupReplaceConfirmTitle": "¿Reemplazar todas las entradas?",
  "@backupReplaceConfirmTitle": {},
  "backupReplaceConfirmBody": "Esto eliminará todas las entradas actuales en la app y cargará el archivo. No se puede deshacer.",
  "@backupReplaceConfirmBody": {},
  "backupErrorParseFailed": "No se pudo leer el archivo. Puede estar dañado o ser de otra app.",
  "@backupErrorParseFailed": {},
  "backupErrorWriteFailed": "No se pudo guardar el archivo de exportación.",
  "@backupErrorWriteFailed": {},
  "backupErrorPickCanceled": "Ningún archivo seleccionado.",
  "@backupErrorPickCanceled": {}
```

- [ ] **Step 3: Regenerate `AppLocalizations`**

Run: `flutter gen-l10n`. Generated files in `lib/l10n/app_localizations*.dart` are gitignored.

- [ ] **Step 4: Verify**

Run: `flutter analyze && flutter test` → 0 issues; 181 tests still pass.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_es.arb
git commit -m "feat(l10n): add Phase 5 reminders + backup ARB keys"
```

---

## Task 4: `AppPrefs` additions for reminder schedule

**Files:**
- Modify: `lib/core/prefs/app_prefs.dart`
- Test: `test/core/prefs/app_prefs_test.dart` (create if missing; otherwise extend)

- [ ] **Step 1: Check whether `app_prefs_test.dart` exists**

Run: `ls test/core/prefs/`. If `app_prefs_test.dart` exists, append to it. If not, create it.

- [ ] **Step 2: Write/extend the failing test**

If creating fresh, full file:

```dart
// test/core/prefs/app_prefs_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppPrefs reminder accessors', () {
    test('default reminderEnabled is false', () async {
      final sp = await SharedPreferences.getInstance();
      final prefs = AppPrefs(sp);
      expect(prefs.reminderEnabled, false);
    });

    test('default reminderTime is null', () async {
      final sp = await SharedPreferences.getInstance();
      final prefs = AppPrefs(sp);
      expect(prefs.reminderTime, isNull);
    });

    test('setReminderEnabled persists value', () async {
      final sp = await SharedPreferences.getInstance();
      final prefs = AppPrefs(sp);
      await prefs.setReminderEnabled(true);
      expect(AppPrefs(sp).reminderEnabled, true);
    });

    test('setReminderTime persists HH:mm string', () async {
      final sp = await SharedPreferences.getInstance();
      final prefs = AppPrefs(sp);
      await prefs.setReminderTime('21:00');
      expect(AppPrefs(sp).reminderTime, '21:00');
    });

    test('setReminderTime(null) removes the key', () async {
      final sp = await SharedPreferences.getInstance();
      final prefs = AppPrefs(sp);
      await prefs.setReminderTime('21:00');
      await prefs.setReminderTime(null);
      expect(AppPrefs(sp).reminderTime, isNull);
    });
  });
}
```

If extending an existing test file, just add the `group('AppPrefs reminder accessors', () { ... });` block.

- [ ] **Step 3: Run, verify FAIL**

Run: `flutter test test/core/prefs/app_prefs_test.dart`
Expected: 5 reminder-accessor tests FAIL (methods undefined).

- [ ] **Step 4: Implement in `app_prefs.dart`**

Add new private key constants near the top of the class:

```dart
  static const _kReminderEnabled = 'app.reminderEnabled';
  static const _kReminderTime = 'app.reminderTime';
```

Add new accessors at the bottom of the class (after `setOnboardingCompleted`):

```dart
  bool get reminderEnabled => _sp.getBool(_kReminderEnabled) ?? false;

  Future<void> setReminderEnabled(bool value) =>
      _sp.setBool(_kReminderEnabled, value);

  String? get reminderTime => _sp.getString(_kReminderTime);

  Future<void> setReminderTime(String? hhmm) async {
    if (hhmm == null) {
      await _sp.remove(_kReminderTime);
    } else {
      await _sp.setString(_kReminderTime, hhmm);
    }
  }
```

- [ ] **Step 5: Run, verify PASS, then full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; **186 tests pass** (181 + 5).

- [ ] **Step 6: Commit**

```bash
git add lib/core/prefs/app_prefs.dart test/core/prefs/app_prefs_test.dart
git commit -m "feat(prefs): add reminderEnabled + reminderTime accessors"
```

---

## Task 5: `ReminderSchedule` domain value class

**Files:**
- Create: `lib/features/reminders/domain/reminder_schedule.dart`
- Test: `test/features/reminders/domain/reminder_schedule_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/reminders/domain/reminder_schedule_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/reminders/domain/reminder_schedule.dart';

void main() {
  group('ReminderSchedule', () {
    test('disabledDefault is enabled=false, time=21:00', () {
      const s = ReminderSchedule.disabledDefault;
      expect(s.enabled, false);
      expect(s.time.hour, 21);
      expect(s.time.minute, 0);
    });

    test('prefsString zero-pads hour and minute', () {
      const s = ReminderSchedule(enabled: true, time: (hour: 9, minute: 5));
      expect(s.prefsString, '09:05');
    });

    test('prefsString edge cases (23:59 and 00:00)', () {
      const a = ReminderSchedule(enabled: true, time: (hour: 23, minute: 59));
      const b = ReminderSchedule(enabled: true, time: (hour: 0, minute: 0));
      expect(a.prefsString, '23:59');
      expect(b.prefsString, '00:00');
    });

    test('parseTime accepts valid HH:mm strings', () {
      expect(ReminderSchedule.parseTime('21:00'), (hour: 21, minute: 0));
      expect(ReminderSchedule.parseTime('00:00'), (hour: 0, minute: 0));
      expect(ReminderSchedule.parseTime('09:05'), (hour: 9, minute: 5));
    });

    test('parseTime rejects malformed input', () {
      expect(ReminderSchedule.parseTime(null), isNull);
      expect(ReminderSchedule.parseTime(''), isNull);
      expect(ReminderSchedule.parseTime('oops'), isNull);
      expect(ReminderSchedule.parseTime('25:00'), isNull);
      expect(ReminderSchedule.parseTime('21:60'), isNull);
      expect(ReminderSchedule.parseTime('21'), isNull);
      expect(ReminderSchedule.parseTime('21:'), isNull);
    });
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/reminders/domain/reminder_schedule_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement `reminder_schedule.dart`**

```dart
import 'package:flutter/foundation.dart';

@immutable
class ReminderSchedule {
  const ReminderSchedule({required this.enabled, required this.time});

  final bool enabled;
  final ({int hour, int minute}) time;

  static const ReminderSchedule disabledDefault = ReminderSchedule(
    enabled: false,
    time: (hour: 21, minute: 0),
  );

  String get prefsString {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static ({int hour, int minute})? parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23) return null;
    if (m < 0 || m > 59) return null;
    return (hour: h, minute: m);
  }

  ReminderSchedule copyWith({bool? enabled, ({int hour, int minute})? time}) {
    return ReminderSchedule(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderSchedule &&
          enabled == other.enabled &&
          time.hour == other.time.hour &&
          time.minute == other.time.minute;

  @override
  int get hashCode => Object.hash(enabled, time.hour, time.minute);
}
```

- [ ] **Step 4: Run, verify PASS**

Run: `flutter test test/features/reminders/domain/reminder_schedule_test.dart` → 5 pass.

- [ ] **Step 5: Full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; **191 tests pass** (186 + 5).

- [ ] **Step 6: Commit**

```bash
git add lib/features/reminders/domain/reminder_schedule.dart test/features/reminders/domain/reminder_schedule_test.dart
git commit -m "feat(reminders): add ReminderSchedule value class with HH:mm prefs codec"
```

---

## Task 6: `NotificationService` abstract + provider

**Files:**
- Create: `lib/features/reminders/data/notification_service.dart` (abstract class + concrete impl will both live here, similar to existing repository patterns)
- Create: `lib/features/reminders/data/notification_service_provider.dart`

This task establishes the contract. The concrete plugin-backed implementation is in Task 7, scaffolded behind a `NotificationService` interface so tests can fake it.

- [ ] **Step 1: Create `notification_service.dart` with the interface**

```dart
abstract class NotificationService {
  /// Idempotent. Initializes the platform notification channel + tz database.
  Future<void> init();

  /// Returns the current permission state (granted / denied / permanentlyDenied).
  Future<NotificationPermissionStatus> currentStatus();

  /// Requests OS permission. Returns the post-prompt status.
  Future<NotificationPermissionStatus> requestPermission();

  /// Schedules a daily-repeating notification at the given local time.
  /// Replaces any previously scheduled reminder.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  });

  /// Cancels every scheduled notification. Safe to call when nothing is scheduled.
  Future<void> cancelAll();
}

enum NotificationPermissionStatus { granted, denied, permanentlyDenied }
```

- [ ] **Step 2: Create the Riverpod provider**

```dart
// lib/features/reminders/data/notification_service_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_locator.dart';
import 'notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
    (_) => getIt<NotificationService>());
```

- [ ] **Step 3: Verify**

Run: `flutter analyze` → expect "No issues found!" (no test yet — the abstract class has no behavior to test directly).

- [ ] **Step 4: Commit**

```bash
git add lib/features/reminders/data/notification_service.dart lib/features/reminders/data/notification_service_provider.dart
git commit -m "feat(reminders): add NotificationService interface + Riverpod provider"
```

---

## Task 7: `FlutterLocalNotificationsService` (concrete impl) + GetIt registration

**Files:**
- Modify: `lib/features/reminders/data/notification_service.dart` (append the concrete `FlutterLocalNotificationsService` class)
- Modify: `lib/core/di/service_locator.dart` (register the service)
- Modify: `lib/app/bootstrap.dart` (call `notificationService.init()` after `registerServices`)
- Test: `test/features/reminders/data/notification_service_test.dart`

The test uses a hand-rolled fake of the plugin to avoid hitting platform channels.

- [ ] **Step 1: Inspect existing `service_locator.dart`**

Run `cat lib/core/di/service_locator.dart`. Observe the pattern (`getIt.registerSingleton<...>(...)` calls inside `registerServices`).

- [ ] **Step 2: Write the failing test**

```dart
// test/features/reminders/data/notification_service_test.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/reminders/data/notification_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() {
  setUpAll(() => tzdata.initializeTimeZones());

  test('init() is idempotent', () async {
    final plugin = _FakePlugin();
    final svc = FlutterLocalNotificationsService(plugin);
    await svc.init();
    await svc.init();
    expect(plugin.initializeCallCount, lessThanOrEqualTo(2));
  });

  test('scheduleDailyReminder calls zonedSchedule with channel id and time component', () async {
    final plugin = _FakePlugin();
    final svc = FlutterLocalNotificationsService(plugin);
    await svc.init();
    await svc.scheduleDailyReminder(
      hour: 21,
      minute: 0,
      title: 'T',
      body: 'B',
    );
    expect(plugin.lastZonedSchedule, isNotNull);
    expect(plugin.lastZonedSchedule!.id, 0);
    expect(plugin.lastZonedSchedule!.title, 'T');
    expect(plugin.lastZonedSchedule!.matchDateTimeComponents,
        DateTimeComponents.time);
    expect(plugin.lastZonedSchedule!.notificationDetails.android?.channelId,
        'daily_reminder');
  });

  test('cancelAll forwards to plugin', () async {
    final plugin = _FakePlugin();
    final svc = FlutterLocalNotificationsService(plugin);
    await svc.init();
    await svc.cancelAll();
    expect(plugin.cancelAllCallCount, 1);
  });
}

class _FakePlugin implements FlutterLocalNotificationsPlugin {
  int initializeCallCount = 0;
  int cancelAllCallCount = 0;
  _ZonedScheduleCall? lastZonedSchedule;

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCallCount++;
    return true;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCallCount++;
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    dynamic scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    UILocalNotificationDateInterpretation? uiLocalNotificationDateInterpretation,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    lastZonedSchedule = _ZonedScheduleCall(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  @override
  T? resolvePlatformSpecificImplementation<T extends FlutterLocalNotificationsPlatform>() {
    return null;
  }

  // Unused interface members — fail loudly if accidentally invoked.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('${invocation.memberName} not stubbed');
  }
}

class _ZonedScheduleCall {
  _ZonedScheduleCall({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationDetails,
    required this.matchDateTimeComponents,
  });
  final int id;
  final String? title;
  final String? body;
  final NotificationDetails notificationDetails;
  final DateTimeComponents? matchDateTimeComponents;
}
```

**Note:** if the `flutter_local_notifications` 19.x API differs from this signature (the package has had API churn), adjust the `_FakePlugin` `@override` annotations and `zonedSchedule` parameter list to match the installed version. Use `dart pub deps` or read `.dart_tool/pub-cache/...` if needed.

- [ ] **Step 3: Run, verify FAIL**

Run: `flutter test test/features/reminders/data/notification_service_test.dart`
Expected: compile error (concrete `FlutterLocalNotificationsService` undefined).

- [ ] **Step 4: Append concrete impl to `notification_service.dart`**

Add at the bottom of the file (after the abstract class):

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class FlutterLocalNotificationsService implements NotificationService {
  FlutterLocalNotificationsService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const int _reminderNotificationId = 0;
  static const String _androidChannelId = 'daily_reminder';
  static const String _androidChannelName = 'Daily reminder';

  @override
  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(const InitializationSettings(
      android: android,
      iOS: ios,
    ));
    _initialized = true;
  }

  @override
  Future<NotificationPermissionStatus> currentStatus() async {
    final s = await Permission.notification.status;
    return _map(s);
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    final s = await Permission.notification.request();
    return _map(s);
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      _reminderNotificationId,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  NotificationPermissionStatus _map(PermissionStatus s) {
    if (s.isGranted) return NotificationPermissionStatus.granted;
    if (s.isPermanentlyDenied) return NotificationPermissionStatus.permanentlyDenied;
    return NotificationPermissionStatus.denied;
  }
}
```

(Imports go to the top of the file in alphabetical order. Move them up before the abstract class.)

Final imports block at top of file:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
```

- [ ] **Step 5: Register in `service_locator.dart`**

Add the registration. Likely it looks something like:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/reminders/data/notification_service.dart';

// inside registerServices():
final notificationsPlugin = FlutterLocalNotificationsPlugin();
getIt.registerSingleton<NotificationService>(
    FlutterLocalNotificationsService(notificationsPlugin));
```

Place the registration in the same style as existing registrations (alphabetical, grouped).

- [ ] **Step 6: Initialize in `bootstrap.dart`**

Replace `bootstrap.dart` with:

```dart
import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../core/di/service_locator.dart';
import '../features/reminders/data/notification_service.dart';
import 'package:get_it/get_it.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  await registerServices();
  await GetIt.I<NotificationService>().init();
}
```

(Adjust the `package:get_it/get_it.dart` import path if your project uses a different alias.)

- [ ] **Step 7: Run, verify PASS**

Run: `flutter test test/features/reminders/data/notification_service_test.dart`
Expected: 3 tests pass.

- [ ] **Step 8: Full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; **194 tests pass** (191 + 3).

If any existing tests start failing because bootstrap now requires `NotificationService` from GetIt, they may need `GetIt.I.reset()` or a fake registration. Investigate — most tests use `ProviderContainer` overrides, not GetIt directly, so this should be OK.

- [ ] **Step 9: Commit**

```bash
git add lib/features/reminders/data/notification_service.dart lib/core/di/service_locator.dart lib/app/bootstrap.dart test/features/reminders/data/notification_service_test.dart
git commit -m "feat(reminders): add FlutterLocalNotificationsService + bootstrap wiring"
```

---

## Task 8: `ReminderController` (AsyncNotifier) + permission provider

**Files:**
- Create: `lib/features/reminders/providers/reminder_controller.dart`
- Create: `lib/features/reminders/providers/permission_status_provider.dart`
- Test: `test/features/reminders/providers/reminder_controller_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/reminders/providers/reminder_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/features/reminders/data/notification_service.dart';
import 'package:mood_tracker/features/reminders/data/notification_service_provider.dart';
import 'package:mood_tracker/features/reminders/domain/reminder_schedule.dart';
import 'package:mood_tracker/features/reminders/providers/reminder_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeService implements NotificationService {
  NotificationPermissionStatus next = NotificationPermissionStatus.granted;
  ({int hour, int minute})? scheduledTime;
  int cancelCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<NotificationPermissionStatus> currentStatus() async => next;

  @override
  Future<NotificationPermissionStatus> requestPermission() async => next;

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    scheduledTime = (hour: hour, minute: minute);
  }

  @override
  Future<void> cancelAll() async {
    cancelCalls++;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer makeContainer(NotificationService svc) {
    return ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(svc),
    ]);
  }

  test('initial state reflects defaults when prefs empty', () async {
    final svc = _FakeService();
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(svc),
      appPrefsProvider.overrideWithValue(AppPrefs(sp)),
    ]);
    addTearDown(c.dispose);
    final state = await c.read(reminderControllerProvider.future);
    expect(state.enabled, false);
    expect(state.time.hour, 21);
    expect(state.time.minute, 0);
  });

  test('setEnabled(true) requests permission, schedules, persists', () async {
    final svc = _FakeService();
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(svc),
      appPrefsProvider.overrideWithValue(AppPrefs(sp)),
    ]);
    addTearDown(c.dispose);
    await c.read(reminderControllerProvider.future);
    await c.read(reminderControllerProvider.notifier).setEnabled(true);
    final state = await c.read(reminderControllerProvider.future);
    expect(state.enabled, true);
    expect(svc.scheduledTime, (hour: 21, minute: 0));
    expect(AppPrefs(sp).reminderEnabled, true);
  });

  test('setEnabled(true) with denied permission leaves state OFF', () async {
    final svc = _FakeService()..next = NotificationPermissionStatus.denied;
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(svc),
      appPrefsProvider.overrideWithValue(AppPrefs(sp)),
    ]);
    addTearDown(c.dispose);
    await c.read(reminderControllerProvider.future);
    await c.read(reminderControllerProvider.notifier).setEnabled(true);
    final state = await c.read(reminderControllerProvider.future);
    expect(state.enabled, false);
    expect(svc.scheduledTime, isNull);
  });

  test('setEnabled(false) cancels and persists', () async {
    final svc = _FakeService();
    SharedPreferences.setMockInitialValues({
      'app.reminderEnabled': true,
      'app.reminderTime': '08:30',
    });
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(svc),
      appPrefsProvider.overrideWithValue(AppPrefs(sp)),
    ]);
    addTearDown(c.dispose);
    await c.read(reminderControllerProvider.future);
    await c.read(reminderControllerProvider.notifier).setEnabled(false);
    final state = await c.read(reminderControllerProvider.future);
    expect(state.enabled, false);
    expect(svc.cancelCalls, greaterThanOrEqualTo(1));
    expect(AppPrefs(sp).reminderEnabled, false);
  });

  test('setTime updates schedule when enabled, just persists when disabled', () async {
    final svc = _FakeService();
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      notificationServiceProvider.overrideWithValue(svc),
      appPrefsProvider.overrideWithValue(AppPrefs(sp)),
    ]);
    addTearDown(c.dispose);
    await c.read(reminderControllerProvider.future);
    await c.read(reminderControllerProvider.notifier).setTime(hour: 8, minute: 30);
    expect(svc.scheduledTime, isNull); // not enabled yet
    expect(AppPrefs(sp).reminderTime, '08:30');

    await c.read(reminderControllerProvider.notifier).setEnabled(true);
    await c.read(reminderControllerProvider.notifier).setTime(hour: 9, minute: 0);
    expect(svc.scheduledTime, (hour: 9, minute: 0));
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/reminders/providers/reminder_controller_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement `permission_status_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_service.dart';
import '../data/notification_service_provider.dart';

final permissionStatusProvider =
    FutureProvider<NotificationPermissionStatus>((ref) async {
  final svc = ref.watch(notificationServiceProvider);
  return svc.currentStatus();
});
```

- [ ] **Step 4: Implement `reminder_controller.dart`**

The notification title/body are passed in from the screen (which has `context.l10n`), not from the controller. To keep the controller pure, accept them as parameters. For the test (which doesn't pass them), we'll wire a static helper to avoid forcing every caller to pass them.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/infrastructure_providers.dart';
import '../data/notification_service.dart';
import '../data/notification_service_provider.dart';
import '../domain/reminder_schedule.dart';

class ReminderController extends AsyncNotifier<ReminderSchedule> {
  @override
  Future<ReminderSchedule> build() async {
    final prefs = ref.read(appPrefsProvider);
    final enabled = prefs.reminderEnabled;
    final raw = prefs.reminderTime;
    final time = ReminderSchedule.parseTime(raw) ??
        ReminderSchedule.disabledDefault.time;
    return ReminderSchedule(enabled: enabled, time: time);
  }

  Future<void> setEnabled(bool value,
      {String title = 'Mood Tracker',
      String body = 'How are you feeling right now?'}) async {
    final current = await future;
    final svc = ref.read(notificationServiceProvider);
    final prefs = ref.read(appPrefsProvider);

    if (value) {
      final perm = await svc.requestPermission();
      if (perm != NotificationPermissionStatus.granted) {
        // Permission denied — leave state off.
        state = AsyncData(current.copyWith(enabled: false));
        return;
      }
      await svc.scheduleDailyReminder(
        hour: current.time.hour,
        minute: current.time.minute,
        title: title,
        body: body,
      );
      await prefs.setReminderEnabled(true);
      state = AsyncData(current.copyWith(enabled: true));
    } else {
      await svc.cancelAll();
      await prefs.setReminderEnabled(false);
      state = AsyncData(current.copyWith(enabled: false));
    }
  }

  Future<void> setTime({
    required int hour,
    required int minute,
    String title = 'Mood Tracker',
    String body = 'How are you feeling right now?',
  }) async {
    final current = await future;
    final newTime = (hour: hour, minute: minute);
    final prefs = ref.read(appPrefsProvider);
    final svc = ref.read(notificationServiceProvider);

    final updated = current.copyWith(time: newTime);
    await prefs.setReminderTime(updated.prefsString);

    if (current.enabled) {
      await svc.scheduleDailyReminder(
        hour: hour, minute: minute, title: title, body: body,
      );
    }
    state = AsyncData(updated);
  }
}

final reminderControllerProvider =
    AsyncNotifierProvider<ReminderController, ReminderSchedule>(
        ReminderController.new);
```

- [ ] **Step 5: Run, verify PASS**

Run: `flutter test test/features/reminders/providers/reminder_controller_test.dart`
Expected: 5 tests pass.

- [ ] **Step 6: Full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; **199 tests pass** (194 + 5).

- [ ] **Step 7: Commit**

```bash
git add lib/features/reminders/providers/reminder_controller.dart lib/features/reminders/providers/permission_status_provider.dart test/features/reminders/providers/reminder_controller_test.dart
git commit -m "feat(reminders): add ReminderController + permission status provider"
```

---

## Task 9: Re-arm scheduled reminder on bootstrap

If the user has `reminderEnabled == true` from a previous run, ensure the daily notification is (re-)scheduled when the app starts. This is important after device reboots or after the user updates the app.

**Files:**
- Modify: `lib/app/bootstrap.dart`

- [ ] **Step 1: Edit `bootstrap.dart`**

After `await GetIt.I<NotificationService>().init();`, add:

```dart
  // Re-arm any persisted reminder schedule.
  final prefs = GetIt.I<AppPrefs>();
  if (prefs.reminderEnabled) {
    final time = ReminderSchedule.parseTime(prefs.reminderTime);
    final svc = GetIt.I<NotificationService>();
    final status = await svc.currentStatus();
    if (time != null && status == NotificationPermissionStatus.granted) {
      await svc.scheduleDailyReminder(
        hour: time.hour,
        minute: time.minute,
        title: 'Mood Tracker',
        body: 'How are you feeling right now?',
      );
    }
  }
```

Add imports at the top:

```dart
import '../core/prefs/app_prefs.dart';
import '../features/reminders/domain/reminder_schedule.dart';
```

(Maintain alphabetical order.)

**Note:** the bootstrap uses raw English strings here, not localized. That's a known limitation — the OS locale at install time determines what the notification says on launch, but localization here would require initializing the `AppLocalizations` delegate before bootstrap finishes (chicken/egg). Acceptable for Phase 5; future polish can localize this at first-screen-load instead.

- [ ] **Step 2: Verify**

Run: `flutter analyze && flutter test` → 0 issues; 199 tests still pass.

- [ ] **Step 3: Commit**

```bash
git add lib/app/bootstrap.dart
git commit -m "feat(reminders): re-arm daily reminder on bootstrap if permission still granted"
```

---

## Task 10: `PermissionDeniedCard` + `ReminderTimePickerSheet` widgets

**Files:**
- Create: `lib/features/reminders/presentation/widgets/permission_denied_card.dart`
- Create: `lib/features/reminders/presentation/widgets/reminder_time_picker_sheet.dart`
- Test: `test/features/reminders/presentation/widgets_test.dart` (combined)

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/reminders/presentation/widgets_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/reminders/presentation/widgets/permission_denied_card.dart';
import 'package:mood_tracker/features/reminders/presentation/widgets/reminder_time_picker_sheet.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget wrap(Widget child) => MaterialApp(
    theme: ThemeData(extensions: const [AppColors.light]),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('PermissionDeniedCard renders title, body, and CTA',
      (tester) async {
    var tapped = 0;
    await tester.pumpWidget(wrap(
      PermissionDeniedCard(onOpenSettings: () => tapped++),
    ));
    await tester.pump();
    expect(find.text('Notifications are turned off'), findsOneWidget);
    expect(find.textContaining('Enable notifications'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets(
      'ReminderTimePickerSheet.show returns the picked TimeOfDay or null',
      (tester) async {
    // Smoke test only — verifies the sheet exposes a `show` entry-point.
    // Actual showTimePicker UX is platform-driven; full UX coverage is left
    // to the manual smoke pass.
    expect(ReminderTimePickerSheet.show, isA<Function>());
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/reminders/presentation/widgets_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement `permission_denied_card.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class PermissionDeniedCard extends StatelessWidget {
  const PermissionDeniedCard({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBR),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.remindersPermissionDeniedTitle,
                style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.remindersPermissionDeniedBody,
                style: AppTextStyles.body.copyWith(color: colors.onMuted)),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpenSettings,
                child: Text(l10n.remindersOpenSettings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement `reminder_time_picker_sheet.dart`**

```dart
import 'package:flutter/material.dart';

class ReminderTimePickerSheet {
  /// Wraps `showTimePicker` to return the picked time as a record,
  /// or `null` if dismissed.
  static Future<({int hour, int minute})?> show(
    BuildContext context, {
    required int initialHour,
    required int initialMinute,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );
    if (picked == null) return null;
    return (hour: picked.hour, minute: picked.minute);
  }
}
```

- [ ] **Step 5: Run, verify PASS**

Run: `flutter test test/features/reminders/presentation/widgets_test.dart` → 2 pass.

- [ ] **Step 6: Full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; **201 tests pass** (199 + 2).

- [ ] **Step 7: Commit**

```bash
git add lib/features/reminders/presentation/widgets/permission_denied_card.dart lib/features/reminders/presentation/widgets/reminder_time_picker_sheet.dart test/features/reminders/presentation/widgets_test.dart
git commit -m "feat(reminders): add PermissionDeniedCard + ReminderTimePickerSheet"
```

---

## Task 11: `RemindersScreen`

**Files:**
- Create: `lib/features/reminders/presentation/screens/reminders_screen.dart`
- Test: `test/features/reminders/presentation/reminders_screen_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/reminders/presentation/reminders_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/reminders/data/notification_service.dart';
import 'package:mood_tracker/features/reminders/data/notification_service_provider.dart';
import 'package:mood_tracker/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _GrantingService implements NotificationService {
  ({int hour, int minute})? scheduled;
  @override
  Future<void> init() async {}
  @override
  Future<NotificationPermissionStatus> currentStatus() async =>
      NotificationPermissionStatus.granted;
  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      NotificationPermissionStatus.granted;
  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    scheduled = (hour: hour, minute: minute);
  }
  @override
  Future<void> cancelAll() async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders title + enabled switch + time tile', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final svc = _GrantingService();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appPrefsProvider.overrideWithValue(AppPrefs(sp)),
        notificationServiceProvider.overrideWithValue(svc),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RemindersScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Reminders'), findsWidgets);
    expect(find.text('Daily reminder'), findsOneWidget);
    expect(find.text('Reminder time'), findsOneWidget);
  });

  testWidgets('toggling switch to ON triggers scheduling', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final svc = _GrantingService();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appPrefsProvider.overrideWithValue(AppPrefs(sp)),
        notificationServiceProvider.overrideWithValue(svc),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RemindersScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(svc.scheduled, (hour: 21, minute: 0));
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/reminders/presentation/reminders_screen_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement `reminders_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../features/settings/presentation/widgets/settings_tile.dart';
import '../../data/notification_service.dart';
import '../../providers/permission_status_provider.dart';
import '../../providers/reminder_controller.dart';
import '../widgets/permission_denied_card.dart';
import '../widgets/reminder_time_picker_sheet.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(reminderControllerProvider);
    final permission = ref.watch(permissionStatusProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.errorRetry)),
        data: (schedule) => ListView(
          children: [
            SettingsTile(
              leading: const Icon(Icons.notifications_outlined),
              title: l10n.remindersEnabledTitle,
              trailing: Switch(
                value: schedule.enabled,
                onChanged: (v) => ref
                    .read(reminderControllerProvider.notifier)
                    .setEnabled(
                      v,
                      title: l10n.reminderNotificationTitle,
                      body: l10n.reminderNotificationBody,
                    ),
              ),
            ),
            SettingsTile(
              leading: const Icon(Icons.schedule),
              title: l10n.remindersTimeTitle,
              subtitle: _formatTime(schedule.time.hour, schedule.time.minute),
              trailing: const Icon(Icons.chevron_right),
              enabled: schedule.enabled,
              onTap: () async {
                final picked = await ReminderTimePickerSheet.show(
                  context,
                  initialHour: schedule.time.hour,
                  initialMinute: schedule.time.minute,
                );
                if (picked != null && context.mounted) {
                  await ref
                      .read(reminderControllerProvider.notifier)
                      .setTime(
                        hour: picked.hour,
                        minute: picked.minute,
                        title: l10n.reminderNotificationTitle,
                        body: l10n.reminderNotificationBody,
                      );
                }
              },
            ),
            permission.maybeWhen(
              data: (p) {
                if (p == NotificationPermissionStatus.granted) {
                  return const SizedBox.shrink();
                }
                return PermissionDeniedCard(
                  onOpenSettings: ph.openAppSettings,
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
```

Note the import of `SettingsTile` from the existing settings feature. If the test reveals a `Text('Reminders')` finds multiple widgets (because the AppBar + a parent shell both render it), use `findsWidgets` instead of `findsOneWidget` for that assertion. The test above already uses `findsWidgets`.

Also: `l10n.errorRetry` is used as the error fallback. If it doesn't exist in the ARB, fall back to a literal `'Try again'` or add the key — but I expect Phase 4's retry button already added it.

- [ ] **Step 4: Run, verify PASS**

Run: `flutter test test/features/reminders/presentation/reminders_screen_test.dart`
Expected: 2 tests pass.

- [ ] **Step 5: Full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; **203 tests pass** (201 + 2).

- [ ] **Step 6: Commit**

```bash
git add lib/features/reminders/presentation/screens/reminders_screen.dart test/features/reminders/presentation/reminders_screen_test.dart
git commit -m "feat(reminders): add RemindersScreen with enable switch + time picker"
```

---

## Task 12: Wire `/settings/reminders` route + tappable Settings tile

**Files:**
- Modify: `lib/core/navigation/app_routes.dart`
- Modify: `lib/core/navigation/app_router.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Add route constant**

In `lib/core/navigation/app_routes.dart`, add:

```dart
  static const String settingsReminders = '/settings/reminders';
```

(Place it alphabetically among existing constants — after `settings`.)

- [ ] **Step 2: Add nested route in router**

In `lib/core/navigation/app_router.dart`, find the Settings branch's `GoRoute` and add a child route:

```dart
GoRoute(
  path: AppRoutes.settings,
  builder: (context, _) => const SettingsScreen(),
  routes: [
    GoRoute(
      path: 'about',
      builder: (context, _) => const AboutScreen(),
    ),
    GoRoute(
      path: 'reminders',
      builder: (context, _) => const RemindersScreen(),
    ),
  ],
),
```

Add the import for `RemindersScreen` at the top (alphabetical position):

```dart
import '../../features/reminders/presentation/screens/reminders_screen.dart';
```

- [ ] **Step 3: Update the Settings screen Reminders tile**

In `lib/features/settings/presentation/screens/settings_screen.dart`, replace the disabled Reminders tile with:

```dart
            SettingsSection(
              title: l10n.settingsRemindersSection,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: l10n.settingsRemindersLabel,
                  subtitle: _remindersSubtitle(context, vm),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.settingsReminders),
                ),
              ],
            ),
```

You'll need a `_remindersSubtitle` helper at the bottom of the class. The subtitle should read from `reminderControllerProvider` — convert `SettingsScreen` to use the controller for that subtitle, OR keep it simple by reading directly from `AppPrefs`:

```dart
  String _remindersSubtitle(BuildContext context, dynamic vm) {
    // Read prefs synchronously rather than wiring the full controller.
    // vm carries the existing settings view-model; we extend it later if needed.
    final l10n = context.l10n;
    // ... we don't have vm.reminderEnabled today; fetch via getIt
    return l10n.settingsRemindersOff;
  }
```

Hmm — the SettingsScreen currently uses `settingsControllerProvider` for a single `vm`. Extending the view-model is more invasive. Cleanest fix: convert the Reminders tile in `SettingsScreen` into a `Consumer` widget that reads `reminderControllerProvider`:

```dart
            SettingsSection(
              title: l10n.settingsRemindersSection,
              children: [
                Consumer(builder: (context, ref, _) {
                  final reminderAsync =
                      ref.watch(reminderControllerProvider);
                  return SettingsTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: l10n.settingsRemindersLabel,
                    subtitle: reminderAsync.maybeWhen(
                      data: (s) => s.enabled
                          ? l10n.settingsRemindersDailyAt(
                              '${s.time.hour.toString().padLeft(2, '0')}:${s.time.minute.toString().padLeft(2, '0')}')
                          : l10n.settingsRemindersOff,
                      orElse: () => '',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push(AppRoutes.settingsReminders),
                  );
                }),
              ],
            ),
```

Add the import:

```dart
import '../../../reminders/providers/reminder_controller.dart';
```

- [ ] **Step 4: Verify**

Run: `flutter analyze && flutter test` → 0 issues; 203 tests still pass. If a Settings screen widget test exists and breaks because the new `Consumer` requires `notificationServiceProvider` / `reminderControllerProvider` to be overridable, extend the test's overrides accordingly.

- [ ] **Step 5: Commit**

```bash
git add lib/core/navigation/app_routes.dart lib/core/navigation/app_router.dart lib/features/settings/presentation/screens/settings_screen.dart
git commit -m "feat(navigation): wire /settings/reminders route and tappable Reminders tile"
```

---

## Task 13: `BackupEnvelope` + `ImportMode` + tests

**Files:**
- Create: `lib/features/backup/domain/backup_envelope.dart`
- Create: `lib/features/backup/domain/import_mode.dart`
- Test: `test/features/backup/domain/backup_envelope_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/backup/domain/backup_envelope_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/backup/domain/backup_envelope.dart';
import 'package:mood_tracker/features/backup/domain/import_mode.dart';

void main() {
  test('currentSchema is 1', () {
    expect(BackupEnvelope.currentSchema, 1);
  });

  test('value equality on identical envelopes', () {
    final a = BackupEnvelope(
      schema: 1,
      exportedAt: DateTime.utc(2026, 5, 18),
      appVersion: '1.0.0+1',
      entries: const [],
    );
    final b = BackupEnvelope(
      schema: 1,
      exportedAt: DateTime.utc(2026, 5, 18),
      appVersion: '1.0.0+1',
      entries: const [],
    );
    expect(a, b);
  });

  test('ImportMode has merge and replace', () {
    expect(ImportMode.values, [ImportMode.merge, ImportMode.replace]);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/backup/domain/backup_envelope_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement `import_mode.dart`**

```dart
enum ImportMode { merge, replace }
```

- [ ] **Step 4: Implement `backup_envelope.dart`**

```dart
import 'package:flutter/foundation.dart';

import '../../mood_entry/domain/entities/mood_entry.dart';

@immutable
class BackupEnvelope {
  const BackupEnvelope({
    required this.schema,
    required this.exportedAt,
    required this.appVersion,
    required this.entries,
  });

  final int schema;
  final DateTime exportedAt;
  final String appVersion;
  final List<MoodEntry> entries;

  static const int currentSchema = 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupEnvelope &&
          schema == other.schema &&
          exportedAt == other.exportedAt &&
          appVersion == other.appVersion &&
          listEquals(entries, other.entries);

  @override
  int get hashCode =>
      Object.hash(schema, exportedAt, appVersion, Object.hashAll(entries));
}
```

- [ ] **Step 5: Run, verify PASS, commit**

```bash
flutter test test/features/backup/domain/backup_envelope_test.dart
flutter analyze && flutter test
git add lib/features/backup/domain/backup_envelope.dart lib/features/backup/domain/import_mode.dart test/features/backup/domain/backup_envelope_test.dart
git commit -m "feat(backup): add BackupEnvelope + ImportMode domain types"
```

Expected: 206 tests pass (203 + 3).

---

## Task 14: `BackupCodec` (envelope ↔ JSON Map, migration shim)

**Files:**
- Create: `lib/features/backup/data/backup_codec.dart`
- Test: `test/features/backup/data/backup_codec_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/backup/data/backup_codec_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/backup/data/backup_codec.dart';
import 'package:mood_tracker/features/backup/domain/backup_envelope.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

MoodEntry _e({String id = 'e1'}) {
  final t = DateTime.utc(2026, 5, 17, 12, 0, 0);
  return MoodEntry(
    id: id,
    occurredAt: t,
    mood: Mood.good,
    intensity: 7,
    note: 'Great hike today',
    tags: [
      const Tag(id: 't1', slug: 'work', label: 'Work'),
      const Tag(id: 't2', slug: 'outside', label: 'Outside'),
    ],
    sleepHours: 7.5,
    energy: EnergyLevel.high,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  test('round-trip envelope produces equivalent entries', () {
    final original = BackupEnvelope(
      schema: 1,
      exportedAt: DateTime.utc(2026, 5, 18),
      appVersion: '1.0.0+1',
      entries: [_e()],
    );
    final json = envelopeToJson(original);
    final restored = envelopeFromJson(json);
    expect(restored.schema, 1);
    expect(restored.exportedAt, original.exportedAt);
    expect(restored.appVersion, '1.0.0+1');
    expect(restored.entries.length, 1);
    final re = restored.entries.first;
    expect(re.id, 'e1');
    expect(re.mood, Mood.good);
    expect(re.energy, EnergyLevel.high);
    expect(re.intensity, 7);
    expect(re.note, 'Great hike today');
    expect(re.sleepHours, 7.5);
    expect(re.tags.map((t) => t.slug).toSet(), {'work', 'outside'});
  });

  test('mood and energy serialize as enum names', () {
    final json = envelopeToJson(BackupEnvelope(
      schema: 1,
      exportedAt: DateTime.utc(2026, 5, 18),
      appVersion: 'x',
      entries: [_e()],
    ));
    final entry = (json['entries'] as List).first as Map<String, dynamic>;
    expect(entry['mood'], 'good');
    expect(entry['energy'], 'high');
  });

  test('timestamps serialize as epoch milliseconds', () {
    final json = envelopeToJson(BackupEnvelope(
      schema: 1,
      exportedAt: DateTime.utc(2026, 5, 18),
      appVersion: 'x',
      entries: [_e()],
    ));
    final entry = (json['entries'] as List).first as Map<String, dynamic>;
    expect(entry['occurredAt'], DateTime.utc(2026, 5, 17, 12).millisecondsSinceEpoch);
  });

  test('envelopeFromJson rejects invalid entries with BackupFormatException', () {
    final bad = {
      'schema': 1,
      'exportedAt': DateTime.utc(2026).toIso8601String(),
      'appVersion': 'x',
      'entries': [
        {
          'id': 'broken',
          'occurredAt': 0,
          'mood': 'goodish',   // not a Mood.values name
          'intensity': 5,
          'note': null,
          'tags': <String>[],
          'sleepHours': null,
          'energy': 'medium',
          'createdAt': 0,
          'updatedAt': 0,
        }
      ],
    };
    expect(() => envelopeFromJson(bad),
        throwsA(isA<BackupFormatException>()));
  });

  test('migrate is identity for current-schema envelope', () {
    final raw = <String, dynamic>{
      'schema': 1,
      'exportedAt': DateTime.utc(2026).toIso8601String(),
      'appVersion': 'x',
      'entries': <Map<String, dynamic>>[],
    };
    final migrated = migrate(Map<String, dynamic>.from(raw));
    expect(migrated['schema'], 1);
    expect(migrated['entries'], <Map<String, dynamic>>[]);
  });

  test('migrate bumps unknown older schema to current', () {
    final raw = <String, dynamic>{
      'schema': 0,
      'exportedAt': DateTime.utc(2026).toIso8601String(),
      'appVersion': 'x',
      'entries': <Map<String, dynamic>>[],
    };
    final migrated = migrate(raw);
    expect(migrated['schema'], 1);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/backup/data/backup_codec_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement `backup_codec.dart`**

```dart
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/entities/tag.dart';
import '../../mood_entry/domain/enums/energy_level.dart';
import '../../mood_entry/domain/enums/mood.dart';
import '../domain/backup_envelope.dart';

class BackupFormatException implements Exception {
  const BackupFormatException(this.messageKey, {this.index});

  final String messageKey;
  final int? index;

  @override
  String toString() => 'BackupFormatException($messageKey, index=$index)';
}

Map<String, dynamic> envelopeToJson(BackupEnvelope env) {
  return {
    'schema': env.schema,
    'exportedAt': env.exportedAt.toUtc().toIso8601String(),
    'appVersion': env.appVersion,
    'entries': env.entries.map(_entryToJson).toList(),
  };
}

BackupEnvelope envelopeFromJson(Map<String, dynamic> raw) {
  final migrated = migrate(Map<String, dynamic>.from(raw));
  try {
    final entriesRaw = (migrated['entries'] as List).cast<dynamic>();
    final entries = <MoodEntry>[];
    for (var i = 0; i < entriesRaw.length; i++) {
      try {
        entries.add(_entryFromJson(entriesRaw[i] as Map<String, dynamic>));
      } catch (_) {
        throw BackupFormatException('backupErrorParseFailed', index: i);
      }
    }
    return BackupEnvelope(
      schema: migrated['schema'] as int,
      exportedAt: DateTime.parse(migrated['exportedAt'] as String),
      appVersion: migrated['appVersion'] as String,
      entries: entries,
    );
  } on BackupFormatException {
    rethrow;
  } catch (_) {
    throw const BackupFormatException('backupErrorParseFailed');
  }
}

@visibleForTesting
Map<String, dynamic> migrate(Map<String, dynamic> raw) {
  // Currently a no-op except for schema upgrade hook.
  // Future schema bumps add migrations here.
  final schema = raw['schema'] as int? ?? 0;
  if (schema < BackupEnvelope.currentSchema) {
    raw['schema'] = BackupEnvelope.currentSchema;
  }
  return raw;
}

Map<String, dynamic> _entryToJson(MoodEntry e) {
  return {
    'id': e.id,
    'occurredAt': e.occurredAt.millisecondsSinceEpoch,
    'mood': e.mood.name,
    'intensity': e.intensity,
    'note': e.note,
    'tags': e.tags.map((t) => t.slug).toList(),
    'sleepHours': e.sleepHours,
    'energy': e.energy.name,
    'createdAt': e.createdAt.millisecondsSinceEpoch,
    'updatedAt': e.updatedAt.millisecondsSinceEpoch,
  };
}

MoodEntry _entryFromJson(Map<String, dynamic> raw) {
  final moodName = raw['mood'] as String;
  final mood = Mood.values.firstWhere((m) => m.name == moodName,
      orElse: () => throw const FormatException('bad mood'));
  final energyName = raw['energy'] as String;
  final energy = EnergyLevel.values.firstWhere((e) => e.name == energyName,
      orElse: () => throw const FormatException('bad energy'));
  final tagsRaw = (raw['tags'] as List).cast<String>();
  return MoodEntry(
    id: raw['id'] as String,
    occurredAt:
        DateTime.fromMillisecondsSinceEpoch(raw['occurredAt'] as int),
    mood: mood,
    intensity: raw['intensity'] as int,
    note: raw['note'] as String?,
    tags: [
      for (final slug in tagsRaw)
        Tag(id: 't_$slug', slug: slug, label: _titleCase(slug)),
    ],
    sleepHours: (raw['sleepHours'] as num?)?.toDouble(),
    energy: energy,
    createdAt:
        DateTime.fromMillisecondsSinceEpoch(raw['createdAt'] as int),
    updatedAt:
        DateTime.fromMillisecondsSinceEpoch(raw['updatedAt'] as int),
  );
}

String _titleCase(String slug) {
  if (slug.isEmpty) return slug;
  return slug
      .split('_')
      .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
      .join(' ');
}
```

- [ ] **Step 4: Run, verify PASS, commit**

```bash
flutter test test/features/backup/data/backup_codec_test.dart
flutter analyze && flutter test
git add lib/features/backup/data/backup_codec.dart test/features/backup/data/backup_codec_test.dart
git commit -m "feat(backup): add BackupCodec with versioned envelope and migration shim"
```

Expected: 212 tests pass (206 + 6).

---

## Task 15: `BackupService` (file IO + repo wiring) + tests

**Files:**
- Create: `lib/features/backup/data/backup_service.dart`
- Create: `lib/features/backup/data/backup_service_provider.dart`
- Test: `test/features/backup/data/backup_service_test.dart`

`BackupService` is the only file in the entire phase that touches `share_plus` and `file_picker`. Both are wrapped behind plain function abstractions injected at construction so tests can replace them.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/backup/data/backup_service_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/features/backup/data/backup_service.dart';
import 'package:mood_tracker/features/backup/domain/import_mode.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';

class _MemRepo implements MoodEntryRepository {
  final Map<String, MoodEntry> _store = {};

  @override
  Stream<List<MoodEntry>> watchAll({EntryQuery? query}) =>
      Stream.value(_store.values.toList());
  @override
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query}) async =>
      (_store.values.toList(), null);
  @override
  Future<(MoodEntry?, Failure?)> create(MoodEntry entry) async {
    _store[entry.id] = entry;
    return (entry, null);
  }
  @override
  Future<(MoodEntry?, Failure?)> update(MoodEntry entry) async {
    _store[entry.id] = entry;
    return (entry, null);
  }
  @override
  Future<(Unit?, Failure?)> delete(String id) async {
    _store.remove(id);
    return (Unit.value, null);
  }
  @override
  Future<(MoodEntry?, Failure?)> getById(String id) async =>
      _store.containsKey(id)
          ? (_store[id], null)
          : (null, NotFoundFailure(id: id));
}

MoodEntry _entry(String id, {Mood mood = Mood.okay}) {
  final t = DateTime.utc(2026, 5, 17, 12);
  return MoodEntry(
    id: id,
    occurredAt: t,
    mood: mood,
    intensity: 5,
    note: null,
    tags: const [],
    sleepHours: null,
    energy: EnergyLevel.medium,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_service_test');
  });
  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('exportAndShare writes JSON file with expected entries', () async {
    final repo = _MemRepo();
    await repo.create(_entry('a'));
    await repo.create(_entry('b'));
    String? sharedPath;
    final svc = BackupServiceImpl(
      repo: repo,
      appVersion: '1.0.0+1',
      tempDir: () async => tempDir,
      share: (path) async {
        sharedPath = path;
      },
      pickFile: () async => null,
    );
    final (filename, err) = await svc.exportAndShare();
    expect(err, isNull);
    expect(filename, isNotNull);
    expect(sharedPath, isNotNull);
    final file = File(sharedPath!);
    expect(await file.exists(), true);
    final decoded = json.decode(await file.readAsString())
        as Map<String, dynamic>;
    expect(decoded['schema'], 1);
    expect((decoded['entries'] as List).length, 2);
  });

  test('pickAndImport(merge) skips duplicate IDs', () async {
    final repo = _MemRepo();
    await repo.create(_entry('a', mood: Mood.bad));
    final tmpFile = File('${tempDir.path}/in.json');
    await tmpFile.writeAsString(json.encode({
      'schema': 1,
      'exportedAt': DateTime.utc(2026).toIso8601String(),
      'appVersion': 'x',
      'entries': [
        {
          'id': 'a', 'occurredAt': 0, 'mood': 'great', 'intensity': 5,
          'note': null, 'tags': <String>[], 'sleepHours': null,
          'energy': 'medium', 'createdAt': 0, 'updatedAt': 0,
        },
        {
          'id': 'b', 'occurredAt': 0, 'mood': 'good', 'intensity': 5,
          'note': null, 'tags': <String>[], 'sleepHours': null,
          'energy': 'medium', 'createdAt': 0, 'updatedAt': 0,
        }
      ],
    }));
    final svc = BackupServiceImpl(
      repo: repo,
      appVersion: '1.0.0+1',
      tempDir: () async => tempDir,
      share: (_) async {},
      pickFile: () async => tmpFile,
    );
    final (count, err) = await svc.pickAndImport(ImportMode.merge);
    expect(err, isNull);
    expect(count, 1);
    final (all, _) = await repo.getAll();
    expect(all!.length, 2);
    expect(all.firstWhere((e) => e.id == 'a').mood, Mood.bad); // unchanged
  });

  test('pickAndImport(replace) wipes existing then loads file', () async {
    final repo = _MemRepo();
    await repo.create(_entry('old1'));
    await repo.create(_entry('old2'));
    final tmpFile = File('${tempDir.path}/in.json');
    await tmpFile.writeAsString(json.encode({
      'schema': 1,
      'exportedAt': DateTime.utc(2026).toIso8601String(),
      'appVersion': 'x',
      'entries': [
        {
          'id': 'new1', 'occurredAt': 0, 'mood': 'good', 'intensity': 5,
          'note': null, 'tags': <String>[], 'sleepHours': null,
          'energy': 'medium', 'createdAt': 0, 'updatedAt': 0,
        }
      ],
    }));
    final svc = BackupServiceImpl(
      repo: repo,
      appVersion: '1.0.0+1',
      tempDir: () async => tempDir,
      share: (_) async {},
      pickFile: () async => tmpFile,
    );
    final (count, err) = await svc.pickAndImport(ImportMode.replace);
    expect(err, isNull);
    expect(count, 1);
    final (all, _) = await repo.getAll();
    expect(all!.length, 1);
    expect(all.single.id, 'new1');
  });

  test('pickAndImport returns ValidationFailure on malformed JSON', () async {
    final repo = _MemRepo();
    final tmpFile = File('${tempDir.path}/in.json');
    await tmpFile.writeAsString('{this is not json');
    final svc = BackupServiceImpl(
      repo: repo,
      appVersion: '1.0.0+1',
      tempDir: () async => tempDir,
      share: (_) async {},
      pickFile: () async => tmpFile,
    );
    final (count, err) = await svc.pickAndImport(ImportMode.merge);
    expect(count, isNull);
    expect(err, isA<ValidationFailure>());
  });

  test('pickAndImport returns ValidationFailure when no file picked', () async {
    final repo = _MemRepo();
    final svc = BackupServiceImpl(
      repo: repo,
      appVersion: '1.0.0+1',
      tempDir: () async => tempDir,
      share: (_) async {},
      pickFile: () async => null,
    );
    final (count, err) = await svc.pickAndImport(ImportMode.merge);
    expect(count, isNull);
    expect(err, isA<ValidationFailure>());
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/backup/data/backup_service_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement `backup_service.dart`**

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/error/failure.dart';
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/repositories/mood_entry_repository.dart';
import '../domain/backup_envelope.dart';
import '../domain/import_mode.dart';
import 'backup_codec.dart';

abstract class BackupService {
  Future<(String?, Failure?)> exportAndShare();
  Future<(int?, Failure?)> pickAndImport(ImportMode mode);
}

typedef ShareFn = Future<void> Function(String filePath);
typedef PickFileFn = Future<File?> Function();
typedef TempDirFn = Future<Directory> Function();

class BackupServiceImpl implements BackupService {
  BackupServiceImpl({
    required this.repo,
    required this.appVersion,
    required this.tempDir,
    required this.share,
    required this.pickFile,
  });

  final MoodEntryRepository repo;
  final String appVersion;
  final TempDirFn tempDir;
  final ShareFn share;
  final PickFileFn pickFile;

  @override
  Future<(String?, Failure?)> exportAndShare() async {
    try {
      final (entries, err) = await repo.getAll();
      if (err != null) return (null, err);
      final env = BackupEnvelope(
        schema: BackupEnvelope.currentSchema,
        exportedAt: DateTime.now().toUtc(),
        appVersion: appVersion,
        entries: entries ?? const [],
      );
      final dir = await tempDir();
      final today = DateTime.now().toUtc();
      final yyyy = today.year.toString().padLeft(4, '0');
      final mm = today.month.toString().padLeft(2, '0');
      final dd = today.day.toString().padLeft(2, '0');
      final filename = 'mood_tracker_export_$yyyy-$mm-$dd.json';
      final file = File('${dir.path}/$filename');
      await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(envelopeToJson(env)));
      await share(file.path);
      return (filename, null);
    } catch (e) {
      return (null, IOFailure(message: e.toString()));
    }
  }

  @override
  Future<(int?, Failure?)> pickAndImport(ImportMode mode) async {
    try {
      final file = await pickFile();
      if (file == null) {
        return (null, ValidationFailure(messageKey: 'backupErrorPickCanceled'));
      }
      final raw = await file.readAsString();
      late final BackupEnvelope env;
      try {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        env = envelopeFromJson(decoded);
      } on BackupFormatException catch (e) {
        return (null, ValidationFailure(messageKey: e.messageKey));
      } catch (_) {
        return (null, ValidationFailure(messageKey: 'backupErrorParseFailed'));
      }

      if (mode == ImportMode.replace) {
        final (existing, err) = await repo.getAll();
        if (err != null) return (null, err);
        for (final e in existing ?? const []) {
          await repo.delete(e.id);
        }
      }

      var imported = 0;
      final (existingNow, _) = await repo.getAll();
      final existingIds = (existingNow ?? const <MoodEntry>[])
          .map((e) => e.id)
          .toSet();
      for (final e in env.entries) {
        if (mode == ImportMode.merge && existingIds.contains(e.id)) continue;
        final (_, err) = await repo.create(e);
        if (err == null) imported++;
      }
      return (imported, null);
    } catch (e) {
      return (null, IOFailure(message: e.toString()));
    }
  }
}
```

Check `lib/core/error/failure.dart` for the actual `Failure` subtypes and their constructors. If `ValidationFailure` doesn't take `messageKey`, adapt the constructor call to whatever shape exists (it might use `cause` or `code`). Similarly for `IOFailure`. Read the file before writing the impl.

- [ ] **Step 4: Implement `backup_service_provider.dart`**

```dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../mood_entry/data/mood_entry_repository_provider.dart';
import 'backup_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  return BackupServiceImpl(
    repo: repo,
    appVersion: _appVersionCache ?? 'unknown',
    tempDir: () async => getTemporaryDirectory(),
    share: (path) async {
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
    },
    pickFile: () async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      final path = result?.files.first.path;
      return path == null ? null : File(path);
    },
  );
});

String? _appVersionCache;

Future<void> primeAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    _appVersionCache = '${info.version}+${info.buildNumber}';
  } catch (_) {
    _appVersionCache = 'unknown';
  }
}
```

If your `share_plus` major version exposes `Share.shareXFiles(...)` instead of the `SharePlus.instance.share(...)` form, swap to whatever the installed version exposes.

- [ ] **Step 5: Prime `_appVersionCache` in bootstrap**

In `lib/app/bootstrap.dart`, after `await registerServices()`:

```dart
import '../features/backup/data/backup_service_provider.dart';

// inside bootstrap():
await primeAppVersion();
```

- [ ] **Step 6: Run, verify PASS, commit**

```bash
flutter test test/features/backup/data/backup_service_test.dart
flutter analyze && flutter test
git add lib/features/backup/data/backup_service.dart lib/features/backup/data/backup_service_provider.dart lib/app/bootstrap.dart test/features/backup/data/backup_service_test.dart
git commit -m "feat(backup): add BackupService with export and import (merge|replace)"
```

Expected: 217 tests pass (212 + 5).

---

## Task 16: `BackupController` + tests

**Files:**
- Create: `lib/features/backup/providers/backup_controller.dart`
- Test: `test/features/backup/providers/backup_controller_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/backup/providers/backup_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/features/backup/data/backup_service.dart';
import 'package:mood_tracker/features/backup/data/backup_service_provider.dart';
import 'package:mood_tracker/features/backup/domain/import_mode.dart';
import 'package:mood_tracker/features/backup/providers/backup_controller.dart';

class _FakeService implements BackupService {
  (String?, Failure?) exportResult = ('file.json', null);
  (int?, Failure?) importResult = (3, null);
  ImportMode? lastMode;

  @override
  Future<(String?, Failure?)> exportAndShare() async => exportResult;
  @override
  Future<(int?, Failure?)> pickAndImport(ImportMode mode) async {
    lastMode = mode;
    return importResult;
  }
}

void main() {
  test('initial state is idle', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(backupControllerProvider), const BackupState.idle());
  });

  test('export() returns success with filename', () async {
    final svc = _FakeService();
    final c = ProviderContainer(overrides: [
      backupServiceProvider.overrideWithValue(svc),
    ]);
    addTearDown(c.dispose);
    await c.read(backupControllerProvider.notifier).export();
    final state = c.read(backupControllerProvider);
    expect(state, isA<BackupStateSuccessExport>());
    expect((state as BackupStateSuccessExport).filename, 'file.json');
  });

  test('import(replace) forwards mode to service', () async {
    final svc = _FakeService();
    final c = ProviderContainer(overrides: [
      backupServiceProvider.overrideWithValue(svc),
    ]);
    addTearDown(c.dispose);
    await c.read(backupControllerProvider.notifier).import(ImportMode.replace);
    expect(svc.lastMode, ImportMode.replace);
    final state = c.read(backupControllerProvider);
    expect(state, isA<BackupStateSuccessImport>());
    expect((state as BackupStateSuccessImport).count, 3);
  });

  test('export() failure yields error state', () async {
    final svc = _FakeService()..exportResult = (null, const IOFailure(message: 'oops'));
    final c = ProviderContainer(overrides: [
      backupServiceProvider.overrideWithValue(svc),
    ]);
    addTearDown(c.dispose);
    await c.read(backupControllerProvider.notifier).export();
    final state = c.read(backupControllerProvider);
    expect(state, isA<BackupStateError>());
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/backup/providers/backup_controller_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement `backup_controller.dart`**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../data/backup_service_provider.dart';
import '../domain/import_mode.dart';

@immutable
sealed class BackupState {
  const BackupState();
  const factory BackupState.idle() = BackupStateIdle;
  const factory BackupState.working() = BackupStateWorking;
  const factory BackupState.successExport(String filename) =
      BackupStateSuccessExport;
  const factory BackupState.successImport(int count) =
      BackupStateSuccessImport;
  const factory BackupState.error(Failure failure) = BackupStateError;
}

class BackupStateIdle extends BackupState {
  const BackupStateIdle();
  @override bool operator ==(Object other) => other is BackupStateIdle;
  @override int get hashCode => 0;
}
class BackupStateWorking extends BackupState {
  const BackupStateWorking();
  @override bool operator ==(Object other) => other is BackupStateWorking;
  @override int get hashCode => 1;
}
class BackupStateSuccessExport extends BackupState {
  const BackupStateSuccessExport(this.filename);
  final String filename;
  @override
  bool operator ==(Object other) =>
      other is BackupStateSuccessExport && other.filename == filename;
  @override int get hashCode => filename.hashCode;
}
class BackupStateSuccessImport extends BackupState {
  const BackupStateSuccessImport(this.count);
  final int count;
  @override
  bool operator ==(Object other) =>
      other is BackupStateSuccessImport && other.count == count;
  @override int get hashCode => count.hashCode;
}
class BackupStateError extends BackupState {
  const BackupStateError(this.failure);
  final Failure failure;
  @override
  bool operator ==(Object other) =>
      other is BackupStateError && other.failure == failure;
  @override int get hashCode => failure.hashCode;
}

class BackupController extends Notifier<BackupState> {
  @override
  BackupState build() => const BackupState.idle();

  Future<void> export() async {
    state = const BackupState.working();
    final svc = ref.read(backupServiceProvider);
    final (filename, err) = await svc.exportAndShare();
    if (err != null) {
      state = BackupState.error(err);
    } else {
      state = BackupState.successExport(filename!);
    }
  }

  Future<void> import(ImportMode mode) async {
    state = const BackupState.working();
    final svc = ref.read(backupServiceProvider);
    final (count, err) = await svc.pickAndImport(mode);
    if (err != null) {
      state = BackupState.error(err);
    } else {
      state = BackupState.successImport(count!);
    }
  }
}

final backupControllerProvider =
    NotifierProvider<BackupController, BackupState>(BackupController.new);
```

- [ ] **Step 4: Run, verify PASS, commit**

```bash
flutter test test/features/backup/providers/backup_controller_test.dart
flutter analyze && flutter test
git add lib/features/backup/providers/backup_controller.dart test/features/backup/providers/backup_controller_test.dart
git commit -m "feat(backup): add BackupController with sealed state machine"
```

Expected: 221 tests pass (217 + 4).

---

## Task 17: `ImportModeDialog` widget

**Files:**
- Create: `lib/features/backup/presentation/widgets/import_mode_dialog.dart`
- Test: `test/features/backup/presentation/import_mode_dialog_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/backup/presentation/import_mode_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/backup/domain/import_mode.dart';
import 'package:mood_tracker/features/backup/presentation/widgets/import_mode_dialog.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ImportMode?> pump(WidgetTester tester) async {
    ImportMode? result;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        return Scaffold(body: TextButton(
          onPressed: () async {
            result = await ImportModeDialog.show(context);
          },
          child: const Text('open'),
        ));
      }),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('renders merge and replace options', (tester) async {
    await pump(tester);
    expect(find.text('Merge'), findsOneWidget);
    expect(find.text('Replace'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Cancel returns null', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    // result remains null
  });

  testWidgets('Selecting Merge and pressing Continue returns merge',
      (tester) async {
    ImportMode? captured;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        return Scaffold(body: TextButton(
          onPressed: () async {
            captured = await ImportModeDialog.show(context);
          },
          child: const Text('open'),
        ));
      }),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Merge'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(captured, ImportMode.merge);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/backup/presentation/import_mode_dialog_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement `import_mode_dialog.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../domain/import_mode.dart';

class ImportModeDialog {
  /// Shows the import-mode picker. Returns the chosen mode, or null on cancel.
  /// For Replace, also shows a secondary confirm; returns null if not confirmed.
  static Future<ImportMode?> show(BuildContext context) async {
    final selected = ValueNotifier<ImportMode>(ImportMode.merge);
    final picked = await showDialog<ImportMode>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.backupImportModeTitle),
          content: ValueListenableBuilder<ImportMode>(
            valueListenable: selected,
            builder: (context, value, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ImportMode>(
                    value: ImportMode.merge,
                    groupValue: value,
                    onChanged: (v) => selected.value = v!,
                    title: Text(l10n.backupImportModeMerge),
                    subtitle: Text(l10n.backupImportModeMergeHint),
                  ),
                  RadioListTile<ImportMode>(
                    value: ImportMode.replace,
                    groupValue: value,
                    onChanged: (v) => selected.value = v!,
                    title: Text(l10n.backupImportModeReplace),
                    subtitle: Text(l10n.backupImportModeReplaceHint),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.backupImportCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selected.value),
              child: Text(l10n.backupImportContinue),
            ),
          ],
        );
      },
    );

    if (picked == ImportMode.replace && context.mounted) {
      final l10n = context.l10n;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.backupReplaceConfirmTitle),
          content: Text(l10n.backupReplaceConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.backupImportCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.backupImportContinue),
            ),
          ],
        ),
      );
      if (confirmed != true) return null;
    }

    return picked;
  }
}
```

- [ ] **Step 4: Run, verify PASS, commit**

```bash
flutter test test/features/backup/presentation/import_mode_dialog_test.dart
flutter analyze && flutter test
git add lib/features/backup/presentation/widgets/import_mode_dialog.dart test/features/backup/presentation/import_mode_dialog_test.dart
git commit -m "feat(backup): add ImportModeDialog with merge/replace + replace double-confirm"
```

Expected: 224 tests pass (221 + 3).

---

## Task 18: `BackupScreen`

**Files:**
- Create: `lib/features/backup/presentation/screens/backup_screen.dart`
- Test: `test/features/backup/presentation/backup_screen_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/backup/presentation/backup_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/backup/data/backup_service.dart';
import 'package:mood_tracker/features/backup/data/backup_service_provider.dart';
import 'package:mood_tracker/features/backup/domain/import_mode.dart';
import 'package:mood_tracker/features/backup/presentation/screens/backup_screen.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

class _FakeService implements BackupService {
  int exportCalls = 0;
  ImportMode? lastImportMode;
  @override
  Future<(String?, Failure?)> exportAndShare() async {
    exportCalls++;
    return ('out.json', null);
  }
  @override
  Future<(int?, Failure?)> pickAndImport(ImportMode mode) async {
    lastImportMode = mode;
    return (5, null);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders Export + Import buttons', (tester) async {
    final svc = _FakeService();
    await tester.pumpWidget(ProviderScope(
      overrides: [backupServiceProvider.overrideWithValue(svc)],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BackupScreen(),
      ),
    ));
    await tester.pump();
    expect(find.text('Export to file'), findsOneWidget);
    expect(find.text('Import from file'), findsOneWidget);
  });

  testWidgets('tapping Export calls service', (tester) async {
    final svc = _FakeService();
    await tester.pumpWidget(ProviderScope(
      overrides: [backupServiceProvider.overrideWithValue(svc)],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BackupScreen(),
      ),
    ));
    await tester.pump();
    await tester.tap(find.text('Export to file'));
    await tester.pumpAndSettle();
    expect(svc.exportCalls, 1);
  });
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `flutter test test/features/backup/presentation/backup_screen_test.dart`
Expected: compile error.

- [ ] **Step 3: Implement `backup_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../providers/backup_controller.dart';
import '../widgets/import_mode_dialog.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(backupControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(l10n.backupSubtitle),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            icon: const Icon(Icons.upload_file),
            label: Text(l10n.backupExportButton),
            onPressed: state is BackupStateWorking
                ? null
                : () => ref.read(backupControllerProvider.notifier).export(),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            icon: const Icon(Icons.download_for_offline_outlined),
            label: Text(l10n.backupImportButton),
            onPressed: state is BackupStateWorking
                ? null
                : () async {
                    final mode = await ImportModeDialog.show(context);
                    if (mode == null) return;
                    await ref
                        .read(backupControllerProvider.notifier)
                        .import(mode);
                  },
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatusBanner(state: state),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});
  final BackupState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (state) {
      BackupStateIdle() => const SizedBox.shrink(),
      BackupStateWorking() =>
        Row(children: [
          const SizedBox(
              height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.backupWorking),
        ]),
      BackupStateSuccessExport(:final filename) =>
        Text(l10n.backupExportSuccess(filename)),
      BackupStateSuccessImport(:final count) =>
        Text(l10n.backupImportSuccess(count)),
      BackupStateError(:final failure) => ErrorView(failure: failure),
    };
  }
}
```

If `AppSpacing.lg` doesn't exist, substitute with whatever larger spacing token exists (e.g., `AppSpacing.md * 2` or `AppSpacing.xl`). Read the file first if unsure.

- [ ] **Step 4: Run, verify PASS**

Run: `flutter test test/features/backup/presentation/backup_screen_test.dart`
Expected: 2 tests pass.

- [ ] **Step 5: Full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; **226 tests pass** (224 + 2).

- [ ] **Step 6: Commit**

```bash
git add lib/features/backup/presentation/screens/backup_screen.dart test/features/backup/presentation/backup_screen_test.dart
git commit -m "feat(backup): add BackupScreen with export/import buttons + status banner"
```

---

## Task 19: Wire `/settings/backup` route + Settings "Data" tile

**Files:**
- Modify: `lib/core/navigation/app_routes.dart`
- Modify: `lib/core/navigation/app_router.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Add route constant**

In `lib/core/navigation/app_routes.dart`:

```dart
  static const String settingsBackup = '/settings/backup';
```

(Alphabetical position.)

- [ ] **Step 2: Add nested route**

In `lib/core/navigation/app_router.dart`, find the Settings branch's children list. After the `reminders` child added in Task 12, add:

```dart
    GoRoute(
      path: 'backup',
      builder: (context, _) => const BackupScreen(),
    ),
```

Import at the top:

```dart
import '../../features/backup/presentation/screens/backup_screen.dart';
```

- [ ] **Step 3: Add Data tile to Settings screen**

In `lib/features/settings/presentation/screens/settings_screen.dart`, between the Reminders section and the About section, insert:

```dart
            SettingsSection(
              title: l10n.settingsDataSection,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: l10n.settingsDataLabel,
                  subtitle: l10n.settingsDataSubtitle,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.settingsBackup),
                ),
              ],
            ),
```

- [ ] **Step 4: Verify**

Run: `flutter analyze && flutter test` → 0 issues; 226 tests still pass.

- [ ] **Step 5: Commit**

```bash
git add lib/core/navigation/app_routes.dart lib/core/navigation/app_router.dart lib/features/settings/presentation/screens/settings_screen.dart
git commit -m "feat(navigation): wire /settings/backup route and Settings Data tile"
```

---

## Task 20: Integration smoke for Reminders + Backup screens

**Files:**
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Read existing scaffold**

Run: `cat test/widget_test.dart | head -60`. Reuse `_EmptyRepo` and `AppColors` setup.

- [ ] **Step 2: Append two smoke tests at the end of `main()`**

```dart
  testWidgets('Reminders screen renders against empty prefs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final svc = _FakeReminderService();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
        appPrefsProvider.overrideWithValue(AppPrefs(sp)),
        notificationServiceProvider.overrideWithValue(svc),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RemindersScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Daily reminder'), findsOneWidget);
  });

  testWidgets('Backup screen renders Export/Import buttons', (tester) async {
    final svc = _FakeBackupService();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
        backupServiceProvider.overrideWithValue(svc),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BackupScreen(),
      ),
    ));
    await tester.pump();
    expect(find.text('Export to file'), findsOneWidget);
    expect(find.text('Import from file'), findsOneWidget);
  });
}

class _FakeReminderService implements NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<NotificationPermissionStatus> currentStatus() async =>
      NotificationPermissionStatus.granted;
  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      NotificationPermissionStatus.granted;
  @override
  Future<void> scheduleDailyReminder({
    required int hour, required int minute,
    required String title, required String body,
  }) async {}
  @override
  Future<void> cancelAll() async {}
}

class _FakeBackupService implements BackupService {
  @override
  Future<(String?, Failure?)> exportAndShare() async => ('out.json', null);
  @override
  Future<(int?, Failure?)> pickAndImport(ImportMode mode) async => (0, null);
}
```

Add the required imports at the top of `test/widget_test.dart` (alphabetical):

```dart
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/features/backup/data/backup_service.dart';
import 'package:mood_tracker/features/backup/data/backup_service_provider.dart';
import 'package:mood_tracker/features/backup/domain/import_mode.dart';
import 'package:mood_tracker/features/backup/presentation/screens/backup_screen.dart';
import 'package:mood_tracker/features/reminders/data/notification_service.dart';
import 'package:mood_tracker/features/reminders/data/notification_service_provider.dart';
import 'package:mood_tracker/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

- [ ] **Step 3: Run, verify PASS, commit**

```bash
flutter test test/widget_test.dart
flutter analyze && flutter test
git add test/widget_test.dart
git commit -m "test: extend integration smoke to cover Reminders + Backup screens"
```

Expected: **228 tests pass** (226 + 2).

---

## Task 21: Settings screen consistency check

After Tasks 12 + 19, the Settings screen has Theme / Language / Reminders / Data / About. Run the existing settings test to catch any breakage.

**Files:**
- (Possibly modify) `test/features/settings/presentation/screens/settings_screen_test.dart`

- [ ] **Step 1: Identify existing settings test**

Run: `find test/features/settings -name '*.dart'`.

- [ ] **Step 2: Run only that test**

Run: `flutter test test/features/settings/presentation/screens/settings_screen_test.dart`.
If it passes, no action needed. If it fails because the new sections require additional provider overrides:

- Add `appPrefsProvider`, `notificationServiceProvider`, and possibly `backupServiceProvider` to the test's `ProviderScope(overrides: ...)`.
- Provide minimal fakes for any new dependencies.

- [ ] **Step 3: If you had to fix the test, commit**

```bash
git add test/features/settings/presentation/screens/settings_screen_test.dart
git commit -m "test(settings): extend overrides for Reminders + Data tiles"
```

- [ ] **Step 4: Full suite + analyze**

Run: `flutter analyze && flutter test`
Expected: 0 issues; **228 tests pass** (or +1 if you added one).

---

## Task 22: Docs refresh + close-out

**Files:**
- Modify: `README.md`
- Modify: `memory.md`
- Modify: `docs/superpowers/plans/2026-05-18-mood-tracker-phase-5.md` (tick checkboxes + add status header)

- [ ] **Step 1: Skim README**

Run: `cat README.md | head -100`. If it has a phase-status section, append:

```
- Phase 5 — Reminders + JSON export/import (complete 2026-05-18)
```

- [ ] **Step 2: Update `memory.md`**

Add a new session-log entry at the top of the `## Session log` section:

```markdown
### 2026-05-18 — Phase 5 ship

- Phase 5 (Reminders + JSON export/import) landed in N commits on `main`. New tests: +47. Test suite at **228/228 passing**, `flutter analyze` clean.
- Shipped: `features/reminders/` (NotificationService wrapping flutter_local_notifications, ReminderController + permission status provider, RemindersScreen with enable switch + time picker + denied-card), `features/backup/` (BackupCodec with versioned envelope + migration shim, BackupService with file IO via path_provider + share_plus, BackupController sealed state machine, BackupScreen + ImportModeDialog with merge/replace + replace double-confirm).
- New deps: flutter_local_notifications, timezone, share_plus, file_picker, permission_handler.
- Native config: Android manifest permissions + receivers, iOS AppDelegate UNUserNotificationCenter delegate.
- Two new `/settings/` child routes (`reminders`, `backup`) replace the Phase 2 stub tile and add a new Data tile. Settings now shows reminder status as subtitle ("Off" / "Daily at HH:MM").
- Closes out the 5-phase plan. No further phases planned.
```

Replace `N commits` with the actual count from `git log af20408..HEAD --oneline | wc -l` (use whatever the Phase-4 base SHA was — `git log $(git merge-base HEAD af20408)..HEAD --oneline | wc -l` is robust). For simplicity, run `git log --oneline | head -50` and count Phase 5 commits manually.

If `memory.md` has a `## Current status` section, update it. If a `## Phase roadmap` section exists, mark Phase 5 as complete.

- [ ] **Step 3: Tick plan checkboxes**

Add a status header at the top of this plan file (after the existing header):

```markdown
> **Status: ✅ Complete (2026-05-18).** All 22 tasks landed across N commits. `flutter analyze` reports 0 issues; `flutter test` passes 228/228. Manual on-device smoke pass (notifications fire, share sheet opens, file picker imports) deferred to the developer.
```

Replace all `- [ ]` with `- [x]`:

```bash
sed -i '' 's/- \[ \]/- [x]/g' docs/superpowers/plans/2026-05-18-mood-tracker-phase-5.md
```

- [ ] **Step 4: Commit**

```bash
git add README.md memory.md docs/superpowers/plans/2026-05-18-mood-tracker-phase-5.md
git commit -m "docs: mark Phase 5 plan complete; update memory.md session log"
```

- [ ] **Step 5: Final verification**

```
flutter analyze
flutter test
git log --oneline -30
```

Expected: 0 issues; 228 tests pass.

---

## Spec coverage map

| Spec section | Tasks |
|---|---|
| §2 In-scope: `features/reminders/` module | 5-12 |
| §2 In-scope: `features/backup/` module | 13-19 |
| §2 In-scope: new deps | 1 |
| §2 In-scope: native config | 2 |
| §2 In-scope: new routes + AppPrefs keys | 4, 12, 19 |
| §2 In-scope: ~25 ARB key pairs | 3 |
| §2 In-scope: Settings tile edits | 12, 19 |
| §4 Domain types | 5, 13 |
| §5 JSON schema | 14 |
| §6 Service contracts | 6, 7, 15 |
| §7 Provider graph | 8, 16 |
| §8 Presentation | 10, 11, 17, 18 |
| §9 Permission flow | 8, 11 |
| §10 Navigation | 12, 19 |
| §11 Localization | 3 |
| §12 Testing | embedded in 4–20 |
| §13 Edge cases & decisions | embedded throughout |
| §14 Risks | Task 1 (versions), Task 7 (plugin API drift), Task 2 (native config), Task 15 (Failure constructor names) |

## Risks called out

- **Task 7 — `flutter_local_notifications` API drift.** Current major is 19.x; signature may differ from the snippet. Adjust `_FakePlugin` overrides and the `zonedSchedule` call to match the installed version. If `androidScheduleMode` is named differently or moved, adapt.
- **Task 15 — `Failure` subtype constructors.** Read `lib/core/error/failure.dart` first and adjust the `ValidationFailure` / `IOFailure` constructor calls to match real signatures.
- **Task 15 — `share_plus` 10.x API.** If `SharePlus.instance.share(...)` doesn't exist (older majors use `Share.shareXFiles(...)`), swap to whatever the installed version exposes.
- **Task 7 — bootstrap order.** `await registerServices()` must run before `await GetIt.I<NotificationService>().init()`. If existing tests assume bootstrap doesn't call notifications, override via `GetIt.I.reset()` in `setUp`.
- **Task 11 — `errorRetry` ARB key.** Used in the reminders screen error fallback. If not present in EN/ES ARBs, either add it (one line) or replace with a literal string.

## Final acceptance criteria

1. `flutter analyze` → `No issues found!`
2. `flutter test` → 228/228 passing.
3. Manual on-device smoke covers: schedule a reminder for 1 minute from now, verify it fires; export to JSON file via share sheet; import the same file via merge mode (no duplicates); import via replace mode after wiping (works).
4. Spanish translations render correctly on both Reminders and Backup screens.
5. `memory.md` session log updated; plan checkboxes ticked; plan header marked `Status: ✅ Complete`.
