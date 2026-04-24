---
id: US-05-MOBILE-002
title: Login Screen Implementation
status: DONE
type: feature
---
# Description
As a User, I want to log in using my email and password so that I can access my personalized dashboard and management tools.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/features/auth/login_screen.dart`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Successful Login**
    - Given the Login screen is displayed
    - When I enter valid credentials and tap "Login"
    - Then a loading spinner should appear on the button
    - And I should be redirected to the Dashboard upon success.
- [x] **Scenario 2: Invalid Credentials**
    - Given the Login screen is displayed
    - When I enter incorrect credentials and tap "Login"
    - Then the input fields should perform a shake animation
    - And a Red "Invalid email or password" snackbar should appear.
- [x] **Scenario 3: Layout Consistency**
    - Given the Login screen is displayed
    - Then the Logo should be centered at the top
    - And input fields should have Blue borders when focused.

# UI element
- Logo (Geometric face icon)
- TextField (Email, Password)
- PrimaryButton (Deep Blue)
- TextLink (Forgot password?)

# Technical Notes (Architect)
- Integrate with `POST /api/v1/auth/login`.
- Store JWT token securely using `flutter_secure_storage`.
- Use `Riverpod` for authentication state management.
