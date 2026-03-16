# Native iOS Rewrite Planning Prompt

## Prompt Source

- Source: user request from the planning thread on 2026-03-14.
- This file captures the exact working prompt used for the planning pass after normalizing the request into an execution brief.

## Exact Working Prompt

```text
Inspect the existing BoyfriendCam repository first, with special attention to reference assets, milestone docs, QA docs, shot templates, overlay/template files, scoring/guidance/persona logic, lighting/orientation logic, burst/crop/history/persistence logic, and package/project docs. Treat the current React Native / Expo implementation as the product behavior spec, but not as the shipping runtime or architecture.

Plan a new native iOS rewrite under ios-native/ only. The shipping stack must be Swift + SwiftUI, AVFoundation, Vision human body pose, Core Motion, and PhotoKit only for explicit user save/export. Do not keep React Native, Expo, or JavaScript in the shipping path. Do not do a one-shot rewrite, do not create a hybrid path, and do not broaden scope beyond parity with the current RN app.

Use source-of-truth priority in this order:
1. reference/* for live camera visual hierarchy and live camera feel
2. the current RN implementation for product behavior and shipped feature scope
3. milestone docs, QA docs, and VIBECODE_LOG for requirements and edge cases

Create planning deliverables only:
- ios-native/AGENTS.md
- ios-native/Prompt.md
- ios-native/Plan.md
- ios-native/Documentation.md
- ios-native/MigrationParity.md

Also update:
- VIBECODE_LOG.md with a clearly labeled Native iOS rewrite planning section
- TASKS.md with a separate native rewrite section

The plan must preserve current feature parity targets for live preview, shot templates, ghost overlays, real-time score, prompt pill, persona phrasing, ready-state behavior, lighting detection, level/tilt guidance, burst capture, crop previews, local history/detail flows, and explicit save/export. Prefer Apple-native modules, keep the hot path off the main thread, use typed models and data-driven configs, and include signpost-based instrumentation plus xcodebuild-based validation and hardware QA checkpoints. Include a dedicated later visual-alignment pass against:
- reference/step-back.png
- reference/tilt-up.png
- reference/flip-upside-down.png
- reference/upright-overlay.png
- reference/upside-down-ui.png

Stop after the planning pass only. Do not create the Xcode target yet. Do not start implementation yet.
```

## Key Assumptions

- iPhone-first release
- portrait-first UX for v1
- portrait-upside-down support is required
- no iPad optimization in the first native release
- no cloud dependency in the live camera loop
- no broad photo-library permission on launch
- save/export permission is requested only on explicit user action
- no third-party runtime dependencies are currently planned for the native rewrite

## Key Constraints

- Preserve product behavior before improving polish
- Preserve the React Native app as the behavior and QA reference
- Rebuild architecture natively instead of transliterating JS/TS
- Keep the camera/session hot path isolated from SwiftUI state churn
- Do not add scope outside the current Milestones 0 through 3B feature set plus existing reference-alignment intent

## Open Questions

- Minimum iOS deployment target is not yet documented; planning assumes a modern iPhone baseline and avoids SwiftData-specific lock-in.
- Exact acceptable warm-start camera startup time and burst cadence still need on-device tuning during implementation.
- The current RN app uses MediaPipe-based pose landmarks plus compact lighting summaries; the native rewrite plans to use Vision pose and native luminance summaries, so some thresholds will need retuning on hardware.

## Explicitly Out Of Scope

- Android migration work
- backend, accounts, social, or monetization systems
- learned model replacement for the heuristic coaching stack
- iPad-specific layout work
- general photo editor workflows
- broad library sync or gallery management
- implementation code for the native target during this planning pass
