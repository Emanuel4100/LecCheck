# LecCheck - Kotlin Architecture and Deployment

This document tracks the post-migration architecture from Python/Flet into Kotlin across backend, web, and Android.

## System architecture

### 1) Backend/Auth service (`backend`)
- Runtime: Kotlin + Ktor (JVM).
- Hosting target: Google Cloud Run (containerized).
- Responsibilities:
  - Google OAuth redirect and callback handling.
  - Session resolution endpoint for clients.
  - Schedule read/write proxy to Firebase Realtime Database.
- Endpoints:
  - `GET /health`
  - `GET /api/oauth/redirect`
  - `GET /api/oauth/callback?code=...`
  - `GET /api/auth/session/{sessionId}`
  - `GET /api/users/{userId}/schedule`
  - `PUT /api/users/{userId}/schedule`

### 2) Shared contracts (`shared`)
- Kotlin serializable models for schedule, course, meetings, and lecture sessions.
- Keeps payload shape compatible with legacy Firebase records.

### 3) Web client (`webApp`)
- Runtime: Kotlin/JS (IR).
- Hosting target: static hosting (GitHub Pages or Firebase Hosting).
- Integrates with backend OAuth endpoints and schedule endpoints.

### 4) Android client (`androidApp`)
- Runtime: Kotlin + Jetpack Compose.
- Communicates with backend and Firebase-compatible schedule API.
- Uses coroutines for non-blocking network operations.

### 5) Legacy code (`src`)
- Existing Python/Flet implementation retained during transition.
- Can be removed after production parity and cutover validation.

## Environment variables (backend)

- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `REDIRECT_URL` (must match Google OAuth callback config)
- `FRONTEND_URL` (web app URL to return after callback)
- `FIREBASE_URL` (defaults to LecCheck database URL)

## Deployment

### Build backend container
```bash
docker build -t leccheck-backend .
```

### Run backend locally
```bash
docker run --rm -p 8080:8080 \
  -e GOOGLE_CLIENT_ID=... \
  -e GOOGLE_CLIENT_SECRET=... \
  -e REDIRECT_URL=http://localhost:8080/api/oauth/callback \
  -e FRONTEND_URL=http://localhost:8081 \
  leccheck-backend
```

### Cloud Run deploy (example)
```bash
gcloud run deploy leccheck \
  --source . \
  --region europe-west1 \
  --allow-unauthenticated \
  --set-env-vars GOOGLE_CLIENT_ID=...,GOOGLE_CLIENT_SECRET=...,REDIRECT_URL=https://<cloud-run-url>/api/oauth/callback,FRONTEND_URL=https://<web-url>
```