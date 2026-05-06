---
id: US-13-ATT-003
title: Mobile - Immersive Scanner UI
status: DONE
type: feature
---

# Description
As a User, I want a modern and immersive scanning interface, so that I can easily align my face for recognition.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> *   `mobile/lib/features/attendance/scanner_screen.dart`
> *   `mobile/lib/features/attendance/face_oval_painter.dart`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: Immersive View**
    - Given the scanner screen is open
    - Then the status bar and navigation bar are hidden (full screen)

- [x] **Scenario 2: Visual Guides**
    - Given the camera is active
    - Then a semi-transparent facial oval guide is displayed
    - And a "scanning" pulse animation is visible during the live stream

- [x] **Scenario 3: Prevention of double scan**
    - Given the system is currently processing an image
    - When the camera detects another face trigger
    - Then the second request is blocked to avoid redundant API calls

# UI element
- Immersive Camera Preview (Fullscreen).
- Facial Guide Overlay (Oval).
- Scanning Pulse Animation.

# Technical Notes (Architect)
- Use `SystemChrome.setEnabledSystemUIMode` for immersive mode.
- Use a boolean flag `isScanning` in the Riverpod state to guard the API call.
- Ensure the guide overlay is responsive to different screen aspect ratios.
