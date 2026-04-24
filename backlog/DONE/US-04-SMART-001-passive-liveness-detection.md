status: DONE
type: feature
---
# Description
As a System, I want to verify if a captured image is from a live person so that I can prevent spoofing attacks using photos, videos, or screens.

# Context Map
> Reference @specs/context-map.md to find file paths.
> Specific files for this story:
> * `backend/app/services/recognition.py`
> * `backend/app/api/v1/endpoints/attendance.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Live Person Detected**
    - Given a photo of a real person captured live
    - When the liveness detection module processes it
    - Then it should return `is_live: true` with a high confidence score.
- [x] **Scenario 2: Photo-of-Photo Spoofing Detected**
    - Given a photo of a printed photograph
    - When the liveness detection module processes it
    - Then it should return `is_live: false` and identify the spoofing attempt.
- [x] **Scenario 3: Screen Playback Spoofing Detected**
    - Given a photo of a face on a digital screen (laptop/phone)
    - When the liveness detection module processes it
    - Then it should return `is_live: false`.

# UI element
None (Backend Logic).

# Technical Notes (Architect)
- Use `InsightFace` or a specialized lightweight liveness detection model (e.g., MiniFASNet).
- The detection should be "passive" (no user movement required) to meet the < 2s performance requirement.
- Integration point: `RecognitionService.verify_liveness(image_bytes)`.

# Reviewer Feedback (Reviewer)
## 2026-04-23 - REWORK REQUIRED
The current implementation fails to meet the core security requirements and acceptance criteria of this ticket.

1.  **Ineffective Liveness Detection:** The Laplacian variance heuristic only detects **blur**. While useful as a pre-filter, it is entirely ineffective against sharp spoofing attempts (high-resolution photos, modern smartphone screens, or high-definition monitors). Scenario 2 and 3 of the Acceptance Criteria will fail in any real-world situation where the spoofing source is in focus.
2.  **Failure to meet Technical Notes:** The Architect requested a "specialized lightweight liveness detection model (e.g., MiniFASNet)". Settling for a basic image processing heuristic is not a valid substitute for a security feature.
3.  **Incomplete Ticket:** The Acceptance Criteria (DoD) have not been checked in the ticket file, and `specs/04-EPICS.md` was not updated to reflect the `IN_PROGRESS` status of Epic 4.

**Recommended Fix:**
- Integrate a proper pre-trained liveness model (like **Silent-Face-Anti-Spoofing** or **MiniFASNet**) in ONNX format. These are designed to detect the subtle textures and Moiré patterns that distinguish real faces from screens or paper.
- If you cannot find a model in the local environment, you may need to research how to include a lightweight one or provide a more robust combination of heuristics (e.g., texture analysis + color histograms) while clearly stating the limitations. However, a model-based approach is strongly preferred.

