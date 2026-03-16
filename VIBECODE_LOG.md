# VibeCode Log

## Session 2026-03-11 - Planning Pass

### Prompt Used

- User requested a planning-only pass for BoyfriendCam with product requirements, architecture constraints, milestone workflow, and vibecoding proof requirements.
- User then answered five planning questions and requested a revised planning output with a Milestone 0 technical spike.

### What Codex Changed

- Created `PRD.md`
- Created `PLANS.md`
- Created `TASKS.md`
- Created `REPO_STRUCTURE.md`
- Created `PROMPTS/01-planning-pass.md`
- Created `PROMPTS/02-milestone-execution.md`
- Created `VIBECODE_LOG.md`
- Revised planning docs for naming, history scope, portrait-only v1 UX, single-app repo structure, `/reference` handling, and milestone order

### What Was Manually Reviewed

- Scope alignment against `AGENTS.md`
- Milestone boundaries and stop points
- Architecture split for config, analysis, guidance, capture, and UI
- Clarifying-answer impact on planning assumptions and milestone sequencing

### What Still Feels Risky

- Exact on-device landmark stack for VisionCamera in an Expo development build
- Lighting heuristic quality across devices
- Orientation and upside-down correctness once live analysis is integrated

## Session 2026-03-11 - Milestone 0 Technical Spike

### Prompt Used

- User requested implementation of Milestone 0 only: Expo development build, camera permissions, VisionCamera preview, realtime frame processor hook, on-device pose landmarks exposed to JS, simple debug overlay, upside-down portrait support, single photo capture, and milestone stop conditions.

### What Codex Changed

- Bootstrapped an Expo SDK 55 app in the repo
- Added development-build dependencies for VisionCamera, worklets, SVG overlay rendering, and Expo build properties
- Added a local VisionCamera frame-processor plugin package for MediaPipe pose landmarks
- Implemented a minimal spike screen with permission gating, live preview, realtime pose updates, debug overlay, orientation diagnostics, and single capture
- Added Expo/native config for camera permissions and Android min SDK requirements
- Added lint/typecheck scripts and config
- Added a Milestone 0 manual QA checklist

### What Was Manually Reviewed

- Package and app config shape
- Frame-processor hook structure and orientation normalization path
- Minimal UI scope against the Milestone 0 boundary

### What Still Feels Risky

- Android/iOS native build success for the local pose plugin until prebuild/device runs are exercised
- Runtime memory/performance impact of MediaPipe pose detection on older devices
- Orientation correctness in all portrait-upside-down capture combinations

## Session 2026-03-11 - Milestone 1A Product-Layer Camera UI

### Prompt Used

- User requested Milestone 1A only: add a shot type selector, data-driven shot templates, ghost/template overlays, framing guides, ready-state shell, and a dev-toggle for the debug overlay without increasing native risk.

### What Codex Changed

- Added a modular `ShotTemplate` registry/config for all six v1 shot types
- Added a placeholder readiness evaluator that uses current landmark coverage and alignment plumbing
- Added a product-layer shot selector and overlay system on top of the Milestone 0 preview
- Added ghost silhouette rendering and crosshair/rule-of-thirds guide rendering per selected shot type
- Added a green ready-state shell and score panel
- Moved the pose skeleton/diagnostics behind a dev-only toggle
- Added a Milestone 1A manual QA checklist
- Updated `TASKS.md` to reflect the completed camera-shell overlay items

### What Was Manually Reviewed

- Overlay config structure for future scoring-rule attachment
- Separation between native spike code and product-layer UI additions
- Placeholder readiness scoring path to keep it swappable later

### What Still Feels Risky

- Template overlays are heuristic placeholders and will need refinement once real scoring rules land
- Ready-state thresholds may feel too optimistic or too strict on actual devices
- Overlay readability may vary across bright outdoor scenes until visual tuning is done on hardware

## Session 2026-03-13 - Milestone 2 Realtime Scoring and Coaching

### Prompt Used

- User requested Milestone 2 only: implement the realtime scoring engine, guidance/rule engine, on-screen coaching prompts, optional voice coaching with persona packs, green ready-state behavior, template-specific targets, smoothing/hysteresis, deterministic tests, Milestone 2 QA checklist, and milestone doc updates.

### What Codex Changed

- Extended the shot-template registry with data-driven scoring targets, weights, tolerances, smoothing config, and ready-state thresholds per template
- Added a typed Milestone 2 analysis layer for frame metrics, weighted scoring, guidance derivation, persona copy, voice prompting, and ready-state control
- Replaced the placeholder ready shell with live coaching UI, stable primary prompt selection, optional secondary hints, and a local voice/persona control surface
- Added Expo Speech for optional spoken prompts while keeping visible text as the source of truth
- Added deterministic fixtures and unit tests for score computation, fallback behavior, prompt debounce, hysteresis, and persona phrasing
- Added `docs/manual-qa/milestone-2-checklist.md`
- Updated `TASKS.md` to mark the Milestone 2/3/4 items that are now implemented

### What Was Manually Reviewed

- Template-specific scoring emphasis for `full_body`, `half_body`, `portrait`, `outfit`, `instagram_story`, and `rule_of_thirds`
- Prompt prioritization rules to keep movement/framing guidance ahead of vague prompts
- Ready-state hysteresis and voice cooldown behavior
- Compatibility of the old Milestone 1 readiness wrapper with the new scoring engine

### What Still Feels Risky

- Real-device prompt tuning may still need threshold adjustments once more body shapes, distances, and room layouts are tested
- Voice prompting now works through Expo Speech, but cadence and interruption behavior may need polish after hands-on QA
- `Tilt the phone up/down` and `Raise/Lower the camera` share the same landmark signals today, so those distinctions are heuristic rather than sensor-driven
- Lighting analysis, stronger horizon logic, burst capture, history, and broader release prep are still intentionally deferred to later milestones

## Session 2026-03-13 - Milestone 3A Lighting and Sensor-Backed Level Guidance

### Prompt Used

- User requested Milestone 3A only: add deterministic lighting analysis, sensor-backed phone level/tilt assistance, a horizon/level overlay, guidance integration, tests/fixtures, a Milestone 3A manual QA checklist, and milestone doc updates.

### What Codex Changed

- Extended the canonical shot-template registry with lighting thresholds and orientation tolerances instead of creating a parallel config system
- Added deterministic lighting analysis for `low_light`, `backlit`, and `harsh_overhead` using compact frame-summary metrics
- Added a sensor-backed device-motion path for roll/tilt normalization, including portrait-upside-down support
- Added a minimal live level/tilt bar overlay to the preview
- Integrated lighting and orientation into the existing Milestone 2 scoring, prompt selection, ready-state, and debug telemetry pipeline
- Extended the local pose plugin to emit compact lighting summary stats alongside pose landmarks, rather than bridging pixel buffers into JS
- Added deterministic tests and fixtures for lighting classification, orientation classification, upside-down normalization, and prompt prioritization
- Added `docs/manual-qa/milestone-3a-checklist.md`
- Updated `TASKS.md` to mark the Milestone 3A analysis items complete

### What Was Manually Reviewed

- Reuse of the existing Milestone 2 guidance/controller path so prompt debounce and ready-state hysteresis still own the final UI behavior
- Threshold placement for lighting and level so framing guidance still wins when composition is clearly wrong
- Runtime fallback behavior when device-motion sensors are unavailable in an older dev build

### What Still Feels Risky

- Lighting thresholds are intentionally lightweight and will likely need real-device tuning across mixed indoor/outdoor scenes
- Device-motion pitch interpretation is now sensor-backed, but still needs hands-on validation for natural `tilt phone up/down` phrasing on hardware
- The iOS native lighting summary path was kept minimal for performance, so any future need for richer exposure analysis should be deferred to Milestone 3B instead of inflating this bridge
- Android native parity for the compact lighting summary path still needs device verification after the next Android QA pass

## Session 2026-03-13 - Milestone 3B Burst Capture, Crop Preview, and Local History

### Prompt Used

- User requested Milestone 3B only: burst capture selector/orchestrator, post-capture review flow, Instagram crop preview masks, local session history, optional explicit save/export flow, deterministic tests, a Milestone 3B manual QA checklist, and doc updates.

### What Codex Changed

- Reused the existing `MilestoneZeroScreen` capture/coaching path and extended it with burst selection, crop preview selection, review routing, and history entry
- Added a canonical app-local persistence layer for session metadata with lightweight file cleanup instead of creating parallel history state
- Added a modular sequential `CaptureOrchestrator` for `single`, `3`, `5`, and `10` shot sessions
- Added crop preview config/mask math for `none`, `1:1`, `4:5`, and `9:16`
- Added lightweight review and history UI with preferred-frame selection for burst sessions
- Added explicit save-to-library behavior that requests permission only when the user chooses to export
- Added deterministic tests for crop mask math, session modeling, store create/read/delete behavior, and capture orchestration
- Added `docs/manual-qa/milestone-3b-checklist.md`

### What Was Manually Reviewed

- Reuse of the existing shot-template selector, overlay renderer, and coaching snapshot instead of creating a second capture model
- Session metadata shape against the PRD history requirements
- Minimal-permission export flow so app-local history still works when library permission is denied
- Emulator compatibility for review/history using mock capture placeholders

### What Still Feels Risky

- Burst capture is intentionally sequential through the current VisionCamera photo API, not true hardware burst, so burst speed will vary by device
- Hero thumbnails currently reuse the original asset URI instead of generating derived thumbnail files, which keeps writes low but may need revisiting if history grows large
- Real-device QA should validate that sequential `10` shot bursts do not produce heat or memory regressions on older devices
- Export currently saves the hero frame only; richer multi-frame export workflows should wait for the next milestone rather than complicating this capture pass

## Session 2026-03-14 - Reference Ingestion and Live Camera Alignment Cleanup

### Prompt Used

- User requested a reference-ingestion and visual alignment pass only after adding the missing reference stills into `reference/`.

### What Codex Changed

- Verified and reused the five reference stills in `reference/`
- Audited the current live camera, burst, review, and history surfaces against the reference images
- Tightened the live camera hierarchy so the strong prompt pill, lighter overlay, and in-preview capture controls lead the experience again
- Reduced the visual weight of the shot selector, burst selector, crop selector, review screen, and history screen so Milestone 3B additions stay subordinate to the camera guidance loop
- Added `docs/reference-alignment-audit.md`
- Added `docs/manual-qa/reference-alignment-checklist.md`
- Updated `TASKS.md` to mark the alignment pass complete

### What Was Manually Reviewed

- Which parts of the current app could be directly aligned to the reference versus only style-aligned
- Prompt prominence, guide-line weight, silhouette feel, and live control placement
- Whether burst, review, and history screens should keep their structure while shifting toward the same visual language

### What Still Feels Risky

- The live camera surface is now closer to the reference, but exact iconography and top-control density are still style-adjacent rather than pixel-matched
- The bright top prompt pill should be rechecked on-device against longer prompts and bright environments
- The thinner silhouette and guide treatment should be validated against a wider range of backgrounds and clothing tones

## Session 2026-03-14 - Native iOS Rewrite Planning

### Prompt Used

- User requested a planning-only pass for a native iOS rewrite under `ios-native/`.
- The React Native / Expo app in the repo is now the product behavior reference, not the shipping runtime.
- The new shipping stack must be Swift + SwiftUI, `AVFoundation`, `Vision`, `CoreMotion`, and `PhotoKit` only for explicit save/export.
- The pass had to inspect the current repo first, confirm milestone 3A/3B state, inspect the reference stills, and produce native planning artifacts plus root task/log updates only.

### What Codex Changed

- Inspected the current RN implementation, reference assets, product docs, QA checklists, and native pose plugin package before planning
- Created `ios-native/AGENTS.md`
- Created `ios-native/Prompt.md`
- Created `ios-native/Plan.md`
- Created `ios-native/Documentation.md`
- Created `ios-native/MigrationParity.md`
- Updated `TASKS.md` with a dedicated native rewrite section
- Updated `VIBECODE_LOG.md` with this planning section

### What Was Manually Reviewed

- Exact RN source files currently responsible for templates, overlays, scoring, guidance, personas, speech, lighting, motion, burst capture, crop previews, and persistence
- The five reference stills that now define the live camera visual hierarchy and upside-down ergonomics
- Milestone 3A and 3B QA coverage plus the reference alignment audit/checklist
- Which RN modules are safe behavior references versus which areas will need native retuning

### What Still Feels Risky

- Replacing the current MediaPipe-based pose and lighting feed with a Vision-based native pipeline without losing prompt quality or live smoothness
- Preserving intuitive portrait-upside-down behavior across preview, motion guidance, capture, and bottom-control ergonomics
- Matching the reference camera feel while keeping review/history calm and clearly secondary to the live camera surface
