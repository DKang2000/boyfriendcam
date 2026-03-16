# Native iOS Rewrite Plan

## Planning Summary

- Milestone boundaries remain aligned with the current product split because the repo already separates:
  - camera shell + overlay/template UI
  - scoring/guidance/persona logic
  - lighting/orientation analysis
  - burst/crop/history/persistence
- No third-party dependency is planned for the native shipping path.
- The React Native app remains the parity oracle while `ios-native/` becomes the new shipping runtime.

## Default Assumptions

- iPhone-first
- portrait-first camera UX
- upside-down portrait required
- no iPad optimization in the first native release
- on-device only in the live loop
- explicit save/export only, with permission requested at that moment

## Proposed Native Module Layout

- `ios-native/App/`
  - app entry, scene setup, dependency wiring
- `ios-native/AppCore/`
  - app environment, feature flags, shared models, logging, instrumentation
- `ios-native/Features/Camera/`
  - camera screen, preview overlays, capture controls, template/crop selectors
- `ios-native/Features/Coaching/`
  - coaching state model, prompt pill, persona mapping, ready-state UI
- `ios-native/Features/History/`
  - history list, deletion, session loading
- `ios-native/Features/Review/`
  - post-capture review, filmstrip, crop preview overlay, export affordances
- `ios-native/Features/Settings/`
  - voice toggle and persona selection
- `ios-native/Services/Camera/`
  - `CameraSessionController`, preview host, photo output, burst sequencing
- `ios-native/Services/Pose/`
  - `PoseDetectionService`, pose normalization, lighting summary extraction
- `ios-native/Services/Motion/`
  - `MotionService`, gravity normalization, upside-down handling
- `ios-native/Services/Persistence/`
  - session index store, file management, export coordinator
- `ios-native/DesignSystem/`
  - colors, typography, spacing, pills, cards, overlay tokens
- `ios-native/Testing/`
  - scoring/guidance/config fixtures, integration harnesses, UI test plans
- `ios-native/Docs/`
  - milestone notes, performance notes, hardware tuning notes

## Milestones At A Glance

| Milestone | Goal | Primary Output |
| --- | --- | --- |
| `iOS-0` | Native scaffold + stable camera shell | Preview, app shell, permission flow, instrumentation skeleton |
| `iOS-1` | Pose pipeline + overlay/template parity | Vision pose feed, overlay renderer, selectors, crop masks |
| `iOS-2` | Scoring/guidance/persona parity | Pure-Swift score engine, prompt prioritization, ready-state, voice |
| `iOS-3` | Lighting/level/burst/crop/history parity | Lighting, Core Motion, burst/review/history/persistence/export |
| `iOS-4` | Pixel polish + performance hardening + release prep | Visual alignment, hardware tuning, UI tests, release readiness |

## Milestone Details

### iOS-0 native scaffold + camera shell

Goal

- Stand up the native app skeleton and a smooth, instrumentation-ready camera shell without importing any RN runtime behavior.

Expected files/modules to create or change

- `ios-native/App/BoyfriendCamNativeApp.swift`
- `ios-native/App/AppEnvironment.swift`
- `ios-native/AppCore/Models/AppRoute.swift`
- `ios-native/AppCore/Instrumentation/PerformanceSignposts.swift`
- `ios-native/DesignSystem/ColorTokens.swift`
- `ios-native/DesignSystem/SpacingTokens.swift`
- `ios-native/Features/Camera/CameraScreen.swift`
- `ios-native/Features/Camera/CameraPreviewContainer.swift`
- `ios-native/Services/Camera/CameraSessionController.swift`
- `ios-native/Services/Camera/CameraPreviewView.swift`
- `ios-native/Services/Camera/CameraAuthorizationService.swift`
- `ios-native/Testing/Unit/NativeScaffoldSmokeTests.swift`

Acceptance criteria

- Native app launches into a camera-first shell.
- Camera permission flow works and keeps the user on a clean gate when denied.
- `AVCaptureVideoPreviewLayer` runs inside a UIKit host bridged into SwiftUI.
- Preview startup and steady-state operation stay smooth for at least 60 seconds on target iPhones.
- Camera shell already supports portrait and portrait-upside-down orientation handling at the session layer.

Validation commands

- `xcodebuild -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16' build`
- `xcodebuild test -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16'`

Stop conditions

- Stop if preview smoothness depends on pushing frame processing or session configuration onto the main thread.
- Stop if upside-down orientation cannot be normalized cleanly in the preview/capture layer.

Main risks

- Preview layer / SwiftUI integration mistakes causing black frames or layout jank
- Session startup latency from over-configuring outputs too early

Tuning questions likely to arise on hardware

- What startup latency feels acceptable on recent iPhones?
- Does the preview stay stable when rotating into portrait-upside-down mid-session?
- Does the bottom control layout feel thumb-natural in both portrait directions?

### iOS-1 pose pipeline + overlay/template parity

Goal

- Add the Vision pose pipeline and recreate the live overlay/template behavior with native rendering and data-driven template definitions.

Expected files/modules to create or change

- `ios-native/AppCore/Models/ShotTemplate.swift`
- `ios-native/AppCore/Models/CropPreview.swift`
- `ios-native/Features/Camera/ShotTemplateSelectorView.swift`
- `ios-native/Features/Camera/CropPreviewSelectorView.swift`
- `ios-native/Features/Camera/Overlay/ShotTemplateOverlayView.swift`
- `ios-native/Features/Camera/Overlay/CropPreviewMaskView.swift`
- `ios-native/Features/Camera/Overlay/PoseDebugOverlayView.swift`
- `ios-native/Services/Pose/PoseDetectionService.swift`
- `ios-native/Services/Pose/PoseNormalizer.swift`
- `ios-native/Services/Pose/PoseFrame.swift`
- `ios-native/Testing/Unit/ShotTemplateConfigTests.swift`
- `ios-native/Testing/Unit/CropPreviewMathTests.swift`

Acceptance criteria

- Vision body pose produces normalized landmarks suitable for the same six templates.
- Shot template registry is data-driven, typed, and behavior-matched to the RN definitions.
- Ghost silhouette, crosshair, thirds guides, and crop masks render at native frame rates.
- The live camera screen visually stays camera-first and lightweight.
- Debug overlay remains dev-only and does not leak into shipping UX.

Validation commands

- `xcodebuild -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16' build`
- `xcodebuild test -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BoyfriendCamNativeTests/ShotTemplateConfigTests`
- `xcodebuild test -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BoyfriendCamNativeTests/CropPreviewMathTests`

Stop conditions

- Stop if Vision inference frequency causes preview hitching or SwiftUI overlay thrash.
- Stop if overlay alignment differs materially between portrait and portrait-upside-down.

Main risks

- Vision landmark geometry will not match MediaPipe exactly, so overlay and tolerance tuning may drift
- Over-updating SwiftUI state could make overlay motion feel noisy

Tuning questions likely to arise on hardware

- What inference cadence feels stable without burning battery or introducing guidance lag?
- Do the overlay line weights still read in bright rooms and dark rooms?
- Is the silhouette placement close enough to the reference feel in both portrait directions?

### iOS-2 scoring/guidance/persona parity

Goal

- Port the deterministic coaching stack into pure Swift while preserving product behavior and prompt stability.

Expected files/modules to create or change

- `ios-native/AppCore/Models/ScoreTypes.swift`
- `ios-native/AppCore/Models/PersonaPack.swift`
- `ios-native/AppCore/Models/GuidanceRule.swift`
- `ios-native/Features/Coaching/CoachingViewModel.swift`
- `ios-native/Features/Coaching/PromptPillView.swift`
- `ios-native/Features/Coaching/CoachingSupportCard.swift`
- `ios-native/Features/Settings/VoiceSettingsView.swift`
- `ios-native/Services/Pose/FrameMetricsBuilder.swift`
- `ios-native/Services/Pose/ScoreEngine.swift`
- `ios-native/Services/Pose/GuidanceEngine.swift`
- `ios-native/Services/Pose/ReadyStateController.swift`
- `ios-native/Services/Pose/PersonaRepository.swift`
- `ios-native/Services/Pose/VoicePromptService.swift`
- `ios-native/Testing/Unit/ScoreEngineTests.swift`
- `ios-native/Testing/Unit/GuidanceEngineTests.swift`
- `ios-native/Testing/Unit/ReadyStateControllerTests.swift`
- `ios-native/Testing/Unit/PersonaRepositoryTests.swift`

Acceptance criteria

- Score dimensions, prompt prioritization, secondary hint behavior, hysteresis, and persona phrasing match current RN behavior closely.
- Voice remains optional and never replaces visible text.
- A single primary prompt remains stable instead of oscillating between contradictory instructions.
- Ready-state behavior uses the same “stable window / exit hysteresis” intent as the RN app.

Validation commands

- `xcodebuild test -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BoyfriendCamNativeTests/ScoreEngineTests`
- `xcodebuild test -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BoyfriendCamNativeTests/GuidanceEngineTests`
- `xcodebuild test -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BoyfriendCamNativeTests/ReadyStateControllerTests`

Stop conditions

- Stop if the native coaching loop requires business logic inside SwiftUI view bodies.
- Stop if prompt churn can only be controlled by lowering update frequency enough to harm responsiveness.

Main risks

- Vision landmark differences may shift score thresholds
- Voice cadence may differ when moving from Expo Speech to `AVSpeechSynthesizer`

Tuning questions likely to arise on hardware

- Are prompt-switch hold times still correct on iPhone hardware with a real camera feed?
- Do persona phrases fit cleanly inside the prompt pill without truncation?
- Do ready-state thresholds need per-template adjustment after native pose retuning?

### iOS-3 lighting/level/burst/crop/history parity

Goal

- Complete product parity for lighting, motion-backed guidance, burst capture, review, history, persistence, and explicit save/export.

Expected files/modules to create or change

- `ios-native/Features/Camera/LevelBarView.swift`
- `ios-native/Features/Camera/BurstSelectorView.swift`
- `ios-native/Features/Review/SessionReviewScreen.swift`
- `ios-native/Features/Review/SessionFilmstripView.swift`
- `ios-native/Features/History/HistoryScreen.swift`
- `ios-native/Features/History/HistoryRowView.swift`
- `ios-native/Features/History/SessionDetailScreen.swift`
- `ios-native/Services/Motion/MotionService.swift`
- `ios-native/Services/Motion/OrientationAnalyzer.swift`
- `ios-native/Services/Pose/LightingAnalyzer.swift`
- `ios-native/Services/Camera/BurstCaptureCoordinator.swift`
- `ios-native/Services/Camera/PhotoCaptureService.swift`
- `ios-native/Services/Persistence/SessionRecord.swift`
- `ios-native/Services/Persistence/SessionStore.swift`
- `ios-native/Services/Persistence/SessionFileManager.swift`
- `ios-native/Services/Persistence/ExportService.swift`
- `ios-native/Testing/Unit/LightingAnalyzerTests.swift`
- `ios-native/Testing/Unit/OrientationAnalyzerTests.swift`
- `ios-native/Testing/Unit/BurstCaptureCoordinatorTests.swift`
- `ios-native/Testing/Unit/SessionStoreTests.swift`

Acceptance criteria

- Lighting guidance handles low light, backlight, and harsh overhead conditions without dominating obviously bad framing corrections.
- Level and tilt guidance remain directionally correct in portrait and portrait-upside-down.
- Burst capture supports `1`, `3`, `5`, and `10` sequential stills with visible progress and duplicate-tap lockout.
- Review and history preserve the current RN behavior while keeping the camera surface visually primary.
- Session metadata persists locally across relaunches without requesting library permission.
- Save/export requests permission only when the user taps save/export.

Validation commands

- `xcodebuild test -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BoyfriendCamNativeTests/LightingAnalyzerTests`
- `xcodebuild test -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BoyfriendCamNativeTests/OrientationAnalyzerTests`
- `xcodebuild test -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BoyfriendCamNativeTests/BurstCaptureCoordinatorTests`
- `xcodebuild test -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BoyfriendCamNativeTests/SessionStoreTests`

Stop conditions

- Stop if burst sequencing causes preview teardown or visible UI freezes.
- Stop if history/review visual weight starts overpowering the live camera screen.

Main risks

- Native lighting summaries will differ from the current MediaPipe-derived stats
- Burst cadence and still-capture responsiveness will vary across iPhone hardware
- Persistence and hero-frame updates can introduce accidental file churn

Tuning questions likely to arise on hardware

- What burst cadence remains responsive without preview instability or thermal spikes?
- Do motion prompts remain intuitive when the user flips to upside-down portrait mid-session?
- Does history remain lightweight enough after dozens of sessions?

### iOS-4 pixel polish + performance hardening + release prep

Goal

- Align the live camera surface to the reference stills, harden the hot path, and prepare for release execution.

Expected files/modules to create or change

- `ios-native/DesignSystem/CameraChromeTokens.swift`
- `ios-native/Features/Camera/CameraScreen.swift`
- `ios-native/Features/Coaching/PromptPillView.swift`
- `ios-native/Features/History/HistoryScreen.swift`
- `ios-native/Features/Review/SessionReviewScreen.swift`
- `ios-native/Docs/PerformanceTuning.md`
- `ios-native/Docs/HardwareQA.md`
- `ios-native/Docs/ReleaseChecklist.md`
- `ios-native/Testing/UI/HistoryFlowUITests.swift`
- `ios-native/Testing/UI/ReviewFlowUITests.swift`

Acceptance criteria

- Dedicated visual-alignment pass has been run against:
  - `reference/step-back.png`
  - `reference/tilt-up.png`
  - `reference/flip-upside-down.png`
  - `reference/upright-overlay.png`
  - `reference/upside-down-ui.png`
- Prompt pill placement, overlay hierarchy, control spacing, and upside-down ergonomics are visually intentional and consistent.
- Signpost traces show no obvious main-thread blocking in camera startup, preview start, pose inference, scoring/guidance, capture, burst completion, or persistence writes.
- Review/history feel visually supportive, not dominant.
- Hardware QA is complete on at least one upright-portrait iPhone and one upside-down portrait pass.

Validation commands

- `xcodebuild -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16' build`
- `xcodebuild test -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16'`
- `xcodebuild test -project ios-native/BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNativeUITests -destination 'platform=iOS Simulator,name=iPhone 16'`
- Instruments runs using Time Profiler and Points of Interest with native signposts enabled

Stop conditions

- Stop if polish work masks unresolved hot-path regressions.
- Stop if visual alignment starts adding clutter or control density that harms usability.

Main risks

- Pixel-perfect reference matching can tempt the implementation toward brittle chrome or custom controls
- Polish changes can accidentally reintroduce SwiftUI update thrash

Tuning questions likely to arise on hardware

- Is the prompt pill still legible over varied backgrounds and longer persona copy?
- Are bottom controls equally comfortable in upright and upside-down portrait?
- Do review/history screens stay calm enough after final visual polish?

## Camera And Performance Strategy

- Host the preview with `AVCaptureVideoPreviewLayer` inside `UIViewRepresentable` to keep the live surface fast and stable.
- Run session configuration and start/stop work on a dedicated camera session queue.
- Feed video frames into `AVCaptureVideoDataOutput` on a dedicated output queue.
- Run Vision pose requests on a pose actor or dedicated inference queue and drop stale frames when the analyzer is busy.
- Convert pose + motion + lighting summaries into a compact `CameraCoachingSnapshot` before touching SwiftUI state.
- Only publish UI snapshots when materially changed to avoid overlay and prompt thrash.
- Keep still capture on `AVCapturePhotoOutput` and avoid copying full-size images unless a capture is explicitly taken.

## Instrumentation Strategy

- Add `os_signpost` / `OSSignposter` markers around:
  - camera startup
  - preview start
  - pose inference
  - scoring/guidance update
  - photo capture
  - burst completion
  - session persistence/history write
- Record signposts in debug and internal builds by default.
- Pair signposts with lightweight counters for dropped analysis frames, capture latency, and persistence duration.
- Use Instruments “Points of Interest” plus Time Profiler during iOS-3 and iOS-4.

## Validation Strategy

- Unit tests for:
  - shot template config
  - crop preview math
  - frame metrics
  - score engine
  - guidance engine
  - ready-state controller
  - persona repository
  - lighting analyzer
  - orientation analyzer
  - burst coordinator
  - persistence/session store
- UI tests where practical for:
  - history navigation
  - review flow
  - delete flow
  - save/export permission surfacing
- Manual hardware QA checkpoints for:
  - upright portrait
  - upside-down portrait
  - prompt stability
  - capture responsiveness
  - burst responsiveness
  - history persistence
  - save/export permission flow

## Visual Alignment Pass

- Treat the reference images as the design bar for live camera hierarchy, not as full-product screen coverage.
- Prioritize:
  - prompt pill placement and visual weight
  - thin overlay hierarchy
  - integrated bottom control spacing
  - upside-down ergonomics
  - minimal visual clutter
  - polished iPhone-native feel
- Keep history/review aligned to the same language, but calmer and less dominant than the camera surface.
