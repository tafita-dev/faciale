# Technical Architecture

## 1. Tech Stack
*   **Mobile:** Flutter (State management: Riverpod)
*   **Backend:** FastAPI (Python 3.11+)
*   **Primary DB:** MongoDB (Motor for async driver)
*   **Vector DB:** Qdrant (Dockerized)
*   **AI Engine:** InsightFace (RetinaFace for detection, ArcFace for embedding)
*   **Anti-Spoofing:** Silent-Face-Anti-Spoofing.

## 2. Directory Structure
```text
faciale/
├── backend/
│   ├── app/
│   │   ├── api/v1/endpoints/  # API Routes
│   │   ├── core/              # Config, Security, Auth, Logging
│   │   ├── models/            # Pydantic (Domain & API)
│   │   ├── repositories/      # MongoDB & Qdrant logic
│   │   ├── services/          # Business Logic & AI Processing
│   │   ├── main.py            # Entry point
│   │   └── deps.py            # Dependencies (DI)
│   ├── requirements.txt
│   └── tests/
├── mobile/
│   ├── lib/
│   │   ├── core/              # Constants, Theme, Network, Providers
│   │   ├── features/          # Feature-based architecture
│   │   │   ├── auth/
│   │   │   ├── attendance/
│   │   │   ├── employees/
│   │   │   └── dashboard/
│   │   ├── main.dart
│   └── pubspec.yaml
└── docker-compose.yml
```

## 3. API Standards & Patterns
*   **Response Format:**
    ```json
    {
      "success": true,
      "data": {},
      "message": "Optional feedback"
    }
    ```
*   **Error Handling:** Use standard HTTP status codes. Errors should return:
    ```json
    {
      "success": false,
      "error": {
        "code": "ERROR_CODE",
        "message": "Human readable message"
      }
    }
    ```
*   **Authentication:** Bearer JWT in the header.

## 4. Database Schema (Refined)
### MongoDB: `faciale_db`
*   **Organizations:** `{ _id: UUID, name: string, type: "school"|"company", settings: { threshold: float }, created_at: datetime }`
*   **Departments:** `{ _id: UUID, org_id: UUID, name: string }`
*   **Employees:** `{ _id: UUID, org_id: UUID, dept_id: UUID, name: string, active: boolean, reference_image_url: string }`
*   **AttendanceLogs:** `{ _id: UUID, employee_id: UUID, org_id: UUID, timestamp: datetime, confidence: float, liveness_score: float, status: "success"|"failed" }`

### Qdrant: `embeddings`
*   **Vector Size:** 512
*   **Distance Metric:** Cosine
*   **Payload:** `{ "employee_id": string, "org_id": string }`

## 5. Coding Standards
*   **SOLID:** Each service handles one specific domain (e.g., `RecognitionService` vs `EnrollmentService`).
*   **Type Hints:** Mandatory in Python; No `dynamic` in Flutter.
*   **Security:** Biometric vectors are considered sensitive; API must use TLS.
