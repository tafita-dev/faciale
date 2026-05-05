---
id: US-12-BRAND-002
title: User Profile - Comprehensive Data Display
status: DONE
type: feature
priority: MEDIUM
---

# Description
As a Logged-in User (Super Admin, Admin, or Employee), I want to see my full profile details (name, email, role, photo) fetched from the backend so that I can verify my identity and account status.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/api/v1/endpoints/auth.py`
> * `mobile/lib/features/profile/profile_screen.dart`
> * `mobile/lib/features/auth/auth_provider.dart`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: Display Profile Data**
    - Given I am logged in
    - When I navigate to the Profile screen
    - Then the system fetches my latest data from the `/auth/me` endpoint.
    - Then I see my Name, Email, Role, and Profile Photo.
- [x] **Scenario 2: Profile Photo Placeholder**
    - Given I do not have a profile photo set
    - When I view my profile
    - Then a modern default avatar/placeholder is displayed.

# UI element
- Profile screen with user information cards and a circular profile image.

# Technical Notes (Architect)
- Ensure the backend `/auth/me` endpoint returns all required fields.
- Use `CachedNetworkImage` for profile photos to optimize performance.

# Reviewer Feedback (Reviewer)
1. **Verified**: The `ProfileScreen` now correctly displays Name, Email, Role, and Photo.
2. **Verified**: `CachedNetworkImage` is implemented for profile photos.
3. **Verified**: A modern Neumorphic placeholder avatar is displayed when no photo is available.
4. **Verified**: `fetchProfile()` is called in `initState` to ensure latest data is displayed.
5. **Quality**: The code follows Neumorphism design patterns and project architecture.

