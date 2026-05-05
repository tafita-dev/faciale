---
id: US-12-BRAND-007-1
title: Mobile - Logout Functionality
status: DONE
type: feature
priority: MEDIUM
---

# Description
As a User, I want to be able to log out of the application securely so that I can manage my session.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/features/auth/auth_provider.dart`
> * `mobile/lib/features/profile/profile_screen.dart`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: Logout Functionality**
    - Given I am logged into the app
    - When I click the "Logout" button (in Profile or Drawer)
    - Then the session is cleared (JWT removed from secure storage).
    - Then I am redirected to the Login screen.

# UI element
- Logout button in the Profile screen and/or Navigation Drawer.

# Technical Notes (Architect)
- Use `FlutterSecureStorage` (or whatever is used for tokens) to clear the JWT.
- Update the Auth provider state to reflect the unauthenticated status.
