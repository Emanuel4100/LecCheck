# LecCheck

LecCheck is a lecture and semester tracking app built with **Flutter** (Dart) for web, Android, and Linux desktop.

## Stack

- Flutter + Dart (Material 3)
- Localization: English and Hebrew
- Targets: Web, Android, Linux desktop (iOS/macOS/Windows scaffolding included)
- Optional **Firebase Auth** (Google) and **Cloud Firestore** sync (see below)

## Project structure

- `flutter_app/` — application source (run and build from here)
- `flutter_app/lib/main.dart` — Firebase bootstrap and `MaterialApp`
- `flutter_app/lib/app/leccheck_root.dart` — navigation shell, persistence, login/onboarding
- `ARCHITECTURE.md` — Flutter architecture and direction
- `docs/` — parity QA checklist, migration notes, cutover runbook
- `scripts/` — release helpers that place binaries under `download/` (see below)
- `run-dev.sh` / `run-dev.fish` — helpers to run the app with a sensible browser on Linux

## Features

- Guest flow or **Continue with Google** (web uses Firebase `signInWithPopup` to avoid extra Google People API setup)
- **Local persistence**: JSON schedule bundle — file-based on mobile/desktop (`path_provider`), **SharedPreferences / localStorage** on web
- **Cloud sync** (when signed in): schedule document at `users/{userId}/leccheck/main` (see [`flutter_app/lib/core/schedule/firestore_schedule_store.dart`](flutter_app/lib/core/schedule/firestore_schedule_store.dart)); merge uses `savedAt` timestamps
- Semester onboarding (language, date range, week start)
- Course setup: **course editor** (name, optional code, lecturer, link, notes, extra links)
- **Weekly meetings** per course (time, location, type, per-meeting links)
- **Dashboard**: weekly grid, lectures list, stats, settings
- **Manage courses** from Settings and the FAB menu
- Lecture status and optional recording link; **Resources** via `url_launcher`
- **Theme**: light, dark, or system (persisted)

Feature toggles: [`flutter_app/lib/core/config/feature_flags.dart`](flutter_app/lib/core/config/feature_flags.dart)

## Firebase

1. Android: `google-services.json` under [`flutter_app/android/app/`](flutter_app/android/app/) (`com.leccheck.app`).
2. All platforms: options in [`flutter_app/lib/firebase_options.dart`](flutter_app/lib/firebase_options.dart). Regenerate with [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup): `dart pub global activate flutterfire_cli` then `flutterfire configure` from `flutter_app/`.
3. **Authentication**: enable **Google** in Firebase Console for your project.
4. **Firestore rules**: deploy [`flutter_app/firestore.rules`](flutter_app/firestore.rules). From `flutter_app/`, with CLI logged in: `firebase deploy --only firestore:rules`. Default project is set in [`flutter_app/.firebaserc`](flutter_app/.firebaserc) (`leccheck-app-db`).
5. **Web OAuth**: configure authorized JavaScript origins for your hosting URL; `web/index.html` includes the Google Sign-In client meta where needed.
6. **Linux**: Firebase is skipped until Linux is added in FlutterFire; local-only mode still works.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Android SDK for Android builds
- Chrome, Chromium, or Brave for web (`CHROME_EXECUTABLE` if needed)
- Linux: `clang`, `cmake`, `ninja`, GTK dev packages (see Flutter Linux docs)

## Clone and run

```bash
git clone https://github.com/Emanuel4100/LecCheck.git
cd LecCheck/flutter_app
flutter pub get
flutter doctor
```

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

### Helper scripts (repo root)

```bash
./run-dev.sh chrome
./run-dev.sh android
./run-dev.sh linux
```

Fish shell: `./run-dev.fish` (same idea).

Override the Flutter binary:

```bash
FLUTTER_BIN=~/development/flutter/bin/flutter ./run-dev.sh chrome
```

**Brave on Linux:**

```bash
export CHROME_EXECUTABLE=/usr/bin/brave-browser
./run-dev.sh chrome
```

## Build release artifacts

### Quick manual builds

```bash
cd flutter_app
flutter build web
flutter build apk --release
flutter build linux --release
```

### Scripts → `download/` (gitignored binaries)

From the **repository root**:

```bash
./scripts/build-download-linux.sh    # → download/leccheck-linux-x64-<version>.tar.gz
./scripts/build-download-android.sh  # → download/leccheck-android-<version>.apk
```

See [`download/README.md`](download/README.md). APKs from the script are for sideloading; **Google Play** uses `flutter build appbundle` (AAB), not this APK path.

`FLUTTER_BIN` is honored the same way as `run-dev.sh`.

## App icons (Android / iOS)

After changing `flutter_app/assets/branding/app_icon.png`:

```bash
cd flutter_app
dart run flutter_launcher_icons
```

## Docs

- `ARCHITECTURE.md`
- `docs/MIGRATION_PARITY_CHECKLIST.md`
- `docs/PARITY_QA_CHECKLIST.md`
- `docs/CUTOVER_RUNBOOK.md`
