---
id: US-01-AUTH-003
title: Implement JWT Authentication and Login
status: DONE
type: feature
---
# Description
As a User (Admin/Org Admin), I want to log in with my email and password to receive a JWT token so that I can access protected endpoints securely.

# Context Map
> Reference @specs/context-map.md
> Specific files for this story:
> * `backend/app/api/v1/endpoints/auth.py`
> * `backend/app/core/security.py`
> * `backend/app/services/auth_service.py`

# Acceptance Criteria (DoD)
- [ ] **Scenario 1:** Successful Login
    - Given a valid user exists in MongoDB
    - When I POST to `/api/v1/auth/login` with correct credentials
    - Then I should receive a 200 OK with a `access_token` and `token_type` "bearer"
- [ ] **Scenario 2:** Invalid Credentials
    - Given a user exists but I provide a wrong password
    - When I POST to `/api/v1/auth/login`
    - Then I should receive a 401 Unauthorized error
- [ ] **Scenario 3:** Protected Endpoint Access
    - Given a valid JWT token
    - When I request a protected endpoint (e.g., `/api/v1/users/me`)
    - Then I should receive the user's data
- [ ] **Scenario 4:** Expired/Invalid Token
    - Given an expired or malformed token
    - When I request a protected endpoint
    - Then I should receive a 401 Unauthorized error

# Technical Notes (Architect)
- Use `passlib[bcrypt]` for password hashing.
- Use `python-jose` for JWT tokens.
- Implement a dependency `get_current_user` for route protection.
- Roles: "admin" and "org_admin" must be encoded in claims or verified from DB.
