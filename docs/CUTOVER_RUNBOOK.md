# LecCheck UI Cutover Runbook

## Scope
- New UI targets:
  - `flutter_app` web
  - `flutter_app` Android
  - `flutter_app` Linux desktop
- The legacy Python/Flet app has been removed; Flutter is the only app in this repository.

## Pre-cutover checks
1. Run `flutter doctor` and verify Flutter/Android/Web setup.
2. Run `cd flutter_app && flutter analyze`.
3. Run `./run-dev.sh chrome` and complete QA checklist.
4. Run `./run-dev.sh android` and complete QA checklist.
5. Run `./run-dev.sh linux` and complete QA checklist.

## Cutover steps
1. Deploy web static bundle from `flutter_app` (`flutter build web`).
2. Distribute Android build from `flutter_app` (`flutter build apk` or `appbundle`).
3. Provide Linux build artifact from `flutter_app` (`flutter build linux`).
4. Track stabilization issues against Flutter-only releases.

## Stabilization window
- Monitor login and onboarding completion rates.
- Monitor schedule create/edit/status flows.
- Validate no RTL regressions reported by users.

## Legacy decommission (complete)
- Python/Flet source has been removed from the repo.
- Docs and onboarding point to the Flutter app under `flutter_app/`.
