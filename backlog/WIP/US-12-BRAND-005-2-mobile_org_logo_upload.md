---
id: US-12-BRAND-005-2
title: Mobile - Organization Logo Upload UI
status: IN_PROGRESS
type: feature
priority: MEDIUM
---

# Description
As a Super Admin, I want to upload a logo during organization creation so that the organization has a visual identity from the start.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/features/organizations/create_org_screen.dart`

# Acceptance Criteria (DoD)

- [ ] **Scenario 1: Image Picker for Logo**
    - Given I am on the Create Organization screen
    - When I tap the "Add Logo" placeholder
    - Then I can select an image from the gallery or camera.
- [ ] **Scenario 2: Upload during Creation**
    - Given I have selected a logo
    - When I submit the creation form
    - Then the logo is uploaded and associated with the new organization.

# Technical Notes (Architect)
- Use `image_picker` Flutter package.
- Display a preview of the selected image.
- Ensure the upload happens either as part of the multipart form or in a subsequent call.
