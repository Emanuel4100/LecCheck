# LecCheck Migration Parity Checklist

This checklist maps current Python/Flet behavior to the new Kotlin stack so we can verify functional parity during migration.

## Current behavior inventory

- Auth provider:
  - Web uses Google OAuth client id and server redirect endpoint at `/api/oauth/redirect`.
  - Mobile uses a different client id.
- Data persistence:
  - Firebase Realtime Database path: `/users/{user_id}/schedule.json`.
  - Local backup file for non-web clients: `my_schedule_data.json`.
- Login flows:
  - Google login pulls schedule from Firebase.
  - Guest mode loads local file only.
- Schedule core model:
  - Semester dates, language, weekend visibility, meeting numbering, courses.
  - Courses include meetings and generated lecture sessions.
  - Lecture status and per-session metadata (duration, links, meeting type, one-off tasks).
- Deployment:
  - Static web output for GitHub Pages.
  - Python container for Cloud Run auth/backend role.

## Kotlin target parity checks

## 1) Authentication
- [ ] Backend exposes OAuth start/redirect/callback-compatible flow.
- [ ] Supports configured redirect URL and Google client credentials via env vars.
- [ ] Returns a stable authenticated user identity to web and android clients.

## 2) Firebase sync compatibility
- [ ] Read schedule from `/users/{user_id}/schedule.json`.
- [ ] Write schedule to `/users/{user_id}/schedule.json`.
- [ ] Keep JSON shape backward-compatible with existing Python payload.

## 3) Guest/local mode
- [ ] Android supports local-only mode without login.
- [ ] Local schedule storage available for offline use.

## 4) Schedule domain parity
- [ ] Semester start/end saved and restored.
- [ ] Course + meeting rules represented in Kotlin models.
- [ ] Lecture generation behavior preserved for weekly rules.
- [ ] One-off task/event creation preserved.
- [ ] Lecture status values mapped without regressions.

## 5) Web parity
- [ ] Login + schedule sync work in browser.
- [ ] RTL (Hebrew) rendering behavior preserved.
- [ ] Basic schedule UI view available.

## 6) Android parity
- [ ] Login + schedule sync functional.
- [ ] Core schedule list rendering functional.
- [ ] Non-blocking network calls (coroutines) preserve UI responsiveness.

## 7) Deployment parity
- [ ] Backend deploys to Cloud Run using Kotlin image.
- [ ] Web deploys to static hosting.
- [ ] Updated docs include Kotlin commands and env vars.
