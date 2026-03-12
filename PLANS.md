# BoyfriendCam Plan

## Working Assumptions

- Repo starts empty and needs full Expo app scaffolding
- Planning artifacts can be created now, but implementation must wait for approval
- Reference visuals are not yet available in `/reference`
- The app will target a single-subject happy path in v1
- The v1 camera UX is portrait-first with upside-down portrait support
- Landscape is not a first-class v1 path
- Public branding uses `BoyfriendCam`, while internal app identifiers remain swappable placeholders
- The implementation will prefer Expo-managed workflows with development builds, escalating to a thin native module only when VisionCamera/frame-processing demands it

## Architecture Direction

### App Shell

- Expo + TypeScript
- `expo-router` for app structure and screens
- development build with VisionCamera and required native plugins
- local persistence via AsyncStorage or SQLite-backed Expo storage depending on history needs
- single Expo app repo, not a monorepo

### Domain Layers

1. `config`
   - shot templates
   - personas
   - crop masks
   - feature flags
2. `analysis`
   - pose/framing adapter
   - frame analysis engine
   - lighting analyzer
   - horizon analyzer
   - confidence smoothing
3. `guidance`
   - rules
   - persona formatting
   - prompt debounce/state machine
4. `capture`
   - single capture
   - burst orchestration
   - save pipeline
5. `ui`
   - camera chrome
   - overlays
   - prompt bar
   - crop preview
   - history views

### Key Technical Choice

The analyzer layer will be defined behind interfaces so the initial heuristic implementation can later be replaced by a learned model without rewriting the UI or guidance layers.

## Milestones

### Milestone 0: Technical Spike

Goal:
De-risk the camera and frame-analysis foundation before broader app buildout.

Scope:

- camera permission flow
- live preview
- frame processor hook
- on-device pose landmarks exposed to JS
- simple debug overlay
- upside-down portrait support
- single capture

Exit criteria:

- development build launches on target devices
- camera permission flow works
- live preview renders
- frame processor hook executes reliably
- pose landmark data reaches JS in a structured payload
- debug overlay can visualize landmark/framing output
- upside-down portrait normalization is validated
- single capture works or blockers are explicitly documented

### Milestone 1: Foundation and Scaffolding

Goal:
Create the Expo project, establish architecture folders, configure TypeScript/lint/test tooling, wire development-build dependencies, and add product docs/compliance placeholders.

Exit criteria:

- Expo app boots
- iOS/Android dev build config is present
- module skeletons and typed config models exist
- lint and test commands run

### Milestone 2: Camera Shell and Overlay System

Goal:
Stand up live preview, shot selection, overlay rendering, crop masks, personas, and the ready-state UI shell with mocked analysis.

Exit criteria:

- live camera preview renders
- shot template overlays switch correctly
- crop masks render for `1:1`, `4:5`, `9:16`
- prompt bar and ready-state UI work from mocked scores

### Milestone 3: Deterministic Analysis Pipeline

Goal:
Integrate on-device analysis for framing geometry, lighting heuristics, tilt, and temporal smoothing.

Exit criteria:

- analysis loop produces structured scores in real time
- centeredness/headroom/subject size/tilt are computed
- lighting states are detected heuristically
- upside-down orientation logic is handled

### Milestone 4: Guidance Engine and Persona Output

Goal:
Translate scores into debounced prompts and optional spoken guidance using persona packs.

Exit criteria:

- prompt rules map low scores to guidance strings
- prompts are debounced and stable
- voice prompts are optional and never replace visible text
- green ready state depends on score thresholds

### Milestone 5: Capture, Burst, Save, and History

Goal:
Implement single capture, burst capture, local save flow, and session history.

Exit criteria:

- burst modes `3`, `5`, `10` work
- capture pipeline saves locally
- session history screen lists captures and metadata
- permissions remain minimal

History metadata for v1 includes:

- local photo URI/reference
- generated thumbnail reference
- timestamp
- shot template
- persona
- burst count and selected frame index
- final angle score
- ready-state flag
- top guidance prompts shown
- lighting state
- tilt/horizon state

### Milestone 6: Store Setup and Release Docs

Goal:
Finish store configuration, EAS setup, privacy copy, checklist docs, and submission guidance.

Exit criteria:

- app config and `eas.json` are complete
- package/bundle IDs are set
- store/privacy docs exist
- screenshot/assets checklist exists

## Design Alignment Pass

If `/reference` is added before Milestone 2 UI work, run a short design-alignment pass to calibrate camera chrome, prompt presentation, and overlay feel without copying the reference product.

## Validation Strategy

- Unit tests for config registries, scoring helpers, and guidance mapping
- Integration tests for scoring-to-prompt behavior
- Manual device validation for camera preview, capture, orientation, and performance
- Per-milestone lint/test run before stopping for review

## Risks and Mitigations

### Real-Time Pose/Frame Processing in Expo

Risk:
VisionCamera plus local landmark inference may require native setup beyond a simple managed Expo path.

Mitigation:
Start with a development build, isolate the analyzer adapter, and keep a fallback path where simulated or reduced analysis validates the UI shell before native optimization.

### Lighting Heuristic Reliability

Risk:
Low-light/backlight/harsh-overhead detection can be noisy across devices.

Mitigation:
Keep lighting guidance advisory, apply thresholds with smoothing, and avoid making it gate ready-state capture.

### Orientation Complexity

Risk:
Upside-down support can break tilt interpretation and overlay transforms.

Mitigation:
Keep orientation normalization centralized in `HorizonAnalyzer` and explicitly test normal + upside-down portrait flows.

### Burst Performance

Risk:
Burst capture timing and save throughput may vary by device.

Mitigation:
Implement `CaptureOrchestrator` with bounded burst sizes and explicit queueing, then validate on both platforms.

## Review Gates

- Gate 1: approve planning docs and repo structure
- Gate 2: approve Milestone 0 technical spike results
- Gate 3: approve foundation/scaffold milestone
- Gate 4: approve camera shell before live analysis integration
- Gate 5: approve guidance quality before capture/history finalization
- Gate 6: approve release docs and submission checklist
