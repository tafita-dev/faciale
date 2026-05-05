---
id: US-10-ENH-006
title: Global - Multi-language Support (FR/EN)
status: DONE
type: feature
---
# Description
As a User, I want to choose between French and English so that I can use the app in my preferred language.

# Context Map
- Mobile: `mobile/lib/features/settings/language_provider.dart`

# Acceptance Criteria (DoD)
- [ ] **Scenario 1: Language Toggle**
    - Given I am in the settings
    - When I select "Français"
    - Then all UI text should immediately translate to French.
- [ ] **Scenario 2: Persistence**
    - Given I have selected "Français"
    - When I restart the app
    - Then the app should still be in French.

# Technical Notes (Architect)
- Use `flutter_localizations` or a dedicated package like `easy_localization`.
- Create `en.json` and `fr.json` translation files.

# Reviewer Feedback
The implementation is incomplete and does not meet the "Zero Compromise" quality standard.

**Issues:**
1. **Incomplete Localization:** Only the main screens (Login, Dashboard, Profile) were localized. Many other user-facing screens still contain hardcoded English strings:
   - `forgot_password_screen.dart`
   - `reports_screen.dart`
   - `scanner_screen.dart`
   - `directory_screen.dart`
   - `employees_screen.dart`
   - `create_org_screen.dart`
   - `enroll_screen.dart`
   - `create_user_screen.dart`
   - `departments_screen.dart`
2. **Acceptance Criteria Failure:** The DoD explicitly states "all UI text should immediately translate".
3. **Leftover Code:** I found a debug `print(file)` in `backend/app/api/v1/endpoints/employees.py` which was unrelated to this ticket. (I have removed it).

**Required Actions:**
- Audit all `.dart` files in `mobile/lib` for hardcoded strings.
- Move all hardcoded strings to `en.json` and `fr.json`.
- Use `.tr()` for all user-facing text, including tooltips, placeholders, and error messages.
- Update tests to ensure they continue to pass (currently they expect keys because `easy_localization` is not initialized in tests, which is fine for now but should be consistent).
