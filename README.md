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

### Linux: Google sign-in (OAuth) and “missing client” errors

Linux uses a **Web OAuth client** with a local redirect server on a **fixed port** (`8765`). You must:

1. Copy `flutter_app/.env.example` to `flutter_app/.env`, set `LINUX_GOOGLE_OAUTH_CLIENT_ID` and `LINUX_GOOGLE_OAUTH_CLIENT_SECRET`, and **never commit** `.env` (it is gitignored).
2. Pass defines on every run and release build, for example:
   - `flutter run -d linux --dart-define-from-file=flutter_app/.env`
   - `flutter build linux --dart-define-from-file=flutter_app/.env`
3. In [Google Cloud Console](https://console.cloud.google.com/apis/credentials) → your **OAuth 2.0 Web client** → **Authorized redirect URIs**, add exactly: `http://127.0.0.1:8765/` (same host, path, and port as the app).

If the app is built **without** those defines, Google may report errors users describe as **“missing client”**; the app shows a dialog with the correct `flutter run` / `flutter build` flags. Only one app instance should use sign-in at a time; if port `8765` is busy, close the other instance or free the port.

### Android: Google sign-in stuck or `DEVELOPER_ERROR`

Use the **Android** OAuth client type in Firebase/Google Cloud as documented for your package name, register **SHA-1** (and SHA-256 if required) for debug and release keystores, and ensure the **Web client ID** matches Firebase’s Google provider settings when applicable. Mismatches often surface as `DEVELOPER_ERROR` / `ApiException: 10`.

### Sensitive data (Linux)

Google tokens for Linux are stored in **SharedPreferences** (not hardware-backed). Treat the device account as trusted; use full-disk encryption where it matters.

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

