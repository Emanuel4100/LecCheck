# LecCheck

LecCheck is a lecture tracking app for web and Android.  
This repository is currently in migration from legacy Python/Flet to a Kotlin stack.

## What the app does

- Track semester schedule (courses, meetings, lecture sessions)
- Sign in with Google OAuth
- Sync schedule data with Firebase Realtime Database
- Support Hebrew and English UI (including RTL flow)
- Support guest/local mode (no login)

## Current project structure

- `backend` - Kotlin + Ktor backend (OAuth + schedule API)
- `webApp` - Kotlin/JS web client
- `androidApp` - Jetpack Compose Android app
- `shared` - shared Kotlin models and UI contracts
- `src` - legacy Python/Flet implementation (reference during migration)

## How it works

### Auth flow

1. Web app redirects to `GET /api/oauth/redirect`
2. Google redirects back to `GET /api/oauth/callback`
3. Backend exchanges code for token and fetches user info
4. Backend creates short-lived in-memory session and redirects web client with `session_id`
5. Web client calls `GET /api/auth/session/{sessionId}` to resolve logged-in user

### Data flow

- Schedule data is stored in Firebase at:
  - `/users/{user_id}/schedule.json`
- Backend exposes read/write API:
  - `GET /api/users/{userId}/schedule`
  - `PUT /api/users/{userId}/schedule`

## Features status

- Backend API: working (`/health`, OAuth routes, schedule routes)
- Web app:
  - Login screen + language files (`webApp/src/main/resources/locales`)
  - Guest mode button wired
  - Basic schedule shell/tabs implemented
  - Ongoing UI parity work vs legacy Flet app
- Android app:
  - Compose shell and initial screens implemented
  - Ongoing UI parity work vs legacy app

## Backend environment variables

- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `REDIRECT_URL` (example: `http://localhost:8080/api/oauth/callback`)
- `FRONTEND_URL` (example: `http://localhost:8081`)
- `FIREBASE_URL` (optional, defaults to LecCheck Firebase URL)

## Run locally

Prerequisites:
- JDK 21 installed
- Gradle available on your PATH

Optional recommended environment setup:

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH="$JAVA_HOME/bin:$PATH"
```

### 1) Run backend

```bash
gradle :backend:run
```

Verify:

```bash
curl http://localhost:8080/health
```

Expected response: `ok`

### 2) Run web app

In a second terminal:

```bash
gradle :webApp:browserDevelopmentRun
```

Open the URL printed by Gradle (usually `http://localhost:8081`).

### 3) Build Android app

```bash
gradle :androidApp:assembleDebug
```

## Common notes

- `:backend:run` stays running at high progress in Gradle. That is expected for a server task.
- You may see a warning that `kotlin-js` plugin is deprecated; this is non-blocking and planned for migration to multiplatform JS target.
- If Gradle reports cache lock issues, run `gradle --stop` and retry.

## API endpoints

- `GET /health`
- `GET /api/oauth/redirect`
- `GET /api/oauth/callback?code=...`
- `GET /api/auth/session/{sessionId}`
- `GET /api/users/{userId}/schedule`
- `PUT /api/users/{userId}/schedule`

## Documentation

- `ARCHITECTURE.md`
- `MIGRATION_PARITY_CHECKLIST.md`
- `docs/PARITY_QA_CHECKLIST.md`
- `docs/CUTOVER_RUNBOOK.md`