---
id: US-12-BRAND-001
title: UI/UX - Android Status Bar & Global Modernization
status: DONE
type: feature
priority: HIGH
---

# Description
As a User, I want the Android status bar to be blue and the interface to look modern and professional so that the app feels high-quality and consistent with the brand.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/main.dart`
> * `mobile/lib/core/theme.dart`

# Acceptance Criteria (DoD)

- [ ] **Scenario 1: Android Status Bar Color**
    - Given the app is running on an Android device
    - When the app is launched
    - Then the Status Bar color is Blue (#0047AB) and icons (time, battery, etc.) remain clearly visible.
- [ ] **Scenario 2: Global UI Modernization**
    - Given I am navigating the app
    - When I view any screen
    - Then the design follows a professional, clean aesthetic (consistent padding, refined typography, and modern Neumorphism/Material elements).

# UI element
- System status bar configuration.
- Global theme refinements.

# Technical Notes (Architect)
- Use `SystemChrome.setSystemUIOverlayStyle` in `main.dart`.
- Ensure `StatusBarIconBrightness` is set appropriately for visibility.
