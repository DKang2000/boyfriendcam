# Proposed Native Architecture

## Overview

The native rewrite should use a camera-service core with SwiftUI layered on top, not a SwiftUI-first camera implementation. The preview, frame delivery, still capture, Vision inference, motion updates, and persistence work should live in dedicated services so the live camera path stays fast and predictable.

## Major Modules

- `App` bootstraps the native app, routes between camera/history/review, and wires dependencies.
- `AppCore` owns shared models, feature flags, instrumentation helpers, and typed configuration.
- `Features/Camera` renders the live camera screen, prompt pill, selectors, overlay surface, and capture controls.
- `Features/Coaching` renders ready-state UI, prompt text, persona UI, and coaching support panels.
- `Features/History` and `Features/Review` own the quieter post-capture flows.
- `Services/Camera` owns `AVCaptureSession`, preview hosting, photo capture, and burst sequencing.
- `Services/Pose` owns Vision body pose requests, pose normalization, frame metrics, scoring, guidance, and lighting summary extraction.
- `Services/Motion` owns `CoreMotion` sampling plus portrait / portrait-upside-down normalization.
- `Services/Persistence` owns session metadata, file references, deletion, and explicit export.
- `DesignSystem` keeps layout tokens, colors, text styles, and overlay styling separate so later pixel-polish work can move quickly without touching the capture engine.

## Data Flow

1. `CameraSessionController` starts `AVCaptureSession`.
2. Preview frames go to `AVCaptureVideoPreviewLayer` for the live image.
3. The same session feeds throttled sample buffers to `PoseDetectionService`.
4. `PoseDetectionService` runs Vision pose requests and produces normalized landmarks plus compact lighting summaries.
5. `MotionService` publishes normalized roll/pitch samples.
6. A coaching pipeline combines pose, motion, lighting, shot template config, and persona selection.
7. The pipeline outputs a compact `CameraCoachingSnapshot`.
8. SwiftUI reads that snapshot and updates the prompt pill, overlay status, level bar, and ready-state chrome.
9. Still capture goes through `PhotoCaptureService`, then review/history read lightweight session metadata from `SessionStore`.

## Camera Pipeline

- Use `AVCaptureSession` with:
  - `AVCaptureDeviceInput`
  - `AVCaptureVideoDataOutput` for analysis
  - `AVCapturePhotoOutput` for still capture
- Use `AVCaptureVideoPreviewLayer` for the preview instead of trying to draw camera pixels through SwiftUI.
- Keep session configuration on a dedicated session queue.
- Keep video frame callbacks on a dedicated output queue.
- Avoid converting frames into `UIImage` in the live loop.
- If analysis lags, drop stale analysis frames instead of allowing a queue backlog.

## Pose Pipeline

- Use `VNDetectHumanBodyPoseRequest` or the current best Vision body-pose API available at implementation time.
- Normalize landmarks into portrait-space coordinates before scoring so overlays, prompt logic, and upside-down behavior all read from one coordinate system.
- Throttle inference to a stable cadence rather than trying to analyze every preview frame.
- Produce a compact struct with only the metrics needed by the coaching pipeline.
- Do not make SwiftUI observe raw landmark arrays directly if a smaller snapshot will do.

## Scoring And Guidance Flow

- Port the RN scoring logic into pure Swift structs and services.
- Keep the same concepts:
  - frame metrics
  - weighted template scoring
  - issue severity ranking
  - prompt prioritization
  - prompt debounce
  - secondary hint hold rules
  - ready-state stable window and exit hysteresis
- Keep persona phrasing data-driven so copy changes do not require logic changes.
- Publish a small UI-facing snapshot instead of many observable fields to reduce update churn.

## Motion / Level Flow

- Use `CoreMotion` gravity or device motion updates for roll/pitch.
- Normalize those readings against the active preview orientation so portrait and portrait-upside-down remain directionally consistent.
- Feed motion into the same coaching snapshot as pose and lighting rather than maintaining separate UI state machines.

## Capture / Session History Flow

- `PhotoCaptureService` captures a still only when the user taps.
- `BurstCaptureCoordinator` sequences `1`, `3`, `5`, or `10` still captures and reports progress.
- `SessionStore` writes lightweight JSON metadata plus file URLs under app-local storage.
- Review reads one `SessionRecord` at a time, including hero frame index and crop preview selection.
- Export uses `PhotoKit` only when the user explicitly chooses save/export.

## Main Thread Vs Background

Main thread

- SwiftUI rendering
- navigation state
- lightweight snapshot publication
- preview layer hosting and layout

Background / dedicated queues

- capture session configuration and lifecycle
- sample buffer delivery
- Vision pose inference
- luminance summary extraction
- score and guidance evaluation
- burst sequencing
- metadata and file writes

## Expected Bottlenecks

- Vision body pose inference cost on older iPhones
- Any accidental image conversion or pixel-buffer copy in the hot loop
- Publishing too much SwiftUI state too frequently
- Still capture latency during `5` and `10` shot bursts
- File I/O after burst completion
- Motion + pose disagreement during upside-down rotation transitions

## Why This Supports Pixel-Perfect UI Later

- The preview is hosted natively, so polish work can focus on overlay composition instead of camera plumbing.
- The live camera screen can iterate quickly because visuals live in SwiftUI and `DesignSystem`, while the hot path stays in services.
- Typed templates and prompt data make it easy to retune spacing, hierarchy, and copy without risking camera performance.
- A compact coaching snapshot lets the team refine prompt placement and animation without binding the UI directly to raw frame-processing state.

## iOS-4 Performance Instrumentation

- `OSSignposter` intervals now cover:
  - `camera_startup`
  - `preview_start`
  - `frame_analysis`
  - `guidance_update`
  - `photo_capture`
  - `burst_capture`
  - `history_write`
- `OSSignposter` events now cover:
  - `photo_capture_saved`
  - `burst_completion`
- The hot camera loop stays off the main thread:
  - `AVCaptureVideoDataOutput` work stays on `videoOutputQueue`
  - Vision pose inference stays inside `PoseDetectionService`
  - lighting sampling stays inside `LightingAnalysisService`
  - only the final UI-facing results are published back to the main actor
- `CameraShellViewModel` now suppresses redundant coaching snapshot publishes so unchanged prompt state does not cause avoidable SwiftUI work.
- `MotionGuidanceService` suppresses duplicate motion publishes to reduce steady-state UI churn.

## Instruments Workflow

1. Build and run the app on a physical iPhone.
2. Open Instruments and choose the `Points of Interest` template first.
3. Filter for subsystem `com.boyfriendcam.native`.
4. Inspect these intervals while using the live camera:
   - `frame_analysis` for Vision + lighting cadence
   - `guidance_update` for coaching recompute cost
   - `photo_capture` for shutter responsiveness
   - `burst_capture` for multi-shot pacing
   - `history_write` for post-capture persistence cost
5. Re-run with `Time Profiler` if `frame_analysis` or `guidance_update` grows enough to threaten preview smoothness.
6. Re-run with `Hangs` or `Animation Hitches` while repeatedly entering review/history and flipping between portrait and portrait-upside-down.

## MetricKit

- `MetricKitObserver` is now registered at app startup.
- In debug builds, expect MetricKit to be mainly useful on-device over longer sessions rather than during one short simulator run.
- Use it as a follow-up signal for hangs, CPU spikes, and diagnostics that do not show up during short local traces.

## Hitch-Prone QA

- Manual hardware QA should specifically check:
  - live preview smoothness while prompt text changes rapidly
  - switching between upright portrait and portrait-upside-down without awkward control reach
  - repeated `5` and `10` shot bursts
  - opening review/history immediately after capture
  - saving to Photos immediately after a burst review
- Unit performance tests now cover the pure-Swift scoring and coaching path, but they do not replace device-side camera profiling.

## Remaining Visual Deltas In This Checkout

- `reference/` is not present in the current clone, so the iOS-4 pass could only align by documented hierarchy and prior audit notes, not pixel-match the original stills.
- The prompt pill is now slimmer and more camera-first, but final yellow tone, text wrapping, and top offset still need device-side comparison against the missing reference images.
- The overlay is intentionally lighter and sharper, but exact silhouette proportions and dashed crosshair rhythm still need visual confirmation against the unavailable reference stills.
- Review/history are calmer and more subordinate now, but the exact spacing/iconography relationship to the live camera surface still needs final reference-backed signoff.
