# LecCheck UI Parity QA Checklist

## Login
- Google login button visible and primary.
- Guest mode entry visible.
- Security hint text visible.
- Hebrew text and alignment are correct.

## Onboarding
- Setup title shown.
- Date selection controls visible.
- Continue flow moves to schedule shell.

## Schedule Shell
- Top header/title visible.
- Tabs: weekly, lectures, statistics, settings.
- Floating add button visible.
- Weekly navigation controls present.

## Lectures + Stats + Settings
- Tab switching works on web and Android.
- Empty states are present.
- Basic card layout matches legacy proportions.

## Localization + RTL
- Hebrew strings render correctly.
- Layout direction remains readable for Hebrew.

## Backend Integration
- `/health` returns `ok`.
- Session route can resolve current user.
- Web login redirect still opens OAuth endpoint.
