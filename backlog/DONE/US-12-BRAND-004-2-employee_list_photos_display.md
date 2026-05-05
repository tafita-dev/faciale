---
id: US-12-BRAND-004-2
title: Employee Management - Display Photos in List
status: DONE
type: feature
priority: MEDIUM
---

# Description
As an Admin, I want to see the photo of each employee in the list so that I can easily identify them visually.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/lib/features/employees/employees_screen.dart`

# Acceptance Criteria (DoD)

- [x] **Scenario 1: Photos in List**
    - Given I am on the Employee List screen
    - When the list loads
    - Then each employee entry displays their reference photo (thumbnail).

# UI element
- Employee List item (Photo thumbnail).

# Technical Notes (Architect)
- Use `CircleAvatar` or rounded `ClipRRect` for the photo.
- Ensure efficient loading of images using pagination or lazy loading (already implemented in list).
- Handle cases where the photo is missing with a placeholder.
