# Native iOS Rewrite Instructions

## Mission

- Build the shipping app in this repository as a native iPhone app.
- Use Swift + SwiftUI for product UI and app shell.
- Use Apple frameworks for the hot path:
  - `AVFoundation` for preview, frame delivery, and still capture
  - `Vision` for human body pose
  - `CoreMotion` for level / tilt / upside-down normalization
  - `PhotoKit` only when the user explicitly saves or exports

## Hard Rules

- Do not put React Native, Expo, or JavaScript in the shipping iOS production path.
- Do not line-by-line port React code into Swift.
- Do not reintroduce React Native, Expo, or JavaScript into the shipping app path.
- Do not broaden scope beyond parity for the current shipped product behavior.
- Do not add Android work in this migration pass.
- Do not add third-party dependencies unless the plan/doc update explicitly justifies:
  - why Apple APIs are insufficient
  - the performance tradeoff
  - the maintenance cost
  - the exact surface area

## Source Of Truth Priority

1. `reference/*` for live camera hierarchy, prompt feel, overlay weight, and upside-down ergonomics
2. Legacy React Native implementation in git history or archived references for behavior, feature scope, tuning baselines, and copy
3. `Plan.md`, `Documentation.md`, `MigrationParity.md`, `TASKS.md`, `VIBECODE_LOG.md`, and `docs/manual-qa/*` for milestone intent, QA edges, and deferred issues

## Product Priorities

- iPhone performance first
- Premium iOS-native feel over framework parity
- Pixel-perfect camera-first layout
- Smooth live preview and responsive capture
- Upside-down portrait support must feel intentional, not tolerated
- Review/history must support the camera surface instead of competing with it

## Architecture Expectations

- Keep camera/session code out of SwiftUI view bodies.
- Keep frame processing, scoring, and persistence in explicit services or pure Swift modules.
- Prefer actors, dedicated queues, and structured concurrency for correctness and responsiveness.
- Minimize allocations and image copies in the live loop.
- Make shot templates, prompt copy, and persona phrasing data-driven.
- Treat the React Native app as a behavior reference, not an architecture template.

## Preferred Module Shape

- `App/`
- `AppCore/`
- `Features/Camera/`
- `Features/Coaching/`
- `Features/History/`
- `Features/Review/`
- `Features/Settings/`
- `Services/Camera/`
- `Services/Pose/`
- `Services/Motion/`
- `Services/Persistence/`
- `DesignSystem/`
- `Testing/`
- `Docs/`

## Milestone Workflow

- Work milestone by milestone.
- Stop after each milestone for review before starting the next one.
- Do not collapse multiple milestones into one “rewrite” PR.
- Keep parity gaps and intentional native differences documented in `MigrationParity.md`.

## Validation Expectations

- Every milestone must end with:
  - successful build
  - automated tests for the touched pure-Swift logic
  - updated parity notes
  - updated manual QA expectations where behavior changed
- Canonical validation commands once the native target exists:
  - `xcodebuild -project BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16' build`
  - `xcodebuild test -project BoyfriendCamNative.xcodeproj -scheme BoyfriendCamNative -destination 'platform=iOS Simulator,name=iPhone 16'`

## Review Gate Before Advancing A Milestone

- The milestone acceptance criteria in `Plan.md` are satisfied.
- No known main-thread work remains in the camera hot path.
- Instrumentation exists for any new hot-path stage introduced in that milestone.
- Manual hardware QA has been run for upright portrait and upside-down portrait if camera behavior changed.
- Any native behavior differences from React Native are documented and justified.

## Design Review Bar

- The live camera surface must stay visually dominant.
- The yellow prompt pill must remain the most prominent guidance element until ready-state turns green.
- Overlay lines should stay thin, elegant, and readable over varied lighting.
- Bottom controls should feel integrated into the preview rather than bolted underneath it.
- History/review should feel calmer and lighter than the live guidance surface.
