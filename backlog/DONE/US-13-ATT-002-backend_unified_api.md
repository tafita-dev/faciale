---
id: US-13-ATT-002
title: Backend - Unified Attendance API
status: DONE
type: feature
---

# Description
As a Mobile Client, I want a unified endpoint for facial attendance that returns semantic UI metadata, so that I can display clear and dynamic feedback to the user.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> *   `backend/app/api/v1/endpoints/attendance.py`
> *   `backend/app/services/recognition.py`

# Acceptance Criteria (DoD)

- [ ] **Scenario 1: Successful check-in response**
    - Given a valid image and an authenticated user
    - When calling `POST /attendance/check-in`
    - Then the API returns `200 OK` if similarity score >= 0.7
    - And the JSON includes `ui` object with `color` ("green" for entry, "blue" for exit) and `icon` ("login" or "logout")
    - And the message is "Bienvenue [Name]" (for entry) or "Au revoir [Name]" (for exit)

- [ ] **Scenario 2: No face detected**
    - Given an image without a visible face
    - When calling the endpoint
    - Then the API returns an error with message "Aucun visage détecté"

- [ ] **Scenario 3: User not recognized**
    - Given a face that doesn't match any employee with score >= 0.7
    - When calling the endpoint
    - Then the API returns an error with message "Utilisateur non reconnu"
    - And `ui.color` is "red" in the error payload (or equivalent for failure)

- [ ] **Scenario 4: Spoof detected**
    - Given a photo of a photo or video playback
    - When calling the endpoint
    - Then the API returns an error with message "Vérification échouée" (liveness failure)

# Technical Notes (Architect)
- Validate image format (JPEG/PNG) and size limits.
- Ensure HTTPS is enforced.
- Similarity threshold must be strictly >= 0.7.
- Response structure must match PRD requirements exactly.
