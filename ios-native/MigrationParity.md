# Migration Parity Map

## Repo Inspection Summary

### Exact Current RN Files Responsible For Key Behaviors

| Behavior Area | Current RN Source |
| --- | --- |
| Shot type definitions | `src/config/shotTemplates.ts` |
| Crop preview definitions | `src/config/cropPreviews.ts` |
| Overlay templates / framing guides | `src/milestone1/ShotTemplateOverlay.tsx` |
| Selector UI | `src/milestone1/ShotTemplateSelector.tsx`, `src/milestone3b/BurstSelector.tsx`, `src/milestone3b/CropPreviewSelector.tsx` |
| Ready-state plumbing | `src/milestone1/readiness.ts`, `src/milestone2/scoring.ts`, `src/milestone2/controller.ts`, `src/milestone2/useMilestoneTwoCoaching.ts` |
| Scoring engine | `src/milestone2/frameMetrics.ts`, `src/milestone2/scoring.ts` |
| Guidance engine / prompt selection | `src/milestone2/guidance.ts`, `src/milestone2/controller.ts` |
| Persona packs | `src/milestone2/personas.ts` |
| Voice / speech handling | `src/milestone2/speech.ts`, `src/milestone2/useMilestoneTwoCoaching.ts` |
| Lighting logic | `src/milestone3a/lightingAnalyzer.ts`, `packages/vision-camera-pose-landmarks-plugin/ios/MediaPipeFrameProcessor.swift` |
| Orientation / level logic | `src/milestone3a/orientationAnalyzer.ts`, `src/milestone3a/useDeviceMotionAnalyzer.ts` |
| Pose frame processing / normalization | `src/milestone0/usePoseFrameProcessor.ts`, `src/milestone0/pose.ts`, `packages/vision-camera-pose-landmarks-plugin/src/index.ts` |
| Burst capture | `src/milestone3b/captureOrchestrator.ts` |
| Crop preview rendering | `src/milestone3b/CropPreviewMask.tsx` |
| Session history / persistence | `src/milestone3b/sessionModel.ts`, `src/milestone3b/sessionStore.ts`, `src/milestone3b/types.ts` |
| Review / history screens | `src/milestone3b/SessionReviewScreen.tsx`, `src/milestone3b/HistoryScreen.tsx`, `src/milestone3b/SessionImage.tsx` |
| Capture orchestration / app wiring | `src/milestone0/MilestoneZeroScreen.tsx` |

### `reference/` Status

- `reference/step-back.png`
- `reference/tilt-up.png`
- `reference/flip-upside-down.png`
- `reference/upright-overlay.png`
- `reference/upside-down-ui.png`

### Milestone 3A / 3B Docs And Checklists

- Present:
  - `docs/manual-qa/milestone-3a-checklist.md`
  - `docs/manual-qa/milestone-3b-checklist.md`
  - `docs/manual-qa/reference-alignment-checklist.md`
  - `docs/reference-alignment-audit.md`

### RN Files Most Reusable As Behavior References

- `src/config/shotTemplates.ts`
- `src/config/cropPreviews.ts`
- `src/milestone2/types.ts`
- `src/milestone2/frameMetrics.ts`
- `src/milestone2/scoring.ts`
- `src/milestone2/guidance.ts`
- `src/milestone2/controller.ts`
- `src/milestone2/personas.ts`
- `src/milestone3a/lightingAnalyzer.ts`
- `src/milestone3a/orientationAnalyzer.ts`
- `src/milestone3b/captureOrchestrator.ts`
- `src/milestone3b/sessionModel.ts`
- `src/milestone3b/sessionStore.ts`
- `docs/manual-qa/*`
- `docs/reference-alignment-audit.md`

### Areas Likely To Need Retuning Instead Of Literal Parity

- Pose thresholds because Vision and MediaPipe do not produce identical landmarks
- Lighting thresholds because the RN app currently relies on MediaPipe-adjacent luminance summaries produced in the custom plugin
- Motion phrasing and upside-down normalization because the native rewrite will depend directly on `CoreMotion`
- Burst responsiveness because `AVCapturePhotoOutput` timing differs from the current VisionCamera path
- Review/history styling because the reference images only strongly define the live camera surface

## Parity Table

| Module / Behavior | Current RN Source File(s) | Proposed Native Destination File(s) | Parity Status | Risk | Notes | Validation Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Shot templates | `src/config/shotTemplates.ts` | `ios-native/AppCore/Models/ShotTemplate.swift` | direct parity | medium | Carry over template ids, guide modes, overlay geometry, scoring ranges, ready thresholds, and priorities as typed Swift data. | Unit test every template id, range, and weight against the RN registry. |
| Overlay rendering | `src/milestone1/ShotTemplateOverlay.tsx` | `ios-native/Features/Camera/Overlay/ShotTemplateOverlayView.swift` | retune in native | high | Preserve template-driven geometry, but redraw with native vector paths and align visual weight to `reference/*`. | Manual QA against `reference/upright-overlay.png` and live-device screenshots. |
| Selector UI | `src/milestone1/ShotTemplateSelector.tsx`, `src/milestone3b/BurstSelector.tsx`, `src/milestone3b/CropPreviewSelector.tsx` | `ios-native/Features/Camera/ShotTemplateSelectorView.swift`, `ios-native/Features/Camera/BurstSelectorView.swift`, `ios-native/Features/Camera/CropPreviewSelectorView.swift` | redesign in native | low | Keep behavior and option sets; rebuild layout as iOS-native horizontal controls. | Snapshot/UI tests plus manual feel check for thumb reach and visual clutter. |
| Score engine | `src/milestone2/frameMetrics.ts`, `src/milestone2/scoring.ts` | `ios-native/Services/Pose/FrameMetricsBuilder.swift`, `ios-native/Services/Pose/ScoreEngine.swift` | direct parity | high | Reimplement as pure Swift. Keep score dimensions, weighting, and ready candidate rules. | Unit tests using shared fixture expectations from the RN suite. |
| Prompt selection | `src/milestone2/guidance.ts`, `src/milestone2/controller.ts` | `ios-native/Services/Pose/GuidanceEngine.swift`, `ios-native/Services/Pose/ReadyStateController.swift` | direct parity | high | Preserve candidate families, conflict suppression, prompt debounce, and secondary hint hold logic. | Unit tests for contradictory prompt suppression and ready-state hysteresis. |
| Persona phrasing | `src/milestone2/personas.ts` | `ios-native/Services/Pose/PersonaRepository.swift` | direct parity | low | Copy strings exactly unless product copy intentionally changes later. | Unit tests for every `PersonaId` x `PromptMeaning` lookup. |
| Voice prompt logic | `src/milestone2/speech.ts`, `src/milestone2/useMilestoneTwoCoaching.ts` | `ios-native/Services/Pose/VoicePromptService.swift`, `ios-native/Features/Coaching/CoachingViewModel.swift` | retune in native | medium | Behavior should match, but `AVSpeechSynthesizer` cadence may need tuning relative to Expo Speech. | Manual QA for cooldown, duplicate suppression, and voice-off parity. |
| Ready-state logic | `src/milestone1/readiness.ts`, `src/milestone2/scoring.ts`, `src/milestone2/controller.ts` | `ios-native/Services/Pose/ReadyStateController.swift` | direct parity | medium | Keep stable-enter and hysteresis-exit behavior; do not flash green from one good frame. | Unit tests plus hardware QA for “near ready” jitter. |
| Lighting detection | `src/milestone3a/lightingAnalyzer.ts`, `packages/vision-camera-pose-landmarks-plugin/ios/MediaPipeFrameProcessor.swift` | `ios-native/Services/Pose/LightingAnalyzer.swift`, `ios-native/Services/Pose/LightingSummaryExtractor.swift` | retune in native | high | Keep `low_light`, `backlit`, `harsh_overhead` semantics, but compute native luminance summaries from camera buffers. | Unit tests with deterministic fixtures plus hardware QA in dim/backlit/overhead scenes. |
| Level / orientation | `src/milestone3a/orientationAnalyzer.ts`, `src/milestone3a/useDeviceMotionAnalyzer.ts` | `ios-native/Services/Motion/MotionService.swift`, `ios-native/Services/Motion/OrientationAnalyzer.swift` | retune in native | high | Preserve prompt meanings and upside-down correctness; normalize directly from `CoreMotion` and preview orientation. | Hardware QA for portrait and portrait-upside-down directional consistency. |
| Burst capture | `src/milestone3b/captureOrchestrator.ts` | `ios-native/Services/Camera/BurstCaptureCoordinator.swift`, `ios-native/Services/Camera/PhotoCaptureService.swift` | retune in native | high | Keep sequential `1/3/5/10` behavior and duplicate-tap lockout. Native capture timings will differ. | Unit tests for orchestration plus hardware QA for responsiveness and heat. |
| Crop preview | `src/config/cropPreviews.ts`, `src/milestone3b/CropPreviewMask.tsx` | `ios-native/AppCore/Models/CropPreview.swift`, `ios-native/Features/Camera/Overlay/CropPreviewMaskView.swift`, `ios-native/Features/Review/CropPreviewMaskView.swift` | direct parity | low | Keep the same aspect ratios and mask math. | Unit tests using the current RN expected rects. |
| Session persistence | `src/milestone3b/sessionModel.ts`, `src/milestone3b/sessionStore.ts`, `src/milestone3b/types.ts` | `ios-native/Services/Persistence/SessionRecord.swift`, `ios-native/Services/Persistence/SessionStore.swift`, `ios-native/Services/Persistence/SessionFileManager.swift` | direct parity | medium | Preserve lightweight metadata and file references. Prefer app-local JSON/file management first. | Unit tests for create/list/update/delete and relaunch persistence. |
| Review / history screens | `src/milestone3b/SessionReviewScreen.tsx`, `src/milestone3b/HistoryScreen.tsx`, `src/milestone3b/SessionImage.tsx` | `ios-native/Features/Review/SessionReviewScreen.swift`, `ios-native/Features/History/HistoryScreen.swift`, `ios-native/Features/History/SessionDetailScreen.swift` | redesign in native | medium | Preserve behavior and metadata, but rebuild as calmer native surfaces that do not overpower the camera. | UI tests for navigation and manual review for visual hierarchy. |
| Save / export flow | `src/milestone0/MilestoneZeroScreen.tsx`, `src/milestone3b/HistoryScreen.tsx`, `src/milestone3b/SessionReviewScreen.tsx` | `ios-native/Services/Persistence/ExportService.swift` | direct parity | low | Keep explicit user-triggered export only, with permission requested at that moment. | Manual permission-flow QA and UI test coverage where practical. |
| Live camera shell wiring | `src/milestone0/MilestoneZeroScreen.tsx` | `ios-native/Features/Camera/CameraScreen.swift`, `ios-native/Features/Coaching/CoachingViewModel.swift`, `ios-native/Services/Camera/CameraSessionController.swift` | redesign in native | high | RN currently centralizes many concerns in one screen. Native rewrite should split hot path services from UI composition. | Milestone-by-milestone integration checks and signpost traces. |
| Pose frame processor and normalization | `src/milestone0/usePoseFrameProcessor.ts`, `src/milestone0/pose.ts`, `packages/vision-camera-pose-landmarks-plugin/src/index.ts` | `ios-native/Services/Pose/PoseDetectionService.swift`, `ios-native/Services/Pose/PoseNormalizer.swift` | redesign in native | high | Same behavior intent, but implementation moves from VisionCamera + MediaPipe to `AVFoundation` + `Vision`. | Signpost traces for inference time and dropped frame counts. |

## Recommended Parity Posture

- Preserve directly:
  - template ids and scoring config intent
  - prompt meanings and persona strings
  - ready-state rules
  - crop preview math
  - session metadata shape
  - explicit save/export behavior
- Retune natively:
  - pose thresholds
  - lighting heuristics
  - motion thresholds
  - burst timing
  - prompt pill sizing for native typography
- Redesign natively:
  - camera screen composition
  - selector styling
  - history/review layout chrome
  - preview/control integration
