# Mood Tracker — Phase 5 Design Spec

**Date:** 2026-05-18
**Status:** Approved (scope refinement on top of the [2026-05-17 master spec](2026-05-17-mood-tracker-design.md))
**Predecessors:** Phases 1 + 2 + 3 + 4 complete on `main`, 181 tests green.

Per-phase scope refinement — not a fresh design. The master spec governs all architectural decisions. This document covers only what Phase 5 adds and modifies. Phase 5 closes out the 5-phase plan.

## 1. Goal

Ship local daily reminders (via `flutter_local_notifications`) and JSON export/import (via `share_plus` + `file_picker`). The Phase 2 reminders stub becomes a real screen; Settings gets a new "Data" subsection that opens a backup screen with Export and Import buttons.

## 2. Scope

**In:**

- `features/reminders/` — full feature module: `ReminderSchedule` domain value class, `NotificationService` thin wrapper around `flutter_local_notifications`, `ReminderController` (AsyncNotifier), Reminders screen replacing the Phase 2 stub.
- `features/backup/` — full feature module: `BackupEnvelope` domain value class, pure `BackupCodec` (domain ↔ JSON Map), `BackupService` (file IO + repository orchestration), `BackupController` (AsyncNotifier), Backup screen + import-mode dialog.
- New plugin dependencies: `flutter_local_notifications`, `timezone`, `share_plus`, `file_picker`, `permission_handler`.
- Native config: `AndroidManifest.xml` (POST_NOTIFICATIONS for API 33+, RECEIVE_BOOT_COMPLETED for reboot-survival), `Info.plist` (no extra perms needed for local notifications on iOS but the plugin needs registration in `AppDelegate.swift`).
- New route: `/settings/reminders` and `/settings/backup`.
- New `AppPrefs` keys: `reminderEnabled` (bool), `reminderTime` (HH:mm string).
- ~25 new EN+ES ARB key pairs.
- Settings screen edits: convert the stub Reminders tile to a real tappable tile routing to `/settings/reminders`; add a "Data" tile routing to `/settings/backup`.

**Out of scope (deferred):**

- Multiple reminder times per day, weekday-only schedules.
- Reminder notification action buttons (e.g., "Log entry" tapped from the notification surface).
- Custom notification copy in Settings (single localized prompt for Phase 5).
- Cloud backup, sync, or auth.
- Encrypted exports.
- Selective import (e.g., date-range filter at import time).
- Tag-only export (always full data).
- Settings export/import (theme, locale, reminder time are NOT included in the JSON envelope).
- "Manage orphan tags" surface (tags left behind after a Replace import remain in the DB).

## 3. File additions and modifications

```
lib/
  app/
    bootstrap.dart                                  [modify] init NotificationService + timezone db at startup
  core/
    prefs/app_prefs.dart                            [modify] add reminderEnabled / reminderTime accessors + persistence
    navigation/
      app_routes.dart                               [modify] add settingsReminders + settingsBackup constants
      app_router.dart                               [modify] add 2 new GoRoutes nested under /settings
  features/
    reminders/                                      [new]   full feature module
      domain/
        reminder_schedule.dart                      # @immutable { enabled: bool, time: ({int hour, int minute}) }
      data/
        notification_service.dart                   # init / requestPermission / scheduleDaily / cancelAll
        notification_service_provider.dart
      providers/
        reminder_controller.dart                    # AsyncNotifier<ReminderSchedule>
        permission_status_provider.dart             # FutureProvider<PermissionStatus> for reminders permission
      presentation/
        screens/reminders_screen.dart
        widgets/
          reminder_time_picker_sheet.dart           # modal showTimePicker wrapper
          permission_denied_card.dart               # CTA → openAppSettings()
    backup/                                         [new]   full feature module
      domain/
        backup_envelope.dart                        # @immutable { schema, exportedAt, appVersion, entries }
      data/
        backup_codec.dart                           # pure JSON ↔ Map<String, dynamic> with schema migration shim
        backup_service.dart                         # export(): writes temp file + share_plus; import(file, mode): parses + writes via repo
        backup_service_provider.dart
      providers/
        backup_controller.dart                      # AsyncNotifier<BackupState> with export() + import() intent methods
      presentation/
        screens/backup_screen.dart                  # Export button + Import button + status banner
        widgets/
          import_mode_dialog.dart                   # 'Merge' / 'Replace' radio dialog
  features/settings/
    presentation/
      screens/settings_screen.dart                  [modify] reminders tile becomes real (route to /settings/reminders); add Data tile (route to /settings/backup)
  l10n/
    app_en.arb                                      [modify] +~25 keys
    app_es.arb                                      [modify] Spanish mirrors

android/app/src/main/AndroidManifest.xml            [modify] add POST_NOTIFICATIONS + RECEIVE_BOOT_COMPLETED + receiver
android/app/src/main/kotlin/.../MainActivity.kt     [verify] no changes (defaults are fine)
ios/Runner/AppDelegate.swift                        [modify] register flutter_local_notifications

pubspec.yaml                                        [modify] add 5 deps

test/
  features/reminders/
    domain/reminder_schedule_test.dart              [new]
    data/notification_service_test.dart             [new]   uses FakeFlutterLocalNotificationsPlugin
    providers/reminder_controller_test.dart         [new]
    presentation/reminders_screen_test.dart         [new]
  features/backup/
    domain/backup_envelope_test.dart                [new]
    data/backup_codec_test.dart                     [new]   round-trip + schema-migration cases
    data/backup_service_test.dart                   [new]   fake repo + fake file
    providers/backup_controller_test.dart           [new]
    presentation/backup_screen_test.dart            [new]
    presentation/import_mode_dialog_test.dart       [new]
  features/settings/presentation/                   [modify] extend settings_screen_test to cover new tiles
  widget_test.dart                                  [modify] add a smoke test for Reminders + Backup screens
```

## 4. Domain types

### 4.1 `ReminderSchedule` (`features/reminders/domain/`)

```dart
@immutable
class ReminderSchedule {
  const ReminderSchedule({required this.enabled, required this.time});

  final bool enabled;
  final ({int hour, int minute}) time;

  /// Formatted for `AppPrefs` persistence: "HH:mm" (24h, zero-padded).
  String get prefsString;

  /// Parse from prefs string. Returns null on malformed input.
  static ({int hour, int minute})? parseTime(String? raw);

  /// Default schedule: enabled=false, time=21:00.
  static const ReminderSchedule disabledDefault = ReminderSchedule(
    enabled: false,
    time: (hour: 21, minute: 0),
  );
}
```

### 4.2 `BackupEnvelope` (`features/backup/domain/`)

```dart
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
}
```

Tags are denormalized inline per entry — the envelope has no top-level `tags` list. Import re-creates tag rows by slug.

### 4.3 `ImportMode` (`features/backup/domain/`)

```dart
enum ImportMode { merge, replace }
```

## 5. JSON schema

```json
{
  "schema": 1,
  "exportedAt": "2026-05-18T21:34:00.000Z",
  "appVersion": "1.0.0+1",
  "entries": [
    {
      "id": "abc-123",
      "occurredAt": 1747600440000,
      "mood": "good",
      "intensity": 7,
      "note": "Great hike today",
      "tags": ["work", "outside"],
      "sleepHours": 7.5,
      "energy": "high",
      "createdAt": 1747600440000,
      "updatedAt": 1747600440000
    }
  ]
}
```

**Field details:**

- `schema` (int): currently `1`. A `BackupCodec.migrate(Map raw)` shim handles older schemas if/when this changes; currently a no-op stub.
- `exportedAt` (ISO 8601 UTC string): human-readable timestamp of when the export was generated.
- `appVersion` (string): from `package_info_plus`. Informational only.
- `entries[].mood` and `entries[].energy`: enum **name** strings, not ordinals (survives enum reordering).
- `entries[].occurredAt`, `createdAt`, `updatedAt`: epoch ms integers (matches Drift storage).
- `entries[].sleepHours`: nullable double.
- `entries[].note`: nullable string.
- `entries[].tags`: array of slug strings. Empty array allowed. Tag labels are derived from the slug on import (titleCased) — original labels are lost across export/import (acceptable for Phase 5; labels are user-editable post-import).

## 6. Service contracts

### 6.1 `NotificationService` (`features/reminders/data/`)

```dart
abstract class NotificationService {
  Future<void> init();                          // idempotent; called from bootstrap
  Future<PermissionStatus> requestPermission(); // wraps OS prompt + permission_handler
  Future<PermissionStatus> currentStatus();
  Future<void> scheduleDailyReminder({required int hour, required int minute});
  Future<void> cancelAll();
}
```

Implementation `FlutterLocalNotificationsService` uses:

- `flutter_local_notifications`'s `zonedSchedule` with `DateTimeComponents.time` for daily repeat.
- `timezone.tz.local` (initialized from `timezone/data/latest.dart` in bootstrap).
- Notification ID `0` (single reminder; we only ever have one scheduled).
- Android channel: `id='daily_reminder'`, `name='Daily reminder'`, `importance=Importance.defaultImportance`.
- iOS: default sound + presentation options.

### 6.2 `BackupService` (`features/backup/data/`)

```dart
abstract class BackupService {
  Future<(String?, Failure?)> exportAndShare();
  // → writes the JSON to a temp file, returns the filename; share_plus
  //   surfaces the share sheet. Caller doesn't need the path after.

  Future<(String?, Failure?)> pickAndImport(ImportMode mode);
  // → file_picker pulls the JSON, repository writes happen here.
  //   Returns the number of entries imported, formatted as a string,
  //   or a localized Failure.
}
```

Implementation depends on `MoodEntryRepository`, `BackupCodec`, `share_plus`, `file_picker`, and `package_info_plus`.

### 6.3 `BackupCodec` (`features/backup/data/`)

Pure functions, no Riverpod, no IO:

```dart
Map<String, dynamic> envelopeToJson(BackupEnvelope env);
BackupEnvelope envelopeFromJson(Map<String, dynamic> raw);
// envelopeFromJson runs migrate() first if raw['schema'] < currentSchema.

@visibleForTesting
Map<String, dynamic> migrate(Map<String, dynamic> raw);
// Today: no-op (schema 1 only). Future-proof slot for schema bumps.
```

`envelopeFromJson` throws a typed `FormatException` (subclass `BackupFormatException`) with a localized message-key + index on the first invalid entry; `BackupService` catches it and converts to a `ValidationFailure`.

## 7. Provider graph

```
appPrefsProvider (existing, Phase 1)              ─┐
notificationServiceProvider (NEW, wraps GetIt)    ─┤
moodEntryRepositoryProvider (existing)            ─┤
backupServiceProvider (NEW)                       ─┤
                                                   │
                                                   ▼
reminderControllerProvider : AsyncNotifierProvider<ReminderController, ReminderSchedule>
    - reads AppPrefs.reminderEnabled / reminderTime on build()
    - setEnabled(bool) → calls service + persists
    - setTime(hour, minute) → calls service + persists

permissionStatusProvider : FutureProvider<PermissionStatus>
    - calls notificationService.currentStatus(); invalidated after request

backupControllerProvider : AsyncNotifierProvider<BackupController, BackupState>
    - export() → calls backupService.exportAndShare(); state := idle/inProgress/error/lastSuccess(filename)
    - import(mode) → calls backupService.pickAndImport(mode); state := idle/inProgress/error/lastSuccess(count)
```

`BackupState` is a small sealed class with `idle`, `working`, `success(String message)`, `error(Failure)`.

## 8. Presentation

### 8.1 `RemindersScreen` (`/settings/reminders`)

```
AppBar(title: l10n.remindersTitle)
ListView
  SettingsTile(
    title: l10n.remindersEnabledTitle,
    trailing: Switch (bound to ReminderSchedule.enabled),
  )
  SettingsTile(
    title: l10n.remindersTimeTitle,
    subtitle: HH:mm formatted via context.l10n / intl
    trailing: chevron,
    onTap: → showModalBottomSheet(ReminderTimePickerSheet),
    enabled: schedule.enabled
  )
  PermissionDeniedCard (visible iff permission == denied OR permanentlyDenied)
```

The enable-switch flow:

1. User taps the switch to enable.
2. Controller calls `service.requestPermission()`.
3. On `granted` → schedule, persist `enabled=true`.
4. On `denied` → switch reverts to OFF; `PermissionDeniedCard` appears with "Open settings" button calling `permission_handler.openAppSettings()`.
5. On `permanentlyDenied` (iOS sticky deny, Android "don't ask again") → same card, same CTA.

### 8.2 `ReminderTimePickerSheet`

Modal bottom sheet wrapping Material `showTimePicker(...)`. Uses the existing AppMotion / AppColors / context.l10n conventions. Sheet returns the picked `TimeOfDay`; controller persists + re-schedules.

### 8.3 `BackupScreen` (`/settings/backup`)

```
AppBar(title: l10n.backupTitle)
ListView
  Header text: l10n.backupSubtitle (1-2 sentences explaining what export does)
  PrimaryButton: l10n.backupExportButton
    onTap → controller.export()
  Divider
  Header text: l10n.backupImportSubtitle
  PrimaryButton: l10n.backupImportButton
    onTap → show ImportModeDialog → controller.import(mode)
  BackupStatusBanner
    - idle: hidden
    - working: progress indicator + l10n.backupWorking
    - success: green banner with the message
    - error: ErrorView with the localized Failure message
```

### 8.4 `ImportModeDialog`

`showDialog` with `AlertDialog`:

- Title: `l10n.backupImportModeTitle`
- Body: two `RadioListTile`s (`Merge` / `Replace`) + a localized hint line for each
- Actions: `Cancel`, `Continue`
- Returns the chosen `ImportMode` to the caller.

For Replace mode specifically, after the dialog confirms, show a second confirm dialog (`l10n.backupReplaceConfirmTitle` / `l10n.backupReplaceConfirmBody`) so the destructive path requires two taps.

### 8.5 Settings screen edits

`features/settings/presentation/screens/settings_screen.dart`:

- The current Reminders tile is a disabled-looking stub. Make it tappable: tap → `context.push(AppRoutes.settingsReminders)`. Subtitle shows current state: "Off" / "Daily at 21:00".
- Insert a new "Data" tile between Reminders and About: tap → `context.push(AppRoutes.settingsBackup)`. Subtitle: l10n.settingsDataSubtitle ("Export or import your entries").

## 9. Permission flow

Android 13+ requires POST_NOTIFICATIONS at runtime; older Android grants by manifest. iOS asks once.

`NotificationService.requestPermission()` strategy:

- Android: call `Permission.notification.request()` via `permission_handler`.
- iOS: call `flutter_local_notifications`'s iOS plugin `requestPermissions(alert: true, badge: true, sound: true)`.
- Both return a unified `PermissionStatus` (granted / denied / permanentlyDenied).

The Reminders screen uses `permissionStatusProvider` (a `FutureProvider`) to drive `PermissionDeniedCard` visibility. After the user taps "Open settings" and comes back, the screen invalidates `permissionStatusProvider` (lifecycle hook on resume) so the card disappears if they granted from system settings.

For Phase 5 simplicity, the lifecycle re-check is done via `WidgetsBindingObserver` only on the Reminders screen — not app-wide.

## 10. Navigation

```dart
abstract final class AppRoutes {
  // existing constants…
  static const String settingsReminders = '/settings/reminders';
  static const String settingsBackup = '/settings/backup';
}
```

Both routes nest under the existing Settings shell branch (already index 4 after Phase 4). Add as children of the existing `/settings` `GoRoute`:

```dart
GoRoute(
  path: AppRoutes.settings,
  builder: (context, _) => const SettingsScreen(),
  routes: [
    GoRoute(path: 'about', builder: (context, _) => const AboutScreen()),
    GoRoute(path: 'reminders', builder: (context, _) => const RemindersScreen()),
    GoRoute(path: 'backup', builder: (context, _) => const BackupScreen()),
  ],
),
```

(Path strings are relative under the parent — `'reminders'` resolves to `/settings/reminders`.)

## 11. Localization

~25 new EN keys + ES mirrors. All keys carry `@`-metadata; plural keys carry ICU placeholders.

```
# Settings tiles
settingsRemindersTitle, settingsRemindersOff, settingsRemindersDailyAt
settingsDataTile, settingsDataSubtitle

# Reminders screen
remindersTitle, remindersEnabledTitle, remindersTimeTitle, remindersTimeSubtitle
remindersPermissionDeniedTitle, remindersPermissionDeniedBody, remindersOpenSettings

# Notification body
reminderNotificationTitle, reminderNotificationBody

# Backup screen
backupTitle, backupSubtitle, backupExportButton, backupImportButton
backupImportSubtitle, backupWorking, backupExportSuccess, backupImportSuccess

# Import-mode dialog
backupImportModeTitle, backupImportModeMerge, backupImportModeMergeHint,
backupImportModeReplace, backupImportModeReplaceHint, backupImportContinue, backupImportCancel
backupReplaceConfirmTitle, backupReplaceConfirmBody

# Errors
backupErrorParseFailed, backupErrorWriteFailed, backupErrorPickCanceled
```

`backupImportSuccess` and `reminderNotificationBody` use ICU placeholders/plurals.

## 12. Testing

Target: **+50–65 tests**, total around **231–246 passing**. `flutter analyze` stays at 0 issues.

### 12.1 Domain (pure)

- `reminder_schedule_test.dart` — prefs string serialization (round-trip 21:00, 09:05, 23:59); `parseTime` returns null for `"oops"`, `"25:00"`, `null`; default is disabled + 21:00.
- `backup_envelope_test.dart` — value equality, current-schema constant.
- `backup_codec_test.dart`:
  - Round-trip envelope: domain → JSON → domain reproduces equal entries.
  - Mood/energy serialized as names, not ordinals (assert exact JSON text contains `"mood": "good"`).
  - `envelopeFromJson` rejects invalid entries — throws `BackupFormatException` with the entry index.
  - `migrate()` is a no-op when `schema == currentSchema`.
  - Synthetic `schema: 0` raw map: `migrate` updates schema to 1 (currently identity) — keep the test even though the migration is empty, so the future bump has a regression hook.

### 12.2 Data services

- `notification_service_test.dart` — uses a hand-rolled `FakeFlutterLocalNotificationsPlugin` injected at construction. Asserts:
  - `init()` is idempotent (multiple calls don't re-create channels).
  - `scheduleDailyReminder(hour: 21, minute: 0)` calls plugin's `zonedSchedule` with the right channel ID and `DateTimeComponents.time`.
  - `cancelAll()` calls plugin's `cancelAll()`.
- `backup_service_test.dart` — fake repo (in-memory), fake file system (write to temp dir via `path_provider` mock or a passed-in directory):
  - `exportAndShare()` writes the JSON, returns filename; doesn't invoke `share_plus` in test (skip the OS call; assert the file content instead).
  - `pickAndImport(merge)` skips existing IDs.
  - `pickAndImport(replace)` wipes then loads.
  - Malformed JSON returns a `ValidationFailure` with the right message key.

### 12.3 Providers

- `reminder_controller_test.dart` — fake service + fake prefs; assert state transitions, prefs persistence, service calls fire.
- `backup_controller_test.dart` — fake service; export() success → state.success; export() error → state.error; import(mode) wires `mode` through.

### 12.4 Widgets

- `reminders_screen_test.dart` — toggle switch on/off, time picker opens, permission-denied card visibility.
- `backup_screen_test.dart` — tapping Export calls controller, tapping Import opens ImportModeDialog.
- `import_mode_dialog_test.dart` — radio toggle, returns chosen mode on Continue, returns null on Cancel; Replace path opens secondary confirm.

### 12.5 Integration

`test/widget_test.dart` gains a smoke test for the Reminders + Backup screens.

### 12.6 Testing patterns reused

- Google Fonts disabled in `setUpAll` (existing pattern).
- Fake repo with `Stream.value(const [])` for screen tests.
- All platform plugins are abstracted behind service interfaces — no actual notification fires in tests.

## 13. Edge cases and decisions

- **Permission denied with reminders already enabled** (e.g., user revokes from system settings while the app was off): on next app open, `NotificationService.currentStatus()` returns `denied`. The Reminders screen shows the `PermissionDeniedCard`; the `enabled` switch in prefs is left ON (so re-granting won't lose the schedule). The system simply has no notification scheduled until re-granted.
- **Time picker shows current schedule's time**, defaulting to 21:00 the first time it opens.
- **Daily notification timezone**: scheduled via `zonedSchedule` with `tz.TZDateTime.from(... in tz.local)`. App startup initializes the timezone database. If the user travels and changes phone timezone, the next scheduled fire shifts naturally (DST-safe).
- **Reboot survival on Android**: `flutter_local_notifications` requires `RECEIVE_BOOT_COMPLETED` + a registered `BroadcastReceiver` to re-arm scheduled alarms post-reboot. The plugin handles this via its own receiver — we just need the permission in the manifest.
- **Notification tap behavior**: tapping the notification opens the app to its last state. Phase 5 does NOT route to `/log` on tap (deferred — would require parsing payload + deep-linking through the GoRouter, more nuance than this slice should carry).
- **Backup file size**: even for 1000 entries the JSON should be under ~500 KB. No streaming I/O needed; build the string in memory, write once.
- **`appVersion` field**: read from `package_info_plus`. If the package fails (unlikely on supported platforms), default to `"unknown"` — never block export.
- **Import dropping tag labels**: only slugs are exported per entry. On import, labels are derived `Title Case`'d from the slug (`"work_meeting"` → `"Work meeting"`). Acceptable info loss for Phase 5; tag labels are user-editable post-import in a future iteration.
- **Existing-tag collisions on import**: when an imported entry references slug `"work"` and a `"work"` tag already exists in the DB, the existing tag is reused (by slug match) — no duplicate row. The existing tag's label wins.
- **Replace mode tag cleanup**: on Replace, `entries` and `entry_tags` rows are deleted (CASCADE). `tags` rows are NOT deleted — orphaned tags persist. A "Manage tags" surface in a future phase can clean them up; for now they're harmless.
- **Concurrent import while export is in flight** (unlikely but possible): `BackupController` exposes only one in-flight operation at a time; second tap during `working` state is a no-op.
- **Empty entries list on import**: legitimate — import succeeds with 0 entries (e.g., user testing the file format). Status banner shows "0 entries imported".
- **`reminderEnabled` true but no scheduled notification** (e.g., app freshly installed, prefs migrated from backup of a different device): bootstrap calls `NotificationService.scheduleDailyReminder(...)` if prefs say enabled and permission is granted. Otherwise the schedule is silently dropped.

## 14. Risks and dependencies

### 14.1 Plugin versions

- `flutter_local_notifications` — current major is `19.x` (as of late 2025/early 2026). API has been stable for daily zoned scheduling for several major bumps. Pin version at implementation time after `flutter pub add`.
- `timezone` — peer dep; current major is `0.10.x`. Stable.
- `share_plus` — current major is `10.x`. Stable.
- `file_picker` — current major is `8.x`. Stable, but iOS Info.plist requires `NSPhotoLibraryUsageDescription` if picking from photos; we only pick documents so `LSSupportsOpeningDocumentsInPlace = true` is enough.
- `permission_handler` — current major is `11.x` or `12.x`. Stable.
- `package_info_plus` — already a dep from Phase 2.

### 14.2 Native config blast radius

- Android: 2 lines in `AndroidManifest.xml` (POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED) + the broadcast receiver from `flutter_local_notifications` (added automatically when the plugin is imported in recent versions).
- iOS: a few lines in `AppDelegate.swift` to register the notifications plugin with `UNUserNotificationCenter`.

Both files are committed to the repo and need careful editing.

### 14.3 Testing limitations

- Cannot test actual OS notification delivery in widget tests. The service is fully mocked via an injected `FlutterLocalNotificationsPlugin`-shaped fake.
- File-picker UI also cannot be tested; the picker is wrapped in a thin function the test fakes out.

### 14.4 Time-zone DB freshness

The `timezone` package ships a snapshot of the IANA tz database. If a user travels and a country changes DST rules after our `timezone` version was published, the daily fire may be off by an hour. Rebuilding against a fresh `timezone` package fixes it. Acceptable for Phase 5; not a Phase-5 blocker.

## 15. Out of scope (explicitly)

- Multiple reminder times per day or weekday-specific schedules.
- Reminder notification actions (e.g., "Log entry now" button on the notification surface).
- User-editable notification copy.
- Cloud backup, sync, or auth.
- Encrypted exports.
- Selective import (date-range filter at import time).
- Settings/preferences in the JSON envelope (theme, locale, reminder time are not exported).
- "Manage orphan tags" surface (tags left behind by Replace import remain).
- Background processing beyond what `flutter_local_notifications` ships with.
- iOS Live Activities, Android widgets, watchOS/WearOS companions.
