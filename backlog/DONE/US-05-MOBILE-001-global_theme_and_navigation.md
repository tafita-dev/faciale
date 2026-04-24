---
id: US-05-MOBILE-001
title: Global Theme & Navigation Setup
status: DONE
type: feature
---
# Description
As a Developer, I want to set up the global theme and primary navigation structure so that the application follows the brand identity and provides a consistent user journey.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/core/theme.dart`
> * `mobile/lib/features/navigation/`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: brand Colors Applied**
    - Given the application is launched
    - When viewing any screen
    - Then the Primary color should be Deep Blue (#0047AB), Background should be White (#FFFFFF), and Text should be Black (#000000).
- [x] **Scenario 2: Admin Navigation Structure**
    - Given an Admin or Org Admin is logged in
    - When the home screen is displayed
    - Then a persistent Bottom Navigation Bar should be visible with: Dashboard, Employees, Reports, and Profile.
- [x] **Scenario 3: Scanner Navigation**
    - Given a user chooses to enter Scan Mode
    - When the scanner screen is opened
    - Then the navigation bars should be hidden to provide an immersive full-screen camera view.

# UI element
- Global Theme (ThemeData)
- BottomNavigationBar

# Technical Notes (Architect)
- Use `Flutter Material 3`.
- Implement navigation using `go_router` or standard Navigator.
- Define a `CustomTheme` class to hold the hexadecimal color constants.
