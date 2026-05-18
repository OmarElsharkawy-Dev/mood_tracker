# Mood Tracker

A local-only Flutter mood-tracker app — log journal-style entries (mood, intensity, free-text note, activity tags, sleep hours, energy level) and review them through history, calendar, search, statistics, reminders, and JSON export/import.

Built as a learning playground that exercises a full Feature-First Clean Architecture stack end-to-end. No accounts, no cloud, no network beyond Google Fonts: everything lives in a single SQLite database on-device.

## Status

Phases 1 and 2 are complete: `core/` infrastructure + `mood_entry` / `history` / `today` / `settings` / `onboarding` features + app wiring, with full English and Spanish translations and a first-run onboarding redirect. Subsequent phases (calendar + search, statistics + charts, reminders + JSON backup) are planned but not yet built.

- Master spec: [`docs/superpowers/specs/2026-05-17-mood-tracker-design.md`](docs/superpowers/specs/2026-05-17-mood-tracker-design.md)
- Phase 2 design: [`docs/superpowers/specs/2026-05-18-phase-2-design.md`](docs/superpowers/specs/2026-05-18-phase-2-design.md)
- Phase 1 plan: [`docs/superpowers/plans/2026-05-17-mood-tracker-phase-1.md`](docs/superpowers/plans/2026-05-17-mood-tracker-phase-1.md)
- Phase 2 plan: [`docs/superpowers/plans/2026-05-18-mood-tracker-phase-2.md`](docs/superpowers/plans/2026-05-18-mood-tracker-phase-2.md)
- Project context for AI assistants: [`MEMORY.md`](MEMORY.md)

## Tech stack

| Concern | Choice |
|---|---|
| State management | `flutter_riverpod` |
| Local persistence | `drift` + `sqlite3_flutter_libs` (normalized `entries` / `tags` / `entry_tags`) |
| Routing | `go_router` with a 5-tab `StatefulShellRoute.indexedStack` + first-run redirect |
| DI | `get_it` (infra singletons) + Riverpod (app state) |
| Prefs | `shared_preferences` |
| Localization | ARB-based `flutter_localizations` (English + Spanish, ~73 keys each) |
| Package info | `package_info_plus` (About screen version display) |
| Typography | `google_fonts` (Lora for headings, Raleway for body) |
| Icons | `lucide_icons_flutter` (mood faces and onboarding illustrations are programmatic `CustomPainter`s) |
| Loading states | `skeletonizer` |
| Responsive sizing | `flutter_screenutil` |
| IDs | `uuid` v4 |
| Tests | `flutter_test` + `mockito` (with goldens for the mood faces) |

## Architecture

Feature-First Clean Architecture (`domain → data → presentation`). Each feature lives under `lib/features/<feature>/` with its own `domain/`, `data/`, `presentation/`, and `providers/`. Cross-cutting infrastructure lives in `lib/core/` (`db/`, `di/`, `error/`, `l10n/`, `navigation/`, `prefs/`, `theme/`, `utils/`, `widgets/`).

Errors flow through `Result` tuples `(T?, Failure?)` — the sealed `Failure` hierarchy in `core/error/` maps Drift exceptions to typed failures so the presentation layer never sees a raw exception.

## Running locally

```bash
# fetch deps
flutter pub get

# regenerate localizations + Drift code as needed
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs

# static analysis (must report 0 issues)
flutter analyze

# full test suite
flutter test

# launch on a connected device or simulator
flutter run
```

Generated files (Drift's `app_database.g.dart`, l10n's `app_localizations*.dart`) are NOT committed — they regenerate on `pub get`.

## Conventions

- **Commit format:** `type(scope): short description` (types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`).
- **Commits never include a `Co-Authored-By` trailer.**
- **No hardcoded UI strings** — every string lives in `lib/l10n/app_en.arb` and is accessed via `context.l10n.<key>`.
- **No hardcoded colors** — use `context.appColors` (Mental Health palette in light + dark variants).
- **No hardcoded routes** — use `AppRoutes` constants and `AppRoutes.entryDetailFor(id)` helpers.
- **`const` constructors** wherever possible; **`final` locals** by default.
- **Imports** sorted alphabetically: package imports first, then project imports.
- **Every commit** keeps `flutter analyze` at 0 issues and `flutter test` green.

## Phase roadmap

1. **Phase 1 — Foundation + first vertical slice** *(complete 2026-05-17)* — `core/`, `mood_entry`, `history`, `today`.
2. **Phase 2 — Settings, onboarding, Spanish translations** *(complete 2026-05-18)* — `settings` (theme/language/reminders-stub/about + modal pickers), `onboarding` (3-page first-run flow + GoRouter redirect), full `app_es.arb`, `package_info_plus`.
3. **Phase 3 — Calendar view, search/filter.**
4. **Phase 4 — Statistics & charts (`fl_chart`).**
5. **Phase 5 — Local reminders, JSON export/import.**

Each phase ships against the same spec and gets its own implementation plan under `docs/superpowers/plans/`.
