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

- [x] Run design-alignment pass if `/reference` is added before UI work
- [x] Implement camera permissions and preview shell
- [x] Build shot template selector
- [x] Define `ShotTemplate` configs for all MVP shot types
- [x] Define `CropMask` configs for `1:1`, `4:5`, `9:16`
- [x] Render ghost silhouette overlays per shot type
- [x] Render crosshair / thirds guides
- [x] Build prompt bar and ready-state chrome
- [x] Build mocked analyzer feed for UI development
- [x] Preserve the pose debug overlay behind a dev-only toggle for QA

## Milestone 3: Deterministic Analysis Pipeline

- [x] Define analyzer interfaces and typed score payloads
- [x] Implement pose/framing adapter abstraction
- [x] Implement centeredness scoring
- [x] Implement headroom scoring
- [x] Implement feet visibility scoring for `full_body`
- [x] Implement eye-line scoring for portrait-oriented templates
- [x] Implement subject-size scoring
- [x] Implement shoulder balance / symmetry scoring
- [x] Implement pitch / tilt scoring
- [ ] Implement lower-angle recommendation heuristic
- [x] Implement crop-safety scoring for IG masks
- [x] Implement confidence smoothing over time
- [x] Implement lighting analyzer heuristics
- [x] Implement orientation normalization and upside-down support

## Milestone 4: Guidance and Persona Output

- [x] Define `CoachPersonaPack` configs for `nice`, `sassy`, `mean`
- [x] Define `GuidanceRule` configs mapped to score dimensions
- [x] Implement guidance rule engine
- [x] Implement prompt prioritization and debounce behavior
- [x] Add optional spoken prompts
- [x] Ensure text prompts remain visible during voice guidance
- [x] Bind ready-state UI to score thresholds

## Milestone 5: Capture, Save, and History

- [x] Implement single capture
- [x] Implement burst counts `3`, `5`, `10`
- [x] Implement capture queueing/orchestration
- [x] Implement local save flow
- [x] Persist session metadata for history
- [x] Build history screen
- [x] Build post-capture or pre-capture IG preview flow
- [x] Validate permission minimization
- [x] Store only saved-photo references and lightweight shot metadata
- [x] Avoid raw frame-by-frame analysis persistence and duplicate full-size image storage

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
- [x] Run lint/tests after each milestone
- [x] Stop for review after each milestone

## Native iOS Rewrite

- [x] Inspect `reference/*`, milestone docs, QA docs, and current RN behavior sources before planning
- [x] Create `ios-native/AGENTS.md`
- [x] Create `ios-native/Prompt.md`
- [x] Create `ios-native/Plan.md`
- [x] Create `ios-native/Documentation.md`
- [x] Create `ios-native/MigrationParity.md`
- [ ] iOS-0: native scaffold + camera shell
- [ ] iOS-1: pose pipeline + overlay/template parity
- [ ] iOS-2: scoring/guidance/persona parity
- [ ] iOS-3: lighting/level/burst/crop/history parity
- [ ] iOS-4: pixel polish + performance hardening + release prep
- [ ] Run native hardware QA for upright portrait and portrait-upside-down before release signoff
