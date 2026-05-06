---
id: US-14-SCAN-003
title: Camera Switching and Reusable Scanner Component
status: DONE
type: feature
---
# Description
As a Mobile User, I want to switch between front and back cameras and use a reusable scanner component, so that I can easily scan employees or add new staff members with flexibility.

# Context Map
> Reference @specs/context-map.md
> Specific files for this story:
> * @mobile/lib/features/attendance/scanner_screen.dart

# Acceptance Criteria (DoD)
- [ ] **Scenario 1:** [Happy Path - Camera Toggle]
    - Given the scanner component is active
    - When the user taps the 'switch lens' button
    - Then the camera stream switches to the other lens smoothly without app interruption
- [ ] **Scenario 2:** [Happy Path - Reusability]
    - Given the scan component logic is modular
    - When initialized in 'Enrollment' mode or 'Attendance' mode
    - Then the same UI/logic handles the respective API call correctly based on the passed mode parameter

# UI element
- Toggle button on the scanner interface for lens direction.
- Parameterized scanner widget that accepts a callback function for image processing.

# Technical Notes (Architect)
- Refactor `ScannerScreen` into a reusable `FacialScannerWidget`.
- Pass a `Future<void> Function(String imagePath)` callback to the widget.
- Ensure camera controller is disposed and re-initialized correctly when switching lens.
