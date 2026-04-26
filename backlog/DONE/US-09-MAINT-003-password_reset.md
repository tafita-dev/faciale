---
id: US-09-MAINT-003
title: Password Reset Functionality
status: DONE
type: feature
---
# Description
As a User (Admin or Employee), I want to be able to reset my password if I forget it so that I can securely regain access to my account without manual intervention from a Super Admin.

# Context Map
- Backend: `backend/app/api/v1/endpoints/auth.py`
- Backend: `backend/app/core/security.py`
- Mobile: `mobile/lib/features/auth/forgot_password_screen.dart`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Request Password Reset**
    - Given a user has forgotten their password
    - When they enter their registered email on the "Forgot Password" screen
    - Then the system should send a password reset token/link (or log it for now if email is not configured).
- [x] **Scenario 2: Complete Password Reset**
    - Given a valid reset token
    - When the user provides a new password (min 6 chars)
    - Then their password should be updated in the database, and they should be able to login with the new password.
- [x] **Scenario 3: Invalid/Expired Token**
    - Given an invalid or expired reset token
    - When the user attempts to reset their password
    - Then the system should return an error message and refuse the update.

# Technical Notes (Architect)
- Add `POST /auth/password-reset-request` and `POST /auth/password-reset-confirm`.
- Use a short-lived JWT or a random token stored in MongoDB with an expiration field for reset verification.
- For now, since an email server might not be available, return the token/link in the API response in development mode or log it.
