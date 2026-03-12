# AGENTS.md

Project: BoyfriendCam (working title; keep branding swappable)

Goal
Build a cross-platform mobile app that coaches the photographer in real time so the subject gets flattering, aesthetic photos.

Core UX
- Live camera preview
- Ghost silhouette / framing template
- Crosshair or rule-of-thirds guides
- Short coaching prompt bar
- Optional spoken prompts
- Green ready state when the framing is good
- Shutter / burst capture
- Instagram crop preview before or after capture

MVP features
- Shot types:
  - full_body
  - half_body
  - portrait
  - outfit
  - instagram_story
  - rule_of_thirds
- Real-time coaching:
  - move back slightly
  - tilt phone down
  - center subject
  - zoom out a bit
  - similar short prompts
- Coach personas:
  - nice
  - sassy
  - mean
  - persona packs only; no user-trained voice model in v1
- Lighting detection:
  - backlit
  - low_light
  - harsh_overhead
- Horizon / tilt indicator
- Burst shutter:
  - 3
  - 5
  - 10
- IG crop previews:
  - 1:1
  - 4:5
  - 9:16
- Local save and session history

Roadmap only (do not implement in v1)
- Selfie mode:
  - front_facing
  - side_profile
  - three_quarter
  - keep lighting + burst
  - remove horizon module
- Group mode:
  - multi-person framing
  - group lighting
  - optional landmark/object inclusion like statue or monument

Technical rules
- One shared codebase for iOS and Android
- Expo + React Native + TypeScript
- Expo development build, not Expo Go
- VisionCamera for preview, capture, and frame processing
- On-device pose/framing analysis only
- No cloud inference in the live camera loop
- No backend in v1
- No broad photo-library permissions unless explicitly needed for save/import flows
- Support upside-down shooting
- Always show text prompts on screen even when voice mode is enabled
- Keep original UI, branding, silhouettes, and copy; do not clone the reference app exactly

Architecture rules
- Make shot types data-driven
- Make coach personas data-driven
- Separate modules:
  - ShotTemplateRegistry
  - FrameAnalysisEngine
  - GuidanceRuleEngine
  - PersonaPackRegistry
  - LightingAnalyzer
  - HorizonAnalyzer
  - CropPreviewEngine
  - CaptureOrchestrator
- Keep future modes behind feature flags
- Make the scoring/analyzer layer swappable so heuristics can later be replaced by a learned model

Workflow
- Always start in /plan
- Ask at most 5 clarifying questions
- Write PRD.md, PLANS.md, TASKS.md, and VIBECODE_LOG.md before implementation
- Create a PROMPTS/ folder and save the main Codex prompts there to document the vibecoded workflow
- Implement milestone by milestone
- After each milestone run lint/tests and summarize:
  - files changed
  - commands run
  - open risks
- Stop after each milestone for review

Definition of done for MVP
- Camera preview works on iOS and Android dev builds
- Live framing score updates in real time
- Guidance prompts are visible and debounced
- Voice guidance is optional
- Lighting and tilt checks work
- Burst mode works
- IG preview masks work
- Capture and local save work
- History screen works
- EAS build and submit config exists
- Store/privacy checklist exists