# LecCheck Migration Parity Checklist

Historical checklist: maps former Python/Flet behavior to the Flutter stack for parity verification (migration reference; Python app removed from repo).

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

## Flutter target parity checks

## 1) Authentication
- [ ] Flutter web login launches OAuth-compatible flow.
- [ ] Config values are externally configurable (without hardcoding secrets).
- [ ] Authenticated user identity is resolved consistently across web/android/linux.

## 2) Firebase sync compatibility
- [ ] Read schedule from `/users/{user_id}/schedule.json`.
- [ ] Write schedule to `/users/{user_id}/schedule.json`.
- [ ] Keep JSON shape backward-compatible with existing Python payloads.

## 3) Guest/local mode
- [ ] App supports local-only mode without login.
- [ ] Local schedule storage available for offline use.

## 4) Schedule domain parity
- [ ] Semester start/end saved and restored.
- [ ] Course + meeting rules represented in Dart models.
- [ ] Lecture generation behavior preserved for weekly rules.
- [ ] One-off task/event creation preserved.
- [ ] Lecture status values mapped without regressions.

## 5) Web parity
- [ ] Login + schedule sync work in browser (Brave/Chrome/Chromium).
- [ ] RTL (Hebrew) rendering behavior preserved.
- [ ] Main schedule UI view matches OG spacing and hierarchy.

## 6) Android parity
- [ ] Login + schedule sync functional.
- [ ] Core schedule list rendering functional.
- [ ] Smooth interaction and transitions (no visible jank on common devices).

## 7) Linux desktop parity
- [ ] App starts and renders correctly on Linux desktop.
- [ ] Core schedule actions work in Linux target.

## 8) Deployment parity
- [ ] Web build output deploys to static hosting.
- [ ] Android build pipeline produces debug/release artifacts.
- [ ] Linux build pipeline produces runnable artifacts.
- [ ] Updated docs include Flutter commands and target-specific notes.
