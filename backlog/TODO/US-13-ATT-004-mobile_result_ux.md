---
id: US-13-ATT-004
title: Mobile - Attendance Result Feedback
status: READY
type: feature
---

# Description
As a User, I want clear and instant feedback after my face is scanned, so that I know exactly if my attendance was recorded as an entry or an exit.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> *   `mobile/lib/features/attendance/scanner_screen.dart`
> *   `mobile/lib/features/attendance/scanner_state.dart`

# Acceptance Criteria (DoD)

- [ ] **Scenario 1: Processing state**
    - Given an image is being processed by the backend
    - Then a global loader (circular indicator) is shown on top of the screen
    - And the camera preview is temporarily paused or obscured
    - And no text is displayed with the loader (minimalist)

- [ ] **Scenario 2: Result Popup**
    - Given the API returns a response (Success or Error)
    - Then a popup/modal appears instantly
    - And it shows the message returned by the API (e.g., "Bienvenue Tafita")
    - And the theme matches the dynamic color (Green: entry, Blue: exit, Red: error)

- [ ] **Scenario 3: Automatic reset**
    - Given a result modal is displayed
    - When the user taps "OK" or after 3 seconds of inactivity
    - Then the modal disappears
    - And the scanner returns to "Scanning" mode automatically

# UI element
- Global Loader overlay.
- Result Modal (Popup).
- Dynamic Theming (Green/Blue/Red).

# Technical Notes (Architect)
- Use `showDialog` or a custom overlay for the result popup.
- Loader must be minimalist as per PRD ("pas de texte").
- Map backend `ui` metadata directly to UI styles for consistency.
