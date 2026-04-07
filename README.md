# LecCheck

LecCheck is a lecture tracking app rebuilt with Flutter (Dart) for high visual parity with the original app.

## Stack

- Flutter + Dart (Material 3)
- Targets: Web, Android, Linux desktop
- Legacy Python/Flet code remains in `legacy/src` as migration reference

## Project structure

- `flutter_app` - active Flutter application
- `legacy/src` - original Python/Flet implementation (reference)
- `ARCHITECTURE.md` - current Flutter architecture notes
- `docs` - parity checklist and cutover runbook
- `run-dev.sh` - helper script to run Flutter quickly

## Current features

- Login shell (Google button placeholder + guest mode)
- Onboarding flow (language and semester range setup)
- Dashboard for lecture tracking
  - Day selector
  - List/grid toggle
  - Attendance progress
  - Lecture status update (attended/missed/canceled)
- Settings view (language info, reset semester, logout)
- Shared in-memory schedule domain models:
  - semester, course, meeting, lecture

## Prerequisites

- Flutter SDK installed (recommended path: `~/development/flutter`)
- Android SDK for Android builds
- Chrome or Chromium for web runs
- Linux build dependencies for Linux target (`clang`, `cmake`, `ninja`, `gtk3-devel`)

## Run locally

### Web

```bash
cd flutter_app
flutter run -d chrome
```

### Android

```bash
cd flutter_app
flutter run -d android
```

### Linux

```bash
cd flutter_app
flutter run -d linux
```

### One command helper

From repo root:

```bash
./run-dev.sh chrome
```

Or:

```bash
./run-dev.sh android
./run-dev.sh linux
```

You can also override Flutter binary path:

```bash
FLUTTER_BIN=~/development/flutter/bin/flutter ./run-dev.sh chrome
```

## Build artifacts

```bash
cd flutter_app
flutter build web
flutter build apk
flutter build linux
```

## Next migration milestones

- Reconnect Firebase + OAuth flows from OG app behavior
- Complete icon/layout parity per screen
- Add persistent local/cloud storage and sync conflict handling

## Docs

- `ARCHITECTURE.md`
- `docs/MIGRATION_PARITY_CHECKLIST.md`
- `docs/PARITY_QA_CHECKLIST.md`
- `docs/CUTOVER_RUNBOOK.md`