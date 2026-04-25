---
id: US-08-SEC-004
title: Flutter Environment Configuration with .env
status: DONE
type: feature
---
# Description
As a Developer, I want to use a .env file for mobile environment configuration so that I can easily change the backend base URL and other settings without modifying the code.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `mobile/pubspec.yaml`
> * `mobile/.env`
> * `mobile/lib/main.dart`
> * `mobile/lib/features/auth/auth_provider.dart`
> * `mobile/lib/features/organizations/org_provider.dart`

# Acceptance Criteria (DoD)
- [ ] A `.env` file exists in the `mobile/` directory.
- [ ] The app loads environment variables at startup.
- [ ] The backend `baseUrl` is retrieved from the `.env` file.
- [ ] Changing the `baseUrl` in `.env` updates the app's target backend after restart.

# Technical Notes (Architect)
- Use `flutter_dotenv` package.
- Add `.env` to `assets` in `pubspec.yaml`.
- Initialize `DotEnv` in `main.dart`.
- Update all providers to use `dotenv.env['API_URL']`.
