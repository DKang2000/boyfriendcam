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
