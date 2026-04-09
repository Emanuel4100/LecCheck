# Firebase security model (LecCheck)

## API keys in the client

Values in `lib/firebase_options.dart` (web API key, app IDs, etc.) are **meant to be public**. They identify your Firebase project to client SDKs; they are **not** secrets. Real access control is enforced by **Firebase Authentication** and **Firestore Security Rules**.

## Firestore rules

Rules under `users/{userId}/leccheck/main` require:

- A signed-in user whose `uid` matches `userId`.
- Writes to use only the fields `bundle` (map) and `updatedAt` (server timestamp from the client).
- Document id `main` only (the app does not use other ids under `leccheck/`).

Firestore still enforces a **per-document size limit** (currently 1 MiB). Rules do not expose exact serialized byte size; structural checks above reduce abuse (extra fields, wrong shapes).

## Optional hardening

- **Firebase App Check** can restrict API usage to genuine app instances (Android/iOS). It adds setup and operational cost; enable when you want stronger abuse protection than rules alone.

## Linux Google sign-in

Desktop OAuth uses **PKCE** and a loopback redirect; do **not** embed OAuth client secrets in the app.

## Automated tests

From `flutter_app/`:

- Unit / widget: `flutter test`
- Integration (needs a device / emulator and platform toolchains, e.g. Linux `cmake` for `-d linux`):  
  `flutter test integration_test/app_test.dart -d linux` or `-d <android_device_id>`
