# Mood Tracker — Phase 2 Implementation Plan

> **Status: ✅ Complete (2026-05-18).** All 15 tasks landed across 14 implementation commits + 1 post-review polish (commit `800886d`). `flutter analyze` reports 0 issues; `flutter test` passes 75/75. The only unchecked items are Task 15's manual on-device smoke run + the no-op follow-up commit step — deferred to the developer since the automated environment had no simulator.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the Settings tab, first-run Onboarding flow, and full Spanish translations on top of Phase 1's foundation.

**Architecture:** Phase 1 already established Feature-First Clean Architecture with Riverpod, Drift, GoRouter, GetIt, and a theme/l10n pipeline. Phase 2 adds two more features (`settings`, `onboarding`) and a top-level GoRouter redirect; no architectural changes.

**Tech Stack:** Same as Phase 1 plus `package_info_plus` (for the About screen's version display). No new dev dependencies.

**Spec:** `docs/superpowers/specs/2026-05-18-phase-2-design.md`

**Predecessor:** Phase 1 plan at `docs/superpowers/plans/2026-05-17-mood-tracker-phase-1.md` is complete on `main`. HEAD before Phase 2 starts: `e936b01` (Phase 2 spec commit).

**Working conventions (carry-over from Phase 1):**

- Every Dart file ends with a newline.
- After every task: `flutter analyze` must report 0 issues; `flutter test` must pass.
- Commits NEVER include a `Co-Authored-By` trailer (project preference; overrides the global `CLAUDE.md` rule).
- Imports sorted alphabetically: package imports first, then project imports.
- `const` constructors where possible; `final` locals.
- Generated l10n files (`lib/l10n/app_localizations*.dart`) are gitignored — never commit them.
- Widget tests touching Google Fonts must set `GoogleFonts.config.allowRuntimeFetching = false` in `setUpAll`.

---

## Task 1: Phase 2 prep — prefs, dependency, route constants

**Files:**
- Modify: `lib/core/prefs/app_prefs.dart`
- Modify: `test/core/prefs/app_prefs_test.dart`
- Modify: `pubspec.yaml`
- Modify: `lib/core/navigation/app_routes.dart`

- [x] **Step 1: Add the failing test for `onboardingCompleted`**

In `test/core/prefs/app_prefs_test.dart`, add two new test cases at the end of `main()` (inside the existing test group — preserve all current tests):

```dart
  test('onboardingCompleted defaults to false', () {
    expect(prefs.onboardingCompleted, isFalse);
  });

  test('onboardingCompleted round-trips', () async {
    await prefs.setOnboardingCompleted(true);
    expect(prefs.onboardingCompleted, isTrue);
    await prefs.setOnboardingCompleted(false);
    expect(prefs.onboardingCompleted, isFalse);
  });
```

- [x] **Step 2: Run, verify FAIL**

Run: `flutter test test/core/prefs/app_prefs_test.dart`
Expected: 2 new tests FAIL — `onboardingCompleted` is undefined.

- [x] **Step 3: Extend `lib/core/prefs/app_prefs.dart`**

Add the new key constant and the getter/setter pair. The full file becomes:

```dart
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class AppPrefs {
  AppPrefs(this._sp);

  final SharedPreferences _sp;

  static const _kThemeMode = 'app.themeMode';
  static const _kLocaleTag = 'app.localeTag';
  static const _kOnboardingCompleted = 'app.onboardingCompleted';

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

  bool get onboardingCompleted =>
      _sp.getBool(_kOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) =>
      _sp.setBool(_kOnboardingCompleted, value);
}
```

- [x] **Step 4: Add `package_info_plus` to `pubspec.yaml`**

In the `dependencies:` block, add the entry under the existing `# Utils` section:

```yaml
  # Utils
  uuid: ^4.5.0
  intl: any
  package_info_plus: ^8.0.2
```

Run: `flutter pub get`
Expected: no errors; lockfile updates.

- [x] **Step 5: Add the two new `AppRoutes` constants**

In `lib/core/navigation/app_routes.dart`, add the two constants. Keep the existing ones; the final file is:

```dart
abstract final class AppRoutes {
  static const String today = '/today';
  static const String history = '/history';
  static const String calendar = '/calendar';
  static const String insights = '/insights';
  static const String settings = '/settings';

  static const String log = '/today/log';
  static const String entryDetail = '/entry';
  static const String entryEdit = '/entry/:id/edit';

  static const String onboarding = '/onboarding';
  static const String about = '/settings/about';

  static String entryDetailFor(String id) => '/entry/$id';
  static String entryEditFor(String id) => '/entry/$id/edit';
}
```

- [x] **Step 6: Verify**

- `flutter test test/core/prefs/app_prefs_test.dart` → 6 tests pass (4 existing + 2 new)
- `flutter analyze` → 0 issues
- `flutter test` (full suite) → all pass (was 54; still 54 plus the 2 new pref tests = 56)

- [x] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/prefs/app_prefs.dart lib/core/navigation/app_routes.dart test/core/prefs/app_prefs_test.dart
git commit -m "feat(core): add onboardingCompleted pref, package_info_plus, Phase 2 route constants"
```

No `Co-Authored-By` trailer.

---

## Task 2: Native locale-name helper

**Files:**
- Create: `lib/core/l10n/native_name.dart`
- Create: `test/core/l10n/native_name_test.dart`

- [x] **Step 1: Write the failing test**

Create `test/core/l10n/native_name_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/l10n/native_name.dart';

import 'dart:ui' show Locale;

void main() {
  test('returns native name for English', () {
    expect(nativeNameFor(const Locale('en')), 'English');
  });

  test('returns native name for Spanish', () {
    expect(nativeNameFor(const Locale('es')), 'Español');
  });

  test('falls back to language code for unknown locale', () {
    expect(nativeNameFor(const Locale('fr')), 'fr');
  });
}
```

- [x] **Step 2: FAIL**

Run: `flutter test test/core/l10n/native_name_test.dart`
Expected: FAIL — symbol undefined.

- [x] **Step 3: Implement `lib/core/l10n/native_name.dart`**

```dart
import 'dart:ui' show Locale;

String nativeNameFor(Locale locale) => switch (locale.languageCode) {
      'en' => 'English',
      'es' => 'Español',
      _ => locale.languageCode,
    };
```

- [x] **Step 4: Verify + commit**

- `flutter test test/core/l10n/native_name_test.dart` → 3 tests pass
- `flutter analyze` → 0 issues

```bash
git add lib/core/l10n/native_name.dart test/core/l10n/native_name_test.dart
git commit -m "feat(l10n): add nativeNameFor helper for language picker labels"
```

---

## Task 3: Add the new English ARB keys

**Files:**
- Modify: `lib/l10n/app_en.arb`

- [x] **Step 1: Replace the contents of `lib/l10n/app_en.arb` with the merged set (Phase 1 keys + Phase 2 keys)**

The full file is:

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
  "@navSettings": {},

  "settingsTitle": "Settings",
  "@settingsTitle": {},
  "settingsAppearanceSection": "Appearance",
  "@settingsAppearanceSection": {},
  "settingsLanguageSection": "Language",
  "@settingsLanguageSection": {},
  "settingsRemindersSection": "Reminders",
  "@settingsRemindersSection": {},
  "settingsAboutSection": "About",
  "@settingsAboutSection": {},
  "settingsThemeLabel": "Theme",
  "@settingsThemeLabel": {},
  "settingsLanguageLabel": "Language",
  "@settingsLanguageLabel": {},
  "settingsRemindersLabel": "Daily reminder",
  "@settingsRemindersLabel": {},
  "settingsRemindersComingSoon": "Coming in a future update",
  "@settingsRemindersComingSoon": {},
  "settingsAboutLabel": "About this app",
  "@settingsAboutLabel": {},

  "themeLight": "Light",
  "@themeLight": {},
  "themeDark": "Dark",
  "@themeDark": {},
  "themeSystem": "System",
  "@themeSystem": {},

  "aboutTitle": "About",
  "@aboutTitle": {},
  "aboutDescription": "A journal-style mood tracker that stays on your device.",
  "@aboutDescription": {},
  "aboutVersion": "Version",
  "@aboutVersion": {},
  "aboutViewLicenses": "View open-source licenses",
  "@aboutViewLicenses": {},

  "onboardingSkip": "Skip",
  "@onboardingSkip": {},
  "onboardingNext": "Next",
  "@onboardingNext": {},
  "onboardingGetStarted": "Get started",
  "@onboardingGetStarted": {},
  "onboardingWhatTitle": "Track how you feel",
  "@onboardingWhatTitle": {},
  "onboardingWhatBody": "Capture your mood, intensity, and a quick note in seconds.",
  "@onboardingWhatBody": {},
  "onboardingHowTitle": "Tap a face",
  "@onboardingHowTitle": {},
  "onboardingHowBody": "Pick a mood, adjust the slider, and you're done.",
  "@onboardingHowBody": {},
  "onboardingPrivacyTitle": "Your data stays here",
  "@onboardingPrivacyTitle": {},
  "onboardingPrivacyBody": "No accounts, no cloud — everything lives on this device.",
  "@onboardingPrivacyBody": {}
}
```

- [x] **Step 2: Regenerate l10n**

Run: `flutter gen-l10n`
Expected: `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_en.dart` regenerate. They stay gitignored.

- [x] **Step 3: Verify + commit**

- `flutter analyze` → 0 issues
- `flutter test` → all 56 tests still pass (no consumer of the new keys yet)
- `git status --short` should NOT show `app_localizations*.dart`

```bash
git add lib/l10n/app_en.arb
git commit -m "feat(l10n): add Phase 2 ARB keys (settings, onboarding, about, theme)"
```

---

## Task 4: Spanish translations

**Files:**
- Create: `lib/l10n/app_es.arb`

- [x] **Step 1: Create `lib/l10n/app_es.arb`**

The full file mirrors every English key:

```json
{
  "@@locale": "es",

  "appTitle": "Rastreador de Ánimo",
  "@appTitle": {},

  "todayGreetingMorning": "Buenos días",
  "@todayGreetingMorning": {},
  "todayGreetingAfternoon": "Buenas tardes",
  "@todayGreetingAfternoon": {},
  "todayGreetingEvening": "Buenas noches",
  "@todayGreetingEvening": {},
  "todayPrompt": "¿Cómo te sientes ahora?",
  "@todayPrompt": {},
  "todayRecentTitle": "Reciente",
  "@todayRecentTitle": {},
  "todayEmptyMessage": "Registra tu primer estado de ánimo para verlo aquí.",
  "@todayEmptyMessage": {},

  "moodAwful": "Terrible",
  "@moodAwful": {},
  "moodBad": "Mal",
  "@moodBad": {},
  "moodOkay": "Regular",
  "@moodOkay": {},
  "moodGood": "Bien",
  "@moodGood": {},
  "moodGreat": "Genial",
  "@moodGreat": {},

  "energyVeryLow": "Muy baja",
  "@energyVeryLow": {},
  "energyLow": "Baja",
  "@energyLow": {},
  "energyMedium": "Media",
  "@energyMedium": {},
  "energyHigh": "Alta",
  "@energyHigh": {},
  "energyVeryHigh": "Muy alta",
  "@energyVeryHigh": {},

  "logEntryTitle": "¿Cómo te sientes?",
  "@logEntryTitle": {},
  "logEntryFieldIntensity": "Intensidad",
  "@logEntryFieldIntensity": {},
  "logEntryFieldEnergy": "Energía",
  "@logEntryFieldEnergy": {},
  "logEntryFieldSleepHours": "Horas de sueño",
  "@logEntryFieldSleepHours": {},
  "logEntryFieldTags": "Etiquetas",
  "@logEntryFieldTags": {},
  "logEntryFieldNote": "Nota",
  "@logEntryFieldNote": {},
  "logEntryFieldOccurredAt": "Cuándo",
  "@logEntryFieldOccurredAt": {},
  "logEntrySave": "Guardar",
  "@logEntrySave": {},
  "logEntryCancel": "Cancelar",
  "@logEntryCancel": {},
  "logEntryDiscardConfirm": "¿Descartar esta entrada?",
  "@logEntryDiscardConfirm": {},

  "historyTitle": "Historial",
  "@historyTitle": {},
  "historyEmpty": "Aún no has registrado nada.",
  "@historyEmpty": {},
  "historyDelete": "Eliminar entrada",
  "@historyDelete": {},
  "historyDeleteUndo": "Deshacer",
  "@historyDeleteUndo": {},

  "entryDetailTitle": "Entrada",
  "@entryDetailTitle": {},
  "entryDetailEdit": "Editar",
  "@entryDetailEdit": {},
  "entryDetailDelete": "Eliminar",
  "@entryDetailDelete": {},

  "errorTitle": "Algo salió mal",
  "@errorTitle": {},
  "errorRetry": "Intentar de nuevo",
  "@errorRetry": {},
  "errorDatabase": "No se pudo acceder al almacenamiento local.",
  "@errorDatabase": {},
  "errorNotFound": "No encontramos esa entrada.",
  "@errorNotFound": {},
  "errorValidationIntensity": "La intensidad debe estar entre 1 y 10.",
  "@errorValidationIntensity": {},
  "errorValidationSleepHours": "Las horas de sueño deben estar entre 0 y 24.",
  "@errorValidationSleepHours": {},
  "errorUnknown": "Error inesperado.",
  "@errorUnknown": {},

  "navToday": "Hoy",
  "@navToday": {},
  "navHistory": "Historial",
  "@navHistory": {},
  "navCalendar": "Calendario",
  "@navCalendar": {},
  "navInsights": "Estadísticas",
  "@navInsights": {},
  "navSettings": "Ajustes",
  "@navSettings": {},

  "settingsTitle": "Ajustes",
  "@settingsTitle": {},
  "settingsAppearanceSection": "Apariencia",
  "@settingsAppearanceSection": {},
  "settingsLanguageSection": "Idioma",
  "@settingsLanguageSection": {},
  "settingsRemindersSection": "Recordatorios",
  "@settingsRemindersSection": {},
  "settingsAboutSection": "Acerca de",
  "@settingsAboutSection": {},
  "settingsThemeLabel": "Tema",
  "@settingsThemeLabel": {},
  "settingsLanguageLabel": "Idioma",
  "@settingsLanguageLabel": {},
  "settingsRemindersLabel": "Recordatorio diario",
  "@settingsRemindersLabel": {},
  "settingsRemindersComingSoon": "Próximamente en una versión futura",
  "@settingsRemindersComingSoon": {},
  "settingsAboutLabel": "Acerca de la app",
  "@settingsAboutLabel": {},

  "themeLight": "Claro",
  "@themeLight": {},
  "themeDark": "Oscuro",
  "@themeDark": {},
  "themeSystem": "Sistema",
  "@themeSystem": {},

  "aboutTitle": "Acerca de",
  "@aboutTitle": {},
  "aboutDescription": "Un diario de estados de ánimo, todo en tu dispositivo.",
  "@aboutDescription": {},
  "aboutVersion": "Versión",
  "@aboutVersion": {},
  "aboutViewLicenses": "Ver licencias de código abierto",
  "@aboutViewLicenses": {},

  "onboardingSkip": "Omitir",
  "@onboardingSkip": {},
  "onboardingNext": "Siguiente",
  "@onboardingNext": {},
  "onboardingGetStarted": "Empezar",
  "@onboardingGetStarted": {},
  "onboardingWhatTitle": "Registra cómo te sientes",
  "@onboardingWhatTitle": {},
  "onboardingWhatBody": "Captura tu ánimo, intensidad y una nota rápida en segundos.",
  "@onboardingWhatBody": {},
  "onboardingHowTitle": "Toca una cara",
  "@onboardingHowTitle": {},
  "onboardingHowBody": "Elige un ánimo, ajusta el deslizador y listo.",
  "@onboardingHowBody": {},
  "onboardingPrivacyTitle": "Tus datos se quedan aquí",
  "@onboardingPrivacyTitle": {},
  "onboardingPrivacyBody": "Sin cuentas ni nube: todo vive en este dispositivo.",
  "@onboardingPrivacyBody": {}
}
```

- [x] **Step 2: Regenerate l10n**

Run: `flutter gen-l10n`
Expected: `lib/l10n/app_localizations_es.dart` appears (gitignored, not staged). `AppLocalizations.supportedLocales` now contains both `Locale('en')` and `Locale('es')`.

- [x] **Step 3: Verify + commit**

- `flutter analyze` → 0 issues
- `flutter test` → all 56 tests pass

```bash
git add lib/l10n/app_es.arb
git commit -m "feat(l10n): add Spanish translations for all Phase 1 and Phase 2 keys"
```

---

## Task 5: `SettingsSection` + `SettingsTile` widgets

**Files:**
- Create: `lib/features/settings/presentation/widgets/settings_section.dart`
- Create: `lib/features/settings/presentation/widgets/settings_tile.dart`
- Create: `test/features/settings/presentation/widgets/settings_tile_test.dart`

- [x] **Step 1: Implement `settings_tile.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final effectiveOnTap = enabled ? onTap : null;
    final opacity = enabled ? 1.0 : 0.5;

    return Semantics(
      enabled: enabled,
      button: effectiveOnTap != null,
      child: Opacity(
        opacity: opacity,
        child: InkWell(
          onTap: effectiveOnTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(color: colors.onMuted, size: 22),
                    child: leading!,
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTextStyles.body
                              .copyWith(color: colors.onSurface)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: colors.onMuted)),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [x] **Step 2: Implement `settings_section.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_divider.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: colors.onMuted),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const AppDivider(),
          children[i],
        ],
      ],
    );
  }
}
```

- [x] **Step 3: Write widget test for `SettingsTile`**

```dart
// test/features/settings/presentation/widgets/settings_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/settings/presentation/widgets/settings_tile.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders title and subtitle', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: const Scaffold(
        body: SettingsTile(title: 'Theme', subtitle: 'System'),
      ),
    ));
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
  });

  testWidgets('fires onTap when enabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: SettingsTile(
          title: 'Theme',
          onTap: () => taps++,
        ),
      ),
    ));
    await tester.tap(find.byType(SettingsTile));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('ignores onTap when disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: SettingsTile(
          title: 'Reminders',
          enabled: false,
          onTap: () => taps++,
        ),
      ),
    ));
    await tester.tap(find.byType(SettingsTile));
    await tester.pump();
    expect(taps, 0);
  });
}
```

- [x] **Step 4: Verify + commit**

- `flutter test test/features/settings/presentation/widgets/settings_tile_test.dart` → 3 tests pass
- `flutter analyze` → 0 issues
- Full suite: 59 tests pass (56 prior + 3 new)

```bash
git add lib/features/settings/presentation/widgets/settings_section.dart lib/features/settings/presentation/widgets/settings_tile.dart test/features/settings/presentation/widgets/settings_tile_test.dart
git commit -m "feat(settings): add SettingsSection and SettingsTile widgets"
```

---

## Task 6: `ThemePickerSheet` + `LanguagePickerSheet`

**Files:**
- Create: `lib/features/settings/presentation/widgets/theme_picker_sheet.dart`
- Create: `lib/features/settings/presentation/widgets/language_picker_sheet.dart`

- [x] **Step 1: Implement `theme_picker_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_notifier.dart';

class ThemePickerSheet extends ConsumerWidget {
  const ThemePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBR),
      builder: (_) => const ThemePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(themeModeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: current,
              title: Text(l10n.themeLight),
              onChanged: (m) => _select(context, ref, m!),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: current,
              title: Text(l10n.themeDark),
              onChanged: (m) => _select(context, ref, m!),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: current,
              title: Text(l10n.themeSystem),
              onChanged: (m) => _select(context, ref, m!),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(BuildContext context, WidgetRef ref, ThemeMode mode) async {
    await ref.read(themeModeProvider.notifier).setMode(mode);
    if (context.mounted) Navigator.of(context).pop();
  }
}
```

- [x] **Step 2: Implement `language_picker_sheet.dart`**

```dart
import 'dart:ui' show Locale;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../../../../core/l10n/locale_notifier.dart';
import '../../../../core/l10n/native_name.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class LanguagePickerSheet extends ConsumerWidget {
  const LanguagePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBR),
      builder: (_) => const LanguagePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final locales = AppLocalizations.supportedLocales;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final locale in locales)
              RadioListTile<Locale>(
                value: locale,
                groupValue: current ?? const Locale('en'),
                title: Text(nativeNameFor(locale)),
                onChanged: (l) => _select(context, ref, l!),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(BuildContext context, WidgetRef ref, Locale locale) async {
    await ref.read(localeProvider.notifier).setLocale(locale);
    if (context.mounted) Navigator.of(context).pop();
  }
}
```

- [x] **Step 3: Verify + commit**

- `flutter analyze` → 0 issues
- `flutter test` → all 59 tests pass (no new tests in this task; both sheets are exercised in the SettingsScreen widget test in Task 8)

```bash
git add lib/features/settings/presentation/widgets/theme_picker_sheet.dart lib/features/settings/presentation/widgets/language_picker_sheet.dart
git commit -m "feat(settings): add theme and language picker bottom sheets"
```

---

## Task 7: `SettingsController` + `SettingsViewModel`

**Files:**
- Create: `lib/features/settings/providers/settings_controller.dart`
- Create: `test/features/settings/providers/settings_controller_test.dart`

- [x] **Step 1: Write the failing test**

```dart
// test/features/settings/providers/settings_controller_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/features/settings/providers/settings_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences sp;
  late AppPrefs prefs;
  late ProviderContainer container;

  setUp(() async {
    PackageInfo.setMockInitialValues(
      appName: 'mood_tracker',
      packageName: 'com.example.mood_tracker',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({});
    sp = await SharedPreferences.getInstance();
    prefs = AppPrefs(sp);
    container = ProviderContainer(overrides: [
      appPrefsProvider.overrideWithValue(prefs),
    ]);
  });

  tearDown(() => container.dispose());

  test('build returns the current theme, locale, and app version', () async {
    final vm = await container.read(settingsControllerProvider.future);
    expect(vm.themeMode, ThemeMode.system);
    expect(vm.locale, isNull);
    expect(vm.appVersion, '1.0.0');
  });

  test('setTheme updates the underlying provider and persists', () async {
    final notifier = container.read(settingsControllerProvider.notifier);
    await container.read(settingsControllerProvider.future);
    await notifier.setTheme(ThemeMode.dark);
    final vm = container.read(settingsControllerProvider).value!;
    expect(vm.themeMode, ThemeMode.dark);
    expect(prefs.themeMode, AppThemeMode.dark);
  });

  test('setLocale updates the underlying provider and persists', () async {
    final notifier = container.read(settingsControllerProvider.notifier);
    await container.read(settingsControllerProvider.future);
    await notifier.setLocale(const Locale('es'));
    final vm = container.read(settingsControllerProvider).value!;
    expect(vm.locale, const Locale('es'));
    expect(prefs.localeTag, 'es');
  });
}
```

- [x] **Step 2: FAIL**

Run: `flutter test test/features/settings/providers/settings_controller_test.dart`
Expected: FAIL — symbols undefined.

- [x] **Step 3: Implement `lib/features/settings/providers/settings_controller.dart`**

```dart
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/l10n/locale_notifier.dart';
import '../../../core/theme/theme_notifier.dart';

@immutable
class SettingsViewModel {
  const SettingsViewModel({
    required this.themeMode,
    required this.locale,
    required this.appVersion,
  });

  final ThemeMode themeMode;
  final Locale? locale;
  final String appVersion;
}

class SettingsController extends AsyncNotifier<SettingsViewModel> {
  @override
  Future<SettingsViewModel> build() async {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final info = await PackageInfo.fromPlatform();
    return SettingsViewModel(
      themeMode: themeMode,
      locale: locale,
      appVersion: info.version,
    );
  }

  Future<void> setTheme(ThemeMode mode) =>
      ref.read(themeModeProvider.notifier).setMode(mode);

  Future<void> setLocale(Locale? locale) =>
      ref.read(localeProvider.notifier).setLocale(locale);
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsViewModel>(
  SettingsController.new,
);
```

- [x] **Step 4: Verify + commit**

- `flutter test test/features/settings/providers/settings_controller_test.dart` → 3 tests pass
- `flutter analyze` → 0 issues
- Full suite: 62 tests pass

```bash
git add lib/features/settings/providers/settings_controller.dart test/features/settings/providers/settings_controller_test.dart
git commit -m "feat(settings): add SettingsController with view-model exposing theme, locale, and app version"
```

---

## Task 8: `SettingsScreen`

**Files:**
- Replace: `lib/features/settings/presentation/screens/settings_screen.dart` (does not yet exist as a file — the router currently uses an inline `_PlaceholderScreen('Settings')`; this task adds a real screen and Task 14 wires the router to use it)
- Create: `test/features/settings/presentation/settings_screen_test.dart`

- [x] **Step 1: Implement `settings_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/l10n/native_name.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../providers/settings_controller.dart';
import '../widgets/language_picker_sheet.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/theme_picker_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          failure: e is Failure ? e : UnknownFailure(cause: e),
        ),
        data: (vm) => ListView(
          children: [
            SettingsSection(
              title: l10n.settingsAppearanceSection,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: l10n.settingsThemeLabel,
                  subtitle: _themeLabel(l10n, vm.themeMode),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ThemePickerSheet.show(context),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.settingsLanguageSection,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.translate),
                  title: l10n.settingsLanguageLabel,
                  subtitle: nativeNameFor(vm.locale ?? const Locale('en')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => LanguagePickerSheet.show(context),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.settingsRemindersSection,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: l10n.settingsRemindersLabel,
                  subtitle: l10n.settingsRemindersComingSoon,
                  enabled: false,
                ),
              ],
            ),
            SettingsSection(
              title: l10n.settingsAboutSection,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.info_outline),
                  title: l10n.settingsAboutLabel,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.about),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
        ThemeMode.light => l10n.themeLight,
        ThemeMode.dark => l10n.themeDark,
        ThemeMode.system => l10n.themeSystem,
      };
}
```

- [x] **Step 2: Write the widget test**

```dart
// test/features/settings/presentation/settings_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    PackageInfo.setMockInitialValues(
      appName: 'mood_tracker',
      packageName: 'com.example.mood_tracker',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('renders all four sections', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        appPrefsProvider.overrideWithValue(AppPrefs(sp)),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('LANGUAGE'), findsOneWidget);
    expect(find.text('REMINDERS'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Daily reminder'), findsOneWidget);
    expect(find.text('Coming in a future update'), findsOneWidget);
  });
}
```

- [x] **Step 3: Verify + commit**

- `flutter test test/features/settings/presentation/settings_screen_test.dart` → 1 test passes
- `flutter analyze` → 0 issues
- Full suite: 63 tests pass

```bash
git add lib/features/settings/presentation/screens/settings_screen.dart test/features/settings/presentation/settings_screen_test.dart
git commit -m "feat(settings): implement SettingsScreen with appearance, language, reminders-stub, and about sections"
```

---

## Task 9: `AboutScreen`

**Files:**
- Create: `lib/features/settings/presentation/screens/about_screen.dart`
- Create: `test/features/settings/presentation/about_screen_test.dart`

- [x] **Step 1: Implement `about_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mood_face.dart';
import '../../../mood_entry/domain/enums/mood.dart';
import '../../providers/settings_controller.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final async = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (vm) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  MoodFace(mood: Mood.good, color: colors.primary, size: 64),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.appTitle, style: AppTextStyles.headline),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${l10n.aboutVersion} ${vm.appVersion}',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: colors.onMuted),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.aboutDescription,
                    style: AppTextStyles.body.copyWith(color: colors.onMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SettingsSection(
              title: l10n.aboutTitle,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.description_outlined),
                  title: l10n.aboutViewLicenses,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: l10n.appTitle,
                    applicationVersion: vm.appVersion,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 2: Write the widget test**

```dart
// test/features/settings/presentation/about_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/settings/presentation/screens/about_screen.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    PackageInfo.setMockInitialValues(
      appName: 'mood_tracker',
      packageName: 'com.example.mood_tracker',
      version: '1.2.3',
      buildNumber: '7',
      buildSignature: '',
    );
  });

  testWidgets('renders app title and version', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        appPrefsProvider.overrideWithValue(AppPrefs(sp)),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AboutScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Mood Tracker'), findsOneWidget);
    expect(find.text('Version 1.2.3'), findsOneWidget);
    expect(find.text('View open-source licenses'), findsOneWidget);
  });
}
```

- [x] **Step 3: Verify + commit**

- `flutter test test/features/settings/presentation/about_screen_test.dart` → 1 test passes
- `flutter analyze` → 0 issues
- Full suite: 64 tests pass

```bash
git add lib/features/settings/presentation/screens/about_screen.dart test/features/settings/presentation/about_screen_test.dart
git commit -m "feat(settings): add AboutScreen with version, description, and licenses"
```

---

## Task 10: `OnboardingController`

**Files:**
- Create: `lib/features/onboarding/providers/onboarding_controller.dart`
- Create: `test/features/onboarding/providers/onboarding_controller_test.dart`

- [x] **Step 1: Write the failing test**

```dart
// test/features/onboarding/providers/onboarding_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/features/onboarding/providers/onboarding_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppPrefs prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    prefs = AppPrefs(sp);
    container = ProviderContainer(overrides: [
      appPrefsProvider.overrideWithValue(prefs),
    ]);
  });

  tearDown(() => container.dispose());

  test('initial page is 0', () {
    final notifier = container.read(onboardingControllerProvider.notifier);
    notifier; // initialize
    expect(container.read(onboardingControllerProvider), 0);
  });

  test('setPage updates state', () {
    final notifier = container.read(onboardingControllerProvider.notifier);
    notifier.setPage(2);
    expect(container.read(onboardingControllerProvider), 2);
  });

  test('complete writes onboardingCompleted to prefs', () async {
    final notifier = container.read(onboardingControllerProvider.notifier);
    await notifier.complete();
    expect(prefs.onboardingCompleted, isTrue);
  });
}
```

- [x] **Step 2: FAIL**

Run: `flutter test test/features/onboarding/providers/onboarding_controller_test.dart`
Expected: FAIL — symbols undefined.

- [x] **Step 3: Implement `lib/features/onboarding/providers/onboarding_controller.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/infrastructure_providers.dart';
import '../../../core/prefs/app_prefs.dart';

class OnboardingController extends Notifier<int> {
  late AppPrefs _prefs;

  @override
  int build() {
    _prefs = ref.watch(appPrefsProvider);
    return 0;
  }

  void setPage(int page) => state = page;

  Future<void> complete() => _prefs.setOnboardingCompleted(true);
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, int>(OnboardingController.new);
```

- [x] **Step 4: Verify + commit**

- `flutter test test/features/onboarding/providers/onboarding_controller_test.dart` → 3 tests pass
- `flutter analyze` → 0 issues
- Full suite: 67 tests pass

```bash
git add lib/features/onboarding/providers/onboarding_controller.dart test/features/onboarding/providers/onboarding_controller_test.dart
git commit -m "feat(onboarding): add OnboardingController with page index and completion"
```

---

## Task 11: Three `CustomPainter` illustrations

**Files:**
- Create: `lib/features/onboarding/presentation/widgets/illustration_what.dart`
- Create: `lib/features/onboarding/presentation/widgets/illustration_how.dart`
- Create: `lib/features/onboarding/presentation/widgets/illustration_privacy.dart`
- Create: `test/features/onboarding/presentation/widgets/illustrations_test.dart`

- [x] **Step 1: Implement `illustration_what.dart`**

A "journal page" rectangle with horizontal stroke lines (representing text rows) and a centered `MoodFace`.

```dart
import 'package:flutter/material.dart';

import '../../../../core/widgets/mood_face.dart';
import '../../../mood_entry/domain/enums/mood.dart';

class IllustrationWhat extends StatelessWidget {
  const IllustrationWhat({super.key, required this.color, this.size = 200});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _JournalPainter(color: color),
          ),
          MoodFace(mood: Mood.good, color: color, size: size * 0.32),
        ],
      ),
    );
  }
}

class _JournalPainter extends CustomPainter {
  _JournalPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final pageRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.12,
          size.width * 0.64, size.height * 0.76),
      const Radius.circular(12),
    );
    canvas.drawRRect(pageRect, stroke);

    // Header line (just above the face)
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.26),
      Offset(size.width * 0.6, size.height * 0.26),
      stroke,
    );

    // Lines below the face
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.72 + i * 0.07);
      canvas.drawLine(
        Offset(size.width * 0.28, y),
        Offset(size.width * (0.72 - i * 0.06), y),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _JournalPainter old) => old.color != color;
}
```

- [x] **Step 2: Implement `illustration_how.dart`**

A `MoodCard`-shaped rounded rectangle with a `MoodFace` inside, plus a stylized finger silhouette tapping it.

```dart
import 'package:flutter/material.dart';

import '../../../../core/widgets/mood_face.dart';
import '../../../mood_entry/domain/enums/mood.dart';

class IllustrationHow extends StatelessWidget {
  const IllustrationHow({
    super.key,
    required this.color,
    required this.accent,
    this.size = 200,
  });

  final Color color;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _CardAndFingerPainter(card: accent, finger: color),
          ),
          Align(
            alignment: const Alignment(0, -0.15),
            child: MoodFace(mood: Mood.great, color: accent, size: size * 0.28),
          ),
        ],
      ),
    );
  }
}

class _CardAndFingerPainter extends CustomPainter {
  _CardAndFingerPainter({required this.card, required this.finger});

  final Color card;
  final Color finger;

  @override
  void paint(Canvas canvas, Size size) {
    final cardStroke = Paint()
      ..color = card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.18,
          size.width * 0.64, size.height * 0.58),
      const Radius.circular(20),
    );
    canvas.drawRRect(cardRect, cardStroke);

    final fingerPaint = Paint()
      ..color = finger
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Finger: rounded rectangle (the finger) + small circle (the fingertip dot)
    final fingerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.58,
          size.width * 0.12, size.height * 0.26),
      const Radius.circular(20),
    );
    canvas.drawRRect(fingerRect, fingerPaint);

    canvas.drawCircle(
      Offset(size.width * 0.61, size.height * 0.55),
      size.width * 0.025,
      fingerPaint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _CardAndFingerPainter old) =>
      old.card != card || old.finger != finger;
}
```

- [x] **Step 3: Implement `illustration_privacy.dart`**

A phone outline with three tiny mood faces inside and a small padlock above.

```dart
import 'package:flutter/material.dart';

import '../../../../core/widgets/mood_face.dart';
import '../../../mood_entry/domain/enums/mood.dart';

class IllustrationPrivacy extends StatelessWidget {
  const IllustrationPrivacy({super.key, required this.color, this.size = 200});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _PhoneAndLockPainter(color: color),
          ),
          Align(
            alignment: const Alignment(-0.32, 0.3),
            child: MoodFace(mood: Mood.bad, color: color, size: size * 0.14),
          ),
          Align(
            alignment: Alignment.center.add(const Alignment(0, 0.3)),
            child: MoodFace(mood: Mood.okay, color: color, size: size * 0.14),
          ),
          Align(
            alignment: const Alignment(0.32, 0.3),
            child: MoodFace(mood: Mood.good, color: color, size: size * 0.14),
          ),
        ],
      ),
    );
  }
}

class _PhoneAndLockPainter extends CustomPainter {
  _PhoneAndLockPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Phone outline
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.28, size.height * 0.18,
          size.width * 0.44, size.height * 0.74),
      const Radius.circular(20),
    );
    canvas.drawRRect(phoneRect, stroke);

    // Padlock above the phone
    final lockBodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.42, size.height * 0.06,
          size.width * 0.16, size.height * 0.1),
      const Radius.circular(4),
    );
    canvas.drawRRect(lockBodyRect, stroke);

    // Padlock shackle
    final shacklePath = Path()
      ..moveTo(size.width * 0.44, size.height * 0.06)
      ..arcToPoint(
        Offset(size.width * 0.56, size.height * 0.06),
        radius: const Radius.circular(8),
        clockwise: true,
      )
      ..lineTo(size.width * 0.56, size.height * 0.06);
    canvas.drawPath(shacklePath, stroke);
  }

  @override
  bool shouldRepaint(covariant _PhoneAndLockPainter old) => old.color != color;
}
```

- [x] **Step 4: Smoke test (no goldens — just pump and confirm no exceptions)**

```dart
// test/features/onboarding/presentation/widgets/illustrations_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/onboarding/presentation/widgets/illustration_how.dart';
import 'package:mood_tracker/features/onboarding/presentation/widgets/illustration_privacy.dart';
import 'package:mood_tracker/features/onboarding/presentation/widgets/illustration_what.dart';

void main() {
  testWidgets('illustrations pump without exceptions', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            IllustrationWhat(color: Colors.black),
            IllustrationHow(color: Colors.black, accent: Colors.purple),
            IllustrationPrivacy(color: Colors.black),
          ],
        ),
      ),
    ));
    expect(find.byType(IllustrationWhat), findsOneWidget);
    expect(find.byType(IllustrationHow), findsOneWidget);
    expect(find.byType(IllustrationPrivacy), findsOneWidget);
  });
}
```

- [x] **Step 5: Verify + commit**

- `flutter test test/features/onboarding/presentation/widgets/illustrations_test.dart` → 1 test passes
- `flutter analyze` → 0 issues
- Full suite: 68 tests pass

```bash
git add lib/features/onboarding/presentation/widgets/illustration_what.dart lib/features/onboarding/presentation/widgets/illustration_how.dart lib/features/onboarding/presentation/widgets/illustration_privacy.dart test/features/onboarding/presentation/widgets/illustrations_test.dart
git commit -m "feat(onboarding): add three CustomPainter illustrations"
```

---

## Task 12: `OnboardingPage` widget

**Files:**
- Create: `lib/features/onboarding/presentation/widgets/onboarding_page.dart`

- [x] **Step 1: Implement**

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.illustration,
    required this.title,
    required this.body,
  });

  final Widget illustration;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          illustration,
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: AppTextStyles.headline.copyWith(color: colors.onBackground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: AppTextStyles.body.copyWith(color: colors.onMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```

- [x] **Step 2: Verify + commit**

No test in this task; the page is exercised through `OnboardingScreen` in Task 13.

- `flutter analyze` → 0 issues

```bash
git add lib/features/onboarding/presentation/widgets/onboarding_page.dart
git commit -m "feat(onboarding): add OnboardingPage layout widget"
```

---

## Task 13: `OnboardingScreen`

**Files:**
- Create: `lib/features/onboarding/presentation/screens/onboarding_screen.dart`
- Create: `test/features/onboarding/presentation/onboarding_screen_test.dart`

- [x] **Step 1: Implement `onboarding_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../providers/onboarding_controller.dart';
import '../widgets/illustration_how.dart';
import '../widgets/illustration_privacy.dart';
import '../widgets/illustration_what.dart';
import '../widgets/onboarding_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider.notifier).complete();
    if (mounted) context.go(AppRoutes.today);
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final page = ref.watch(onboardingControllerProvider);
    final isLast = page == 2;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(l10n.onboardingSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => ref
                    .read(onboardingControllerProvider.notifier)
                    .setPage(i),
                children: [
                  OnboardingPage(
                    illustration: IllustrationWhat(color: colors.primary),
                    title: l10n.onboardingWhatTitle,
                    body: l10n.onboardingWhatBody,
                  ),
                  OnboardingPage(
                    illustration: IllustrationHow(
                      color: colors.onBackground,
                      accent: colors.primary,
                    ),
                    title: l10n.onboardingHowTitle,
                    body: l10n.onboardingHowBody,
                  ),
                  OnboardingPage(
                    illustration: IllustrationPrivacy(color: colors.primary),
                    title: l10n.onboardingPrivacyTitle,
                    body: l10n.onboardingPrivacyBody,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    Container(
                      width: i == page ? 12 : 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: i == page ? colors.primary : colors.muted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                  const Spacer(),
                  FilledButton(
                    onPressed: isLast ? _finish : _next,
                    child: Text(isLast
                        ? l10n.onboardingGetStarted
                        : l10n.onboardingNext),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 2: Write the widget test**

```dart
// test/features/onboarding/presentation/onboarding_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/navigation/app_routes.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<({AppPrefs prefs, GoRouter router})> _pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final prefs = AppPrefs(sp);
    final router = GoRouter(
      initialLocation: AppRoutes.onboarding,
      routes: [
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.today,
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('Today'))),
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [appPrefsProvider.overrideWithValue(prefs)],
      child: MaterialApp.router(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
    return (prefs: prefs, router: router);
  }

  testWidgets('first page renders, Next advances, Get started completes',
      (tester) async {
    final state = await _pump(tester);

    // Page 0
    expect(find.text('Track how you feel'), findsOneWidget);

    // Tap Next → page 1
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Tap a face'), findsOneWidget);

    // Tap Next → page 2 (last)
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your data stays here'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);

    // Tap Get started → completes + navigates to Today
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(state.prefs.onboardingCompleted, isTrue);
  });

  testWidgets('Skip completes and navigates to Today', (tester) async {
    final state = await _pump(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(state.prefs.onboardingCompleted, isTrue);
  });
}
```

- [x] **Step 3: Verify + commit**

- `flutter test test/features/onboarding/presentation/onboarding_screen_test.dart` → 2 tests pass
- `flutter analyze` → 0 issues
- Full suite: 70 tests pass

```bash
git add lib/features/onboarding/presentation/screens/onboarding_screen.dart test/features/onboarding/presentation/onboarding_screen_test.dart
git commit -m "feat(onboarding): implement OnboardingScreen PageView with Skip + Next + Get started"
```

---

## Task 14: Router updates — redirect, `/onboarding`, `/settings/about`, real Settings

**Files:**
- Modify: `lib/core/navigation/app_router.dart`
- Create: `test/core/navigation/app_router_redirect_test.dart`

- [x] **Step 1: Replace `lib/core/navigation/app_router.dart`**

The full file becomes:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/history/presentation/screens/entry_detail_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/mood_entry/presentation/screens/log_entry_sheet.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/today/presentation/screens/today_screen.dart';
import '../di/infrastructure_providers.dart';
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
    redirect: (context, state) {
      final completed = ref.read(appPrefsProvider).onboardingCompleted;
      final atOnboarding = state.uri.path == AppRoutes.onboarding;
      if (!completed && !atOnboarding) return AppRoutes.onboarding;
      if (completed && atOnboarding) return AppRoutes.today;
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.today,
              builder: (context, _) => const TodayScreen(),
              routes: [
                GoRoute(
                  path: 'log',
                  pageBuilder: (context, _) => const MaterialPage(
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
              builder: (context, _) => const HistoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.calendar,
              builder: (context, _) => const _PlaceholderScreen('Calendar'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.insights,
              builder: (context, _) => const _PlaceholderScreen('Insights'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, _) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'about',
                  builder: (context, _) => const AboutScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.entryDetail}/:id',
        builder: (context, state) =>
            EntryDetailScreen(entryId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            pageBuilder: (context, state) => MaterialPage(
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
      _NavDest(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Today'),
      _NavDest(icon: Icons.list_alt_outlined, selectedIcon: Icons.list_alt, label: 'History'),
      _NavDest(icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today, label: 'Calendar'),
      _NavDest(icon: Icons.show_chart_outlined, selectedIcon: Icons.show_chart, label: 'Insights'),
      _NavDest(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
    ];
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _NavDest {
  const _NavDest(
      {required this.icon, required this.selectedIcon, required this.label});
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
```

Note: this preserves the bottom-nav literal labels from Phase 1 (Calendar/Insights remain `_PlaceholderScreen`s for Phases 3/4). Settings is now a real screen with a nested `/settings/about` child route.

- [x] **Step 2: Write the redirect test**

```dart
// test/core/navigation/app_router_redirect_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/navigation/app_router.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/mood_entry/data/mood_entry_repository_provider.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/entry_query.dart';
import 'package:mood_tracker/features/mood_entry/domain/repositories/mood_entry_repository.dart';
import 'package:mood_tracker/core/error/failure.dart';
import 'package:mood_tracker/core/error/result.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Future<Widget> _appWith({required bool onboardingCompleted}) async {
  SharedPreferences.setMockInitialValues(
    onboardingCompleted ? {'app.onboardingCompleted': true} : {},
  );
  final sp = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      appPrefsProvider.overrideWithValue(AppPrefs(sp)),
      moodEntryRepositoryProvider.overrideWithValue(_EmptyRepo()),
    ],
    child: Consumer(builder: (context, ref, _) {
      final router = ref.watch(appRouterProvider);
      return MaterialApp.router(
        theme: ThemeData(extensions: const [AppColors.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      );
    }),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    PackageInfo.setMockInitialValues(
      appName: 'mood_tracker',
      packageName: 'com.example.mood_tracker',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('first run lands on /onboarding', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(await _appWith(onboardingCompleted: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('completed-onboarding run lands on /today', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(await _appWith(onboardingCompleted: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('How are you feeling right now?'), findsOneWidget);
  });
}
```

- [x] **Step 3: Verify + commit**

- `flutter test test/core/navigation/app_router_redirect_test.dart` → 2 tests pass
- `flutter analyze` → 0 issues
- Full suite: 72 tests pass

```bash
git add lib/core/navigation/app_router.dart test/core/navigation/app_router_redirect_test.dart
git commit -m "feat(navigation): add onboarding redirect, /onboarding route, /settings/about, and real SettingsScreen wiring"
```

---

## Task 15: Final validation pass

- [x] **Step 1: Analyze must be clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [x] **Step 2: Full test suite must pass**

Run: `flutter test`
Expected: 72 tests pass (54 Phase 1 + 18 new Phase 2).

If any test fails, fix it before declaring Phase 2 complete. Likely sources of trouble:
- `SettingsScreen` widget test viewport — if the four sections don't fit at 800×600, set `tester.view.physicalSize = const Size(1080, 1920)` in `setUp` and add the matching tear-down (same pattern as Task 23/25 in Phase 1).
- ARB key typos — run `flutter gen-l10n` and inspect any compile errors at `lib/l10n/app_localizations.dart`.
- Spanish translation strings — verify every key in `app_es.arb` has a matching key in `app_en.arb`. Missing keys cause `flutter gen-l10n` to emit warnings.

- [ ] **Step 3: Manual smoke run (optional — skip if no device)** *(skipped — no device available; deferred to the developer)*

If a simulator or device is available:

```bash
flutter run -d <device>
```

Verify:
- First launch lands on Onboarding. Tap Next twice → Get started → Today.
- Open Settings tab → Theme → switch to Dark → app switches theme. Re-open → confirm subtitle shows "Dark".
- Open Settings → Language → switch to Español → app re-renders in Spanish; the bottom-nav labels also localize (post-review fix in commit `800886d` wired `_MainShell` to `context.l10n`).
- Reminders row shows "Coming in a future update", is not tappable.
- About → version shows the package version, View licenses opens the standard `showLicensePage`.
- Hot-restart → app skips onboarding (prefs persists).

- [ ] **Step 4: No commit needed unless smoke-test issues surface** *(N/A — manual run was not executed)*

If smoke-test issues surface, file them as follow-ups; do not silently amend.

---

## Phase 2 complete

When Task 15 passes, Phase 2 is done. The next plan to write is Phase 3 (Calendar + Search) against the same spec.
