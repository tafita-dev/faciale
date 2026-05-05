---
id: US-12-BRAND-005-1
title: Backend - Organization Logo Support & Upload API
status: DONE
type: feature
priority: MEDIUM
---

# Description
As a Developer, I want to update the organization model and implement an upload API so that we can support organization logos.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/models/org.py`
> * `backend/app/api/v1/endpoints/orgs.py`
> * `backend/app/services/storage.py`

# Acceptance Criteria (DoD)

- [ ] **Scenario 1: Organization Model Update**
    - Given the `Organization` model
    - When updated
    - Then it includes a `logo_url` field.
- [ ] **Scenario 2: Logo Upload API**
    - Given an image file
    - When I call the organization logo upload endpoint
    - Then the file is saved (local or S3) and the `logo_url` is returned.

# Technical Notes (Architect)
- Update `OrgCreate` and `Org` Pydantic models.
- Reuse or extend `StorageService` for handling the image file.
- Add an endpoint `POST /orgs/{org_id}/logo`.
