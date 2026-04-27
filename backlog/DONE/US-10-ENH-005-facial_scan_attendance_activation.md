---
id: US-10-ENH-005
title: User - Facial Scan Attendance Activation
status: DONE
type: feature
---
# Description
As an Employee, I want to use the facial scan feature to log my attendance so that I can check in securely.

# Context Map
- Mobile: `mobile/lib/features/attendance/scanner_screen.dart`

# Acceptance Criteria (DoD)
- [ ] **Scenario 1: Successful Scan**
    - Given I have been enrolled in the system
    - When I align my face in the scanner oval
    - Then the system should recognize me and log my attendance.
- [ ] **Scenario 2: Unenrolled User**
    - Given I have not been enrolled
    - When I attempt to scan
    - Then the system should inform me that my face is not recognized.

# Technical Notes (Architect)
- Ensure the camera stream is correctly passed to the recognition service.
- Verify the feedback loop (Green/Red oval) matches the UX specs.
