# LecCheck UI Cutover Runbook

## Scope
- New UI targets:
  - `webApp` Kotlin/JS
  - `androidApp` Jetpack Compose
- Backend stays on `backend` Ktor service.
- Legacy Python/Flet UI remains in `src` until final sign-off.

## Pre-cutover checks
1. Run backend and verify `http://localhost:8080/health`.
2. Run `gradle :backend:build` and `gradle :backend:test`.
3. Run `gradle :webApp:browserDevelopmentRun` and complete QA checklist.
4. Build Android debug app and complete QA checklist.

## Cutover steps
1. Deploy backend image from Kotlin code path.
2. Deploy web static bundle from `webApp`.
3. Distribute Android build from `androidApp`.
4. Keep `src` read-only during stabilization window.

## Stabilization window
- Monitor auth callback success.
- Monitor schedule read/write success.
- Validate no RTL regressions reported by users.

## Legacy decommission criteria
- All parity checklist items pass.
- No blocking regressions for one release cycle.
- Docs and onboarding instructions updated to Kotlin flows.
