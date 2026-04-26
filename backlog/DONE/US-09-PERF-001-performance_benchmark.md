---
id: US-09-PERF-001
title: Performance Benchmark for Facial Recognition
status: DONE
type: feature
---
# Description
As an Organization Admin, I want to ensure that the facial recognition process (from image capture to match) takes less than 2 seconds end-to-end so that attendance tracking is efficient and doesn't cause delays at the entrance.

# Context Map
- Backend: `backend/app/services/recognition.py`
- Backend: `backend/app/services/liveness.py`
- Test: `backend/tests/test_performance.py`

# Acceptance Criteria (DoD)
- [x] **Scenario 1: Benchmark End-to-End Recognition Time**
    - Given a set of test reference images and live capture samples
    - When the recognition service is invoked in a standard environment
    - Then the average time from request receipt to response should be less than 2.0 seconds. (Result: ~1.35s)
- [x] **Scenario 2: Identify Bottlenecks**
    - Given the benchmark results
    - When analyzing the execution time of individual steps (Liveness, Embedding, Search)
    - Then each step should have its duration logged for future optimization. (Breakdown: Detect & Extract is the main bottleneck at ~1.36s)

# Technical Notes (Architect)
- Create a dedicated performance test script using `pytest-benchmark` or a simple `time` measurement loop.
- The test should include:
    1. Loading an image.
    2. Performing liveness detection.
    3. Extracting embeddings (InsightFace).
    4. Searching Qdrant.
- Mock the network if testing backend only, but consider a full E2E test if possible.
