# Mood Tracker — Phase 2 Design Spec

**Date:** 2026-05-18
**Status:** Approved (scope refinement on top of the [2026-05-17 master spec](2026-05-17-mood-tracker-design.md))
**Predecessor:** Phase 1 (foundation + first vertical slice) complete on `main`, 54 tests green.

This is a per-phase scope refinement, not a fresh architectural design. The master spec governs all architectural decisions (Clean Arch layering, Riverpod, Drift, GoRouter, error model, theming, etc.). This document covers only what Phase 2 adds and modifies.

## 1. Goal

Replace the Settings + Onboarding placeholders inserted in Phase 1's GoRouter shell with real screens, ship Spanish localizations for every existing key plus the new ones, and enforce a first-run onboarding redirect.

## 2. Scope

**In:**

- `features/settings/` — three sections (Appearance, Language, About) plus a disabled Reminders row that previews Phase 5.
- `features/onboarding/` — 3-page first-run intro with `CustomPainter` illustrations and a GoRouter redirect.
- `lib/l10n/app_es.arb` — full Spanish translation of every key (Phase 1 + Phase 2).
- `AppPrefs.onboardingCompleted` boolean.
- New routes: `/onboarding` (top-level), `/settings/about`.
- `package_info_plus` dependency for the About screen's version display.

**Out of scope (deferred):**

- Reminder scheduling, permission flows, `flutter_local_notifications` integration — Phase 5.
- Custom palette pickers / Material You / dynamic theming — indefinite defer.
- Onboarding deep-linking (the user can't enter onboarding mid-flow; it's first-run or unreachable).
- Locale-aware date/time formatting beyond what `intl` does by default once `MaterialApp.locale` is honored.

## 3. File additions and modifications

```
lib/
  features/
    settings/
      presentation/
        screens/
          settings_screen.dart           # NEW — replaces Phase 1 placeholder
          about_screen.dart              # NEW
        widgets/
          settings_section.dart          # NEW — header + grouped tiles
          settings_tile.dart             # NEW — title + subtitle + trailing chevron/switch
          theme_picker_sheet.dart        # NEW — modal bottom sheet, 3 radio rows
          language_picker_sheet.dart     # NEW — modal bottom sheet, 2 radio rows
      providers/
        settings_controller.dart         # NEW — Notifier<SettingsViewModel>
    onboarding/
      presentation/
        screens/
          onboarding_screen.dart         # NEW — PageView host
        widgets/
          onboarding_page.dart           # NEW — illustration + title + body layout
          illustration_what.dart         # NEW — CustomPainter
          illustration_how.dart          # NEW — CustomPainter
          illustration_privacy.dart      # NEW — CustomPainter
      providers/
        onboarding_controller.dart       # NEW — Notifier<int> + complete()
  core/
    prefs/app_prefs.dart                 # MODIFY — add onboardingCompleted
    navigation/
      app_routes.dart                    # MODIFY — add onboarding, about constants
      app_router.dart                    # MODIFY — add /onboarding route + redirect, add /settings/about route
  l10n/
    app_en.arb                           # MODIFY — add ~25 settings/onboarding/about keys
    app_es.arb                           # NEW — full Spanish translation
pubspec.yaml                             # MODIFY — add package_info_plus
test/
  core/prefs/app_prefs_test.dart         # MODIFY — onboardingCompleted round-trip
  features/settings/...                  # NEW — controller + widget tests
  features/onboarding/...                # NEW — widget + redirect tests
```

## 4. Settings tab

`SettingsScreen` is a single `ListView` (no scaffolded scrollbar — this is a phone screen) of `SettingsSection`s.

### 4.1 SettingsSection structure

```dart
class SettingsSection extends StatelessWidget {
  const SettingsSection({required this.title, required this.children});
  final String title;            // section header label
  final List<Widget> children;   // typically SettingsTiles
}
```

Visual: header text in `AppTextStyles.label` (uppercase, `colors.onMuted`), padded; children stacked with `AppDivider` between rows.

### 4.2 SettingsTile structure

```dart
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });
}
```

When `enabled: false`, the tile renders at 0.5 opacity, `onTap` is ignored, and `Semantics(enabled: false)` is set.

### 4.3 Sections

- **Appearance** (one tile):
  - **Theme** — leading `Icons.palette_outlined`; subtitle is the current mode's localized label (`l10n.themeLight` / `themeDark` / `themeSystem`); trailing chevron; `onTap` opens `ThemePickerSheet`.
- **Language** (one tile):
  - **Language** — leading `Icons.translate`; subtitle is the current locale's native name (`English` or `Español`); trailing chevron; `onTap` opens `LanguagePickerSheet`.
- **Reminders** (one tile):
  - **Daily reminder** — leading `Icons.notifications_outlined`; subtitle `l10n.settingsRemindersComingSoon`; `enabled: false`. Visual cue that the feature exists and is on the roadmap.
- **About** (one tile):
  - **About** — leading `Icons.info_outline`; no subtitle; trailing chevron; `onTap` navigates to `/settings/about`.

### 4.4 ThemePickerSheet

Modal bottom sheet (`showModalBottomSheet`), rounded top via `AppRadius.sheetBR`, listing three `RadioListTile<ThemeMode>` rows (Light/Dark/System). Selection calls `ref.read(themeModeProvider.notifier).setMode(...)` and dismisses with `context.pop()`. The screen rebuilds because `themeModeProvider` is watched at the app root.

### 4.5 LanguagePickerSheet

Same shape, two rows (English/Español), wires to `localeProvider.notifier.setLocale(Locale('en') | Locale('es'))`. Picker options iterate `AppLocalizations.supportedLocales` so adding a third locale in a future phase Just Works.

### 4.6 SettingsController + view model

```dart
class SettingsViewModel {
  final ThemeMode themeMode;
  final Locale? locale;          // null means "follow system"
  final String appVersion;       // for About; resolved via package_info_plus
}

class SettingsController extends AsyncNotifier<SettingsViewModel> { ... }

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsViewModel>(SettingsController.new);
```

`build()` reads `themeModeProvider`, `localeProvider`, and calls `PackageInfo.fromPlatform()` once. Setters delegate to the underlying providers.

`appVersion` is loaded once at controller build (no setter). The About screen reads it from the controller.

### 4.7 AboutScreen

Simple `ListView`:

- App icon (a small `MoodFace(mood: Mood.good, size: 48)` painted in primary) + app title + version `v$appVersion`.
- One-line `l10n.aboutDescription`.
- Tile: "View licenses" → `showLicensePage(context: context, applicationName: l10n.appTitle, applicationVersion: viewModel.appVersion)` (where `viewModel` is the unwrapped `SettingsViewModel` from `ref.watch(settingsControllerProvider).valueOrNull`; the tile is hidden while the controller is still loading).

## 5. Onboarding

### 5.1 OnboardingScreen

Root widget: `Scaffold` (no AppBar) with:

- **Top-right action**: `TextButton(l10n.onboardingSkip, onPressed: controller.complete + go-to-today)`.
- **Body**: `PageView.builder(itemCount: 3, controller: pageController, onPageChanged: controller.setPage)`.
- **Bottom row**: 3-dot indicator (each dot is a 8pt circle, current dot is filled with `colors.primary` and 1.2× scaled; others are `colors.muted`) + a `FilledButton` whose label is `l10n.onboardingNext` on pages 0-1 and `l10n.onboardingGetStarted` on page 2.

Tapping the button on pages 0-1 advances the PageView via `pageController.nextPage(...)`. On page 2 it calls `controller.complete()` and `context.go(AppRoutes.today)`.

### 5.2 OnboardingPage

```dart
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    required this.illustration,
    required this.title,
    required this.body,
  });
  final Widget illustration;
  final String title;
  final String body;
}
```

Vertical layout: 200pt-square illustration centered horizontally, `AppSpacing.lg` gap, title (`AppTextStyles.headline`, centered), `AppSpacing.xs` gap, body (`AppTextStyles.body`, centered, `colors.onMuted`). Whole page is padded `AppSpacing.xl` on the sides.

### 5.3 OnboardingController

```dart
class OnboardingController extends Notifier<int> {
  late AppPrefs _prefs;

  @override
  int build() {
    _prefs = ref.watch(appPrefsProvider);
    return 0;
  }

  void setPage(int page) => state = page;

  Future<void> complete() async {
    await _prefs.setOnboardingCompleted(true);
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, int>(OnboardingController.new);
```

State is the current page index (0..2). `complete()` is what flips the prefs flag; navigation is handled by the screen, not the controller.

### 5.4 Illustrations

Each illustration is a `CustomPaint` wrapping a small `CustomPainter`. All paint colors come from a `color` parameter that the parent threads from `context.appColors.primary` (or accent for variety). Re-paints when theme changes via `MoodTrackerApp`'s root rebuild.

- **`IllustrationWhat`**: A rounded rectangle (the "journal page") with horizontal stroke lines (text rows) and a centered `MoodFace(mood: Mood.good)` painted via the existing painter — direct reuse, not a copy.
- **`IllustrationHow`**: A `MoodCard`-shaped rounded rectangle with a `MoodFace` inside, plus a finger silhouette (a stroked teardrop path) tapping it. Two paint colors used (primary for the card, onSurface for the finger).
- **`IllustrationPrivacy`**: A phone outline (rounded rectangle, ~1.8:1 aspect), inside it a small horizontal row of three tiny mood faces, and a padlock symbol drawn from primitive lines/arc above. Conveys "data stays here, locked away."

Each illustration honors `MediaQuery.disableAnimations` — they're static, so this is automatic.

### 5.5 First-run redirect

In `app_router.dart`:

```dart
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
      // existing StatefulShellRoute ...
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      // existing /entry/:id route ...
    ],
  );
});
```

The redirect runs on every navigation event. Reading `AppPrefs.onboardingCompleted` is synchronous (SharedPreferences caches values after first load), so this stays cheap.

### 5.6 AppRoutes additions

```dart
static const String onboarding = '/onboarding';
static const String about = '/settings/about';
```

`/settings/about` is registered as a child of the `/settings` shell branch so the back button returns to Settings.

## 6. AppPrefs additions

```dart
static const _kOnboardingCompleted = 'app.onboardingCompleted';

bool get onboardingCompleted => _sp.getBool(_kOnboardingCompleted) ?? false;

Future<void> setOnboardingCompleted(bool value) =>
    _sp.setBool(_kOnboardingCompleted, value);
```

Default `false` — first-run defaults to onboarding.

## 7. Localization

### 7.1 New EN keys (~25)

Settings: `settingsTitle`, `settingsAppearanceSection`, `settingsLanguageSection`, `settingsRemindersSection`, `settingsAboutSection`, `settingsThemeLabel`, `settingsLanguageLabel`, `settingsRemindersLabel`, `settingsRemindersComingSoon`, `settingsAboutLabel`.

Theme: `themeLight`, `themeDark`, `themeSystem`.

Language picker: `languageEnglish`, `languageSpanish`.

About: `aboutTitle`, `aboutDescription`, `aboutVersion`, `aboutViewLicenses`.

Onboarding: `onboardingSkip`, `onboardingNext`, `onboardingGetStarted`, `onboardingWhatTitle`, `onboardingWhatBody`, `onboardingHowTitle`, `onboardingHowBody`, `onboardingPrivacyTitle`, `onboardingPrivacyBody`.

### 7.2 Spanish

`lib/l10n/app_es.arb` mirrors `app_en.arb` key-for-key. Standard Spanish (es), no regional variant, plain register. I draft, user proofreads before commit.

The `LanguagePickerSheet` lists locales using their native names (English / Español), not localized-by-current-locale names. This is intentional — users picking a language they don't speak shouldn't be locked out by the current locale label.

### 7.3 Picker source of truth

The language picker iterates `AppLocalizations.supportedLocales` rather than hardcoding `[en, es]`. Adding a third locale later means dropping in `app_<tag>.arb` and adding a native-name mapping; no picker code changes.

A small helper in `core/l10n/`:

```dart
String nativeNameFor(Locale locale) => switch (locale.languageCode) {
  'en' => 'English',
  'es' => 'Español',
  _ => locale.languageCode,
};
```

## 8. Testing strategy

- **`AppPrefs` test** — add `onboardingCompleted defaults to false` and `onboardingCompleted round-trips`.
- **`SettingsController` test** — `ProviderContainer` overrides `appPrefsProvider` with a mock prefs; verify `setTheme(...)` and `setLocale(...)` propagate to the underlying providers and emit a fresh `SettingsViewModel`.
- **`SettingsScreen` widget test** — pump with overrides, find the three section headers, find the Reminders row with `Semantics(enabled: false)`, tap About → verify navigation.
- **`OnboardingController` test** — `setPage` updates state; `complete()` writes the pref via the mock.
- **`OnboardingScreen` widget test** — 3 pages render, "Next" advances the page, "Skip" calls `complete()` + navigates, last-page CTA fires `complete()`.
- **Router redirect test** — pump `appRouterProvider` against a `ProviderContainer` overriding `AppPrefs` with `onboardingCompleted: false`; first frame should land on `/onboarding`. Flip pref to `true`, re-pump, verify `/today`.
- **`AboutScreen` widget test** — version label renders (use `package_info_plus`'s `PackageInfo.setMockInitialValues` in `setUp`).

No golden tests added in Phase 2 — the onboarding illustrations are non-critical static art. If the team wants regression coverage later, goldens can land in a follow-up commit.

## 9. Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  package_info_plus: ^8.0.2
```

No new dev dependencies.

## 10. Out of scope (reaffirmed)

- Reminders: Phase 5.
- Settings sub-pages beyond About (e.g., privacy policy, terms): not part of any planned phase; deferred indefinitely.
- Per-user accounts, profile management: out of project scope (local-only app).
- Locale-aware date/time formatting beyond `intl` defaults — already wired via `MaterialApp.locale`.

## 11. Key Decisions Log

| Decision | Choice | Why |
|---|---|---|
| Reminders in Phase 2 | Stub placeholder | Per spec; permission/scheduling complexity lives in Phase 5. |
| Onboarding screens | What → How → Privacy | Master spec §7.7; reaffirmed during brainstorm. |
| Spanish source | I draft, user proofreads | Fastest reviewable path. |
| About in Phase 2 | Yes, with version + licenses | Small addition; gives a real settings tab even before reminders are wired. |
| Project repo link | Omit in Phase 2 | No public repo configured; revisit if/when one exists. |
| Onboarding state | `Notifier<int>` for page index | Same Riverpod pattern as Phase 1; no AsyncNotifier needed (no I/O at build). |
| First-run gate | GoRouter `redirect:` | Idiomatic; runs on every nav event; SharedPreferences read is cached after bootstrap. |
| Picker UX | Modal bottom sheets | Consistent with the log-entry sheet pattern from Phase 1. |
