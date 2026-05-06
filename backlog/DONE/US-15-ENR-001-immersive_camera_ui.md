---
id: US-15-ENR-001
title: Immersive Camera UI & Lens Switching
status: DONE
type: feature
---
# Description
As a Mobile User, I want a full-screen, immersive camera interface with the ability to toggle between front and back cameras, so that I have a natural and flexible experience while enrolling a new employee.

# Context Map
> Reference @specs/context-map.md
> Specific files for this story:
> * @mobile/lib/features/employees/enroll_screen.dart
> * @mobile/lib/features/attendance/facial_scanner_widget.dart

# Acceptance Criteria (DoD)
- [ ] **Scenario 1:** [Happy Path - Immersive Full Screen]
    - Given the employee enrollment screen is active
    - When the camera initializes
    - Then the camera preview covers the entire screen without any fixed guide frames or overlays
- [ ] **Scenario 2:** [Happy Path - Camera Toggle]
    - Given the camera is active
    - When the user taps the 'switch camera' button
    - Then the camera lens toggles (front/back) smoothly without app interruption
- [ ] **Scenario 3:** [Error Case - Switch Camera Failure]
    - Given the camera switch is attempted
    - When an error occurs during lens transition
    - Then the application handles the exception gracefully, maintaining the previous camera state

# UI element
- Full-screen camera background.
- Toggle camera button (Front/Back) visible in the top-right overlay.
- Removal of any fixed/static frames.

# Technical Notes (Architect)
- Reuse or extend `FacialScannerWidget` for enrollment.
- Ensure camera controller disposal and re-initialization logic is robust for lens switching.
