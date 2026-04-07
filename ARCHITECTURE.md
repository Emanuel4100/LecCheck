# LecCheck - Flutter Architecture

This repository now uses Flutter (Dart) as the primary app stack for web, Android, and Linux desktop.

## Architecture goals

- Preserve OG LecCheck UX and behavior with high visual parity.
- Keep one shared Flutter codebase for web, Android, and Linux.
- Move from in-memory prototype state to durable offline-first storage.
- Keep integration boundaries clear so Firebase/OAuth can be added without UI rewrites.

## System architecture (target)

### 1) Main app (`flutter_app`)
- Runtime: Dart + Flutter (Material 3).
- Targets:
  - Web (`flutter run -d chrome`)
  - Android (`flutter run -d android`)
  - Linux desktop (`flutter run -d linux`)
- Responsibilities:
  - Login/onboarding/dashboard flows.
  - Weekly/lectures/stats/settings UI.
  - App state orchestration and domain use-cases.

### 2) Legacy reference (`legacy/src`)
- Original Python/Flet implementation kept as behavior/layout reference while parity work is in progress.

## Recommended code layering inside `flutter_app/lib`

- `app/`
  - app bootstrap, routing, theme, localization setup
- `core/`
  - constants, utilities, date helpers, result/error models
- `features/<feature_name>/`
  - `presentation/` widgets/screens/view-models
  - `domain/` entities + use-cases
  - `data/` repositories + DTO mappers + data sources
- `shared/`
  - reusable UI components, design tokens, icon mapping

Current code is intentionally concentrated in `main.dart` for bootstrapping speed. Before major feature expansion, split by this structure to keep maintainability high.

## State management direction

- Short term: keep simple local state while parity screens stabilize.
- Base target: move to predictable unidirectional state (Riverpod or Bloc).
- Rule: UI widgets should not hold business logic (lecture generation, attendance calc, sync decisions). Keep this in domain/use-case layer.

## Data architecture direction

Core domain models:
- `SemesterSchedule`
- `Course`
- `Meeting`
- `Lecture`

Data sources (planned):
- Local source: on-device persistence (Hive/Isar/SQLite).
- Remote source: Firebase Realtime Database and OAuth-backed identity.
- Repository layer merges local + remote and resolves sync strategy.

Recommended sync model:
- Offline-first writes to local store.
- Background sync to remote when authenticated/network available.
- Explicit conflict policy (last-write-wins or timestamp/version-based merge).

## Platform notes

- Web: use `CHROME_EXECUTABLE` when running on Brave/Chromium.
- Android: ensure SDK/emulator setup and release signing later in pipeline.
- Linux: requires `clang`, `cmake`, `ninja`, and GTK3 development libs.

## Deployment direction (Flutter-only)

### Web
- Build: `flutter build web`
- Host: static hosting (GitHub Pages, Firebase Hosting, or similar)

### Android
- Build: `flutter build apk` or `flutter build appbundle`

### Linux
- Build: `flutter build linux`

## Base hardening checklist (before feature growth)

- Split `main.dart` into feature modules and shared components.
- Add state-management foundation (Riverpod or Bloc) with testable view-model/controller layer.
- Add local persistence for schedule and settings.
- Add repository abstraction + remote data source interfaces.
- Add analytics/logging/error boundary strategy per platform.
- Add CI steps: `flutter analyze`, `flutter test`, and build checks for web/android/linux.