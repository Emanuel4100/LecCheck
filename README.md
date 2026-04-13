# LecCheck

Flutter app for **Android** and **Linux**: weekly schedule grid, lectures list, attendance stats, semesters/courses, EN/HE, light/dark themes. Offline-first JSON storage; optional **Google sign-in** and **Firestore** sync (native SDK on mobile, REST + browser OAuth on Linux).

---

## Quick start

```bash
git clone https://github.com/Emanuel4100/LecCheck.git
cd LecCheck/flutter_app
flutter pub get
flutter run -d linux    # or -d android
```

**Release builds** (artifacts under `~/Downloads/` unless scripted otherwise):


| Script                                | Output                                                |
| ------------------------------------- | ----------------------------------------------------- |
| `./scripts/build-download-linux.sh`   | Linux tarball + `setup.sh` (install/uninstall menu)   |
| `./scripts/build-download-android.sh` | APK                                                   |
| `./scripts/release.sh`                | Version bump, both platforms, optional GitHub Release |


CI: push a `v*` tag → `.github/workflows/release.yml` can publish a release.

---

## Repo layout

- `**flutter_app/`** — app (`lib/main.dart`, `lib/app/leccheck_root.dart`, features under `lib/features/`)
- `**flutter_app/.env.example**` — copy to `.env` for Linux OAuth (never commit secrets)
- `**scripts/**` — build / install helpers

---

## Firebase (for cloud sync)

1. Add `**google-services.json**` → `flutter_app/android/app/` (package `com.leccheck.app`).
2. Regenerate `**flutter_app/lib/firebase_options.dart**` with `flutterfire configure` if you use a new project.
3. Firebase Console: enable **Google** sign-in; deploy rules: `firebase deploy --only firestore:rules` from `flutter_app/`.
4. **Linux:** fill `flutter_app/.env` from `.env.example` (Desktop OAuth client).

---

## Notable behavior

- **Sync:** Debounced writes to Firestore; Android listens for remote updates; Linux polls while the app runs.
- **Notifications:** Meeting follow-ups on **Android** (not Linux desktop).
- **Secrets:** OAuth client secret stays in `.env`, not in source.

