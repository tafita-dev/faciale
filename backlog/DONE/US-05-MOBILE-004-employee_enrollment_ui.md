---
id: US-05-MOBILE-004
title: Employee Enrollment UI
status: DONE
type: feature
---
# Description
As an Org Admin, I want a form to register new employees and capture their reference photo so that they can use the facial recognition system.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/features/employees/enroll_screen.dart`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Form Validation**
    - Given the Enrollment screen is open
    - When I try to save without a name or department
    - Then I should see validation errors on the respective fields.
- [x] **Scenario 2: Photo Capture**
    - Given the Enrollment screen is open
    - When I tap "Capture Reference Photo"
    - Then a camera preview dialog should open.
- [x] **Scenario 3: Enrollment Progress**
    - Given a photo has been captured and form is valid
    - When I tap "Save"
    - Then I should see a "Generating Secure Identity..." loading state
    - And be redirected to the Employee List on success.

# UI element
- Enrollment Form (Name, Dept Dropdown)
- Photo Capture Box
- Camera Preview (Dialog)
- Loading Overlay

# Technical Notes (Architect)
- Use `camera` package for photo capture.
- Implement image quality check (basic blur/brightness detection if possible, or just user confirmation).
- Integrate with `POST /api/v1/employees/{id}/enroll`.
