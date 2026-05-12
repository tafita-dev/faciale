---
id: HOTFIX-MOBILE-SCAN-002
title: Fix InputImageConverterError during scanning and enrollment
status: DONE
type: hotfix
---

# Description
Frontend fails during face scanning and enrollment with `PlatformException(InputImageConverterError, ImageFormat is not supported., null, null)`. This is caused by incorrect handling of YUV420 camera frames on Android when converting to ML Kit's InputImage.

# Acceptance Criteria
- [x] Correctly concatenate all planes for YUV420 format on Android.
- [x] Ensure correct InputImageFormat is used based on the platform.
- [x] Verify that scanning and enrollment no longer throw ImageFormat is not supported error.

# Technical Notes
- Use `WriteBuffer` from `flutter/foundation.dart` to concatenate `CameraImage` planes.
- Fallback to platform-specific default formats if `InputImageFormatValue.fromRawValue` returns null.
