# LecCheck - Flutter Architecture

This repository now uses Flutter (Dart) as the primary app stack for web, Android, and Linux desktop.

## System architecture

### 1) Main app (`flutter_app`)
- Runtime: Dart + Flutter (Material 3).
- Targets:
  - Web (`flutter run -d chrome`)
  - Android (`flutter run -d android`)
  - Linux desktop (`flutter run -d linux`)
- Responsibilities:
  - Login shell and onboarding flow.
  - Semester/course/meeting/lecture state handling.
  - Weekly and lecture tracking UI, attendance stats, and settings.

### 2) Legacy reference (`src`)
- Original Python/Flet implementation kept as behavior/layout reference while parity work is in progress.

## Data model direction

The Flutter app follows the LecCheck core domain:
- `SemesterSchedule`
- `Course`
- `Meeting`
- `Lecture`

Current implementation is in-memory while UI parity is finalized. Firebase/OAuth wiring can be reintroduced after the Flutter UX cutover is stable.

## Deployment direction

### Web
- Build: `flutter build web`
- Host: static hosting (GitHub Pages, Firebase Hosting, or similar)

### Android
- Build: `flutter build apk` or `flutter build appbundle`

### Linux
- Build: `flutter build linux`