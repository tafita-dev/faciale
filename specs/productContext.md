# Product Context

## 1. Project Identity
*   **Name:** Faciale
*   **Core Value:** Secure and seamless attendance tracking through advanced facial recognition.
*   **Target Audience:** Educational institutions and corporate organizations.

## 2. High-Level Architecture
*   **Type:** Mobile App (Flutter) + Backend API (Python/FastAPI).
*   **Tech Stack:**
    *   Frontend: Flutter
    *   Backend: FastAPI (Python)
    *   Primary Database: MongoDB (User data, metadata)
    *   Vector Database: Qdrant (Facial embeddings)
    *   AI/ML: InsightFace / OpenCV (Face Detection & Recognition)
*   **Key Patterns:** Repository Pattern, Service Layer Pattern, Clean Architecture.

## 3. Core Domain Flows
1.  **Organization Onboarding:** Admin creates an Organization -> Organization Admin sets up Departments and Enrolls Employees with reference photos -> Embeddings are stored in Qdrant.
2.  **Attendance Check-in:** Employee opens the app -> Camera captures face -> Backend performs liveness detection (anti-deepfake) -> Face is matched against Qdrant vector store -> Attendance is logged in MongoDB if matched.
3.  **Management:** Organization Admin views attendance reports and manages employee profiles.
