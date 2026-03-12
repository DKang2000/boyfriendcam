# BoyfriendCam PRD

## Product Summary

BoyfriendCam is a guided mobile camera app that helps a photographer take flattering, aesthetic photos of a single subject in real time. It is not a social network and not a post-processing editor. The app uses on-device heuristics to evaluate framing, lighting, and tilt, then gives short, readable coaching prompts before capture.

## Naming

- Public-facing working name for v1: `BoyfriendCam`
- Internal codename and package/bundle identifiers should remain swappable placeholders until release hardening

## Product Goal

Help a non-expert photographer consistently capture better-looking photos for another person with minimal effort and no manual photography knowledge.

## Target User

- A user handing their phone to a friend, partner, or stranger to take a better photo
- A photographer who wants simple, direct guidance instead of camera jargon
- A subject who cares about flattering composition, safe social crop framing, and outfit visibility

## Non-Goals

- No social feed, messaging, profiles, likes, or comments
- No backend or cloud inference in v1
- No broad photo editing workflow in v1
- No multi-person composition in v1
- No selfie mode in v1
- No learned aesthetic model in v1

## Core Experience

1. User opens the camera.
2. User selects a shot type and optional persona.
3. Live preview shows a ghost silhouette, framing guides, and prompt bar.
4. Analyzer scores framing, crop safety, tilt, and lighting in real time.
5. Guidance engine debounces the lowest-scoring issues into short prompts.
6. Ready state turns green when framing is sufficiently aligned.
7. User captures a single shot or burst.
8. User reviews an Instagram crop preview and the photo is saved locally.

## MVP Scope

### Shot Templates

- `full_body`
- `half_body`
- `portrait`
- `outfit`
- `instagram_story`
- `rule_of_thirds`

Each template must define:

- target subject box size
- preferred eye line or headroom
- feet visibility requirements when applicable
- overlay geometry and guide style
- crop safety thresholds for IG formats

### Real-Time Guidance

Guidance must:

- run on-device in the live camera loop
- convert low-scoring dimensions into short natural-language prompts
- remain visible even when voice mode is enabled
- debounce rapid prompt changes to avoid noisy UX

Example prompt families:

- move back slightly
- tilt phone down
- center subject
- zoom out a bit
- slightly lower the camera
- move left a little

### Coach Personas

Persona packs are predefined copy styles only:

- `nice`
- `sassy`
- `mean`

Personas change phrasing, not guidance logic.

### Lighting Detection

Detect and surface:

- `backlit`
- `low_light`
- `harsh_overhead`

Lighting analysis is heuristic-based and advisory, not a blocker for capture.

### Horizon / Tilt

- Show a tilt or horizon alignment bar
- Use device motion and/or visual estimation
- Support upside-down shooting correctly

### Capture

- Single capture
- Burst capture counts: `3`, `5`, `10`
- Save locally without requiring broad library permissions unless the save flow truly needs it

### IG Crop Preview

Preview masks for:

- `1:1`
- `4:5`
- `9:16`

## Functional Requirements

### Camera

- Live preview on iOS and Android in Expo development builds
- Uses `react-native-vision-camera` for preview, capture, and frame processing
- Uses a portrait-first camera UX in v1
- Supports upside-down portrait shooting
- Does not treat landscape as a first-class v1 path, but architecture should not block it later

### Analysis and Scoring

Deterministic, modular scoring dimensions:

- subject centeredness
- headroom
- feet visibility for full body
- eye line placement for portrait-oriented templates
- subject size relative to frame
- shoulder balance / body symmetry
- pitch / tilt guidance
- lower-angle recommendation for height-enhancing shots
- crop safety for IG formats
- confidence smoothing over time

### Data-Driven Configuration

The following must be defined by config rather than hardcoded UI branches:

- app identity placeholders
- `ShotTemplate`
- `CoachPersonaPack`
- `GuidanceRule`
- `CropMask`

### Local History

Store saved-photo references plus lightweight per-shot metadata only:

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

Do not store raw frame-by-frame analysis or duplicate full-size image data unnecessarily.

## Technical Requirements

- Expo + React Native + TypeScript
- Expo development build, not Expo Go
- One shared codebase for iOS and Android
- On-device analysis only in the live camera loop
- Thin native wrapper or Expo Module only if frame processing requirements force it
- Analyzer/scoring layer must be swappable so heuristics can later be replaced

## Suggested Internal Modules

- `ShotTemplateRegistry`
- `FrameAnalysisEngine`
- `GuidanceRuleEngine`
- `PersonaPackRegistry`
- `LightingAnalyzer`
- `HorizonAnalyzer`
- `CropPreviewEngine`
- `CaptureOrchestrator`

## Future-Ready Architecture Requirements

Design extension points for, but do not implement:

- Selfie mode
- Group mode
- learned model replacement for heuristics

These future modes should remain behind feature flags and separate configuration branches.

## Store and Compliance Requirements

- App config, package name, bundle identifier, icon/splash placeholders, and `eas.json`
- Build commands for iOS and Android
- Submit commands for TestFlight/App Store and Google Play
- Privacy copy stating all pose/framing analysis runs on-device
- Submission checklist docs for both stores
- Screenshot/assets checklist

## Success Criteria

- Runs in iOS and Android development builds
- Provides real-time guidance for single-subject shots
- Shot templates, lighting detection, tilt, burst, and IG preview work
- Capture and local save work
- Store setup and privacy docs exist
- Selfie/group futures are represented architecturally, not implemented

## Assumptions

- The `/reference` inspiration assets are not currently present in the repo, so planning proceeds from the written requirements only
- If `/reference` is added later, perform a short design-alignment pass before Milestone 1 UI work
- v1 may use heuristic body/face landmark estimation from a local library or a thin native integration, subject to performance validation during implementation
- History will be a local session history screen backed by saved-photo references plus lightweight shot metadata, not a full gallery browser
