# BoyfriendCam Tasks

## Planning

- [x] Define product scope, non-goals, and success criteria
- [x] Define milestone-based implementation plan
- [x] Propose repo structure and modular architecture
- [x] Create vibecoding documentation artifacts

## Milestone 0: Technical Spike

- [ ] Validate camera permission flow in Expo development builds
- [ ] Validate live preview with VisionCamera
- [ ] Validate frame processor hook execution
- [ ] Validate on-device pose landmarks exposed to JS
- [ ] Build a simple debug overlay for landmark/framing output
- [ ] Validate upside-down portrait support
- [ ] Validate single capture path
- [ ] Document blockers, tradeoffs, and fallback options if native integration is required

## Milestone 1: Foundation and Scaffolding

- [ ] Initialize Expo + TypeScript app
- [ ] Add Expo development build configuration
- [ ] Configure VisionCamera prerequisites
- [ ] Add linting, formatting, and test scripts
- [ ] Create base folder structure for config, analysis, guidance, capture, UI, storage, and screens
- [ ] Add feature flags for future selfie/group modes
- [ ] Add placeholder brand assets and app metadata
- [ ] Add baseline navigation and app shell

## Milestone 2: Camera Shell and Overlay System

- [ ] Run design-alignment pass if `/reference` is added before UI work
- [x] Implement camera permissions and preview shell
- [x] Build shot template selector
- [x] Define `ShotTemplate` configs for all MVP shot types
- [ ] Define `CropMask` configs for `1:1`, `4:5`, `9:16`
- [x] Render ghost silhouette overlays per shot type
- [x] Render crosshair / thirds guides
- [x] Build prompt bar and ready-state chrome
- [ ] Build mocked analyzer feed for UI development
- [x] Preserve the pose debug overlay behind a dev-only toggle for QA

## Milestone 3: Deterministic Analysis Pipeline

- [ ] Define analyzer interfaces and typed score payloads
- [ ] Implement pose/framing adapter abstraction
- [ ] Implement centeredness scoring
- [ ] Implement headroom scoring
- [ ] Implement feet visibility scoring for `full_body`
- [ ] Implement eye-line scoring for portrait-oriented templates
- [ ] Implement subject-size scoring
- [ ] Implement shoulder balance / symmetry scoring
- [ ] Implement pitch / tilt scoring
- [ ] Implement lower-angle recommendation heuristic
- [ ] Implement crop-safety scoring for IG masks
- [ ] Implement confidence smoothing over time
- [ ] Implement lighting analyzer heuristics
- [ ] Implement orientation normalization and upside-down support

## Milestone 4: Guidance and Persona Output

- [ ] Define `CoachPersonaPack` configs for `nice`, `sassy`, `mean`
- [ ] Define `GuidanceRule` configs mapped to score dimensions
- [ ] Implement guidance rule engine
- [ ] Implement prompt prioritization and debounce behavior
- [ ] Add optional spoken prompts
- [ ] Ensure text prompts remain visible during voice guidance
- [ ] Bind ready-state UI to score thresholds

## Milestone 5: Capture, Save, and History

- [ ] Implement single capture
- [ ] Implement burst counts `3`, `5`, `10`
- [ ] Implement capture queueing/orchestration
- [ ] Implement local save flow
- [ ] Persist session metadata for history
- [ ] Build history screen
- [ ] Build post-capture or pre-capture IG preview flow
- [ ] Validate permission minimization
- [ ] Store only saved-photo references and lightweight shot metadata
- [ ] Avoid raw frame-by-frame analysis persistence and duplicate full-size image storage

## Milestone 6: Release Setup and Compliance

- [ ] Configure package name and bundle identifier
- [ ] Add `eas.json`
- [ ] Add build commands for iOS and Android
- [ ] Add submit commands for App Store / TestFlight / Google Play
- [ ] Write privacy copy for on-device analysis
- [ ] Create App Store submission checklist
- [ ] Create Google Play submission checklist
- [ ] Create store screenshots/assets checklist

## Ongoing

- [ ] Append `VIBECODE_LOG.md` after each milestone
- [ ] Save main execution prompts under `PROMPTS/`
- [ ] Run lint/tests after each milestone
- [ ] Stop for review after each milestone
