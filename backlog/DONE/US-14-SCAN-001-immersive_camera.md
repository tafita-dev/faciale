---
id: US-14-SCAN-001
title: Modern Immersive Camera Interface
status: DONE
type: feature
---
# Description
As a Mobile User, I want to use a full-screen, natural camera interface without overlays, so that the scanning experience is intuitive and professional.

# Context Map
> Specific files for this story:
> * @mobile/lib/features/attendance/scanner_screen.dart

# Acceptance Criteria (DoD)
- [ ] **Scenario 1:** [Happy Path - Full Screen View]
    - Given the user opens the scanner screen
    - When the screen loads
    - Then the camera preview displays in full-screen mode without any fixed guide overlays (e.g., face oval)
- [ ] **Scenario 2:** [Happy Path - Switch Camera]
    - Given the camera is active
    - When the user taps the 'switch camera' button
    - Then the camera switches between front and back lens smoothly without crashing

# UI element
- Full-screen camera background.
- Toggle camera button (Front/Back) visible in the overlay.
- Removal of the 'face oval' guide.

# Technical Notes (Architect)
- Remove `FaceOvalPainter` dependency.
- Use `camera` package lens direction switching logic.
- Ensure state consistency during switch.
