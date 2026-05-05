---
id: US-12-BRAND-003
title: Branding - App Identity (I-POINTEO)
status: DONE
type: feature
priority: HIGH
---

# Description
As the Product Owner, I want the app to be officially named "I-POINTEO" and have a modern, professional logo and harmonized styles so that the brand identity is clear and trustworthy.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/pubspec.yaml`
> * `mobile/android/app/src/main/AndroidManifest.xml`
> * `mobile/ios/Runner/Info.plist`
> * `mobile/lib/core/theme.dart`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: App Renaming**
    - Given the app is installed on a device
    - Then the name displayed on the launcher/home screen is "I-POINTEO".
- [x] **Scenario 2: New App Logo**
    - Given I am on the Login screen or Launcher
    - Then the new modern "I-POINTEO" logo is displayed.
- [x] **Scenario 3: Style Harmonization**
    - Given I am using the app
    - Then all colors, icons, and button styles are harmonized with the brand palette (Blue, White, Black).

# UI element
- App Launcher Icon.
- Logo widget on Login and Dashboard.

# Technical Notes (Architect)
- Use `flutter_launcher_icons` to generate multi-platform icons.
- Update `package_name` and `label` in native config files.

# Reviewer Feedback (Reviewer)
1. **Verified**: App renamed in `AndroidManifest.xml`, `Info.plist`, and `main.dart`.
2. **Verified**: New code-based `Logo` widget created and integrated into key screens.
3. **Verified**: Styles harmonized with pure white background and deep blue primary color.
4. **Quality**: TDD followed with new tests in `branding_test.dart` and updated existing tests.
