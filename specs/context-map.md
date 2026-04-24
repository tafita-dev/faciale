# Context Map

## Feature Map

| Feature / Module | Backend Directory | Mobile Directory | Entry Point (BE/FE) |
| :--- | :--- | :--- | :--- |
| **Authentication** | `backend/app/api/v1/endpoints/auth.py` | `mobile/lib/features/auth/` | `POST /auth/login` / `login_screen.dart` |
| **Organization Mgmt** | `backend/app/api/v1/endpoints/orgs.py` | `mobile/lib/features/dashboard/` | `POST /orgs` / `org_dashboard.dart` |
| **Employee Enrollment** | `backend/app/services/enrollment.py` | `mobile/lib/features/employees/` | `POST /employees` / `enroll_screen.dart` |
| **Face Recognition** | `backend/app/services/recognition.py` | `mobile/lib/features/attendance/` | `POST /attendance/scan` / `scan_screen.dart` |
| **Liveness (Anti-Spoof)** | `backend/app/services/liveness.py` | N/A | Internal Service |
| **Vector Search** | `backend/app/repositories/vector_db.py` | N/A | Qdrant Client |
| **Reporting** | `backend/app/api/v1/endpoints/reports.py` | `mobile/lib/features/dashboard/` | `GET /reports` / `report_view.dart` |

## Dependency Graph
*   `services/recognition` depends on `repositories/vector_db` and `services/liveness`.
*   `api/v1/endpoints` depends on `services/`.
*   `mobile/features/attendance` depends on `mobile/core/network`.
