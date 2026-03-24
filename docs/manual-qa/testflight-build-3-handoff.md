# BoyfriendCam TestFlight Build 3 Handoff

Date: March 24, 2026
Repo: `/Users/donghokang/Documents/New project 4/boyfriendcam-main`
App Store Connect app: `BoyfriendCam`
App ID: `6760730849`
GitHub repo: `DKang2000/boyfriendcam`

## Why this handoff exists

This note is for a future Codex thread that needs full context on the current TestFlight build and the live silhouette overlay issue. There was a false start where a previous fix was shipped, but the overlay still looked fake on-device. Build 3 is the follow-up fix that should address the real problem.

## High-level project state

- The active app is the native iOS SwiftUI app in this repo.
- The older React Native / Expo implementation is not the shipping runtime.
- The app has camera preview, coach mode, template mode, pose detection, motion guidance, history, and review/export flows.
- The core bug being worked was the live subject silhouette overlay not truly following the photographed person.

## What went wrong before build 3

The first attempt at the overlay fix was committed and shipped, but it did not fully solve the user-visible problem.

The earlier implementation improved some pose handling, but the production render path still had two major issues:

1. Pose data was still being collapsed too aggressively before rendering.
2. The overlay renderer still rebuilt a softened mannequin-like body from torso spans and inferred limb geometry rather than directly honoring actual observed joint chains.

That meant:

- arm movement often still looked generic rather than truly tracked
- lower-body partial poses still looked fake
- torso width and shear still felt stock/mannequin-like
- the user tested the uploaded version and reported that the silhouette still did not conform to the photographed person

## Root cause of the real bug

The real root cause was not that pose detection failed. Real landmarks already existed and could be seen in the debug overlay.

The real bug was that the production overlay path was not using those real landmarks faithfully enough.

More specifically:

- `AppCore/Models/PoseFrame.swift` still produced `PoseBodyDescriptor` with lots of inferred geometry.
- `Features/Camera/ShotTemplateOverlayView.swift` still rendered a body using generic torso shaping and inferred limbs.
- `Features/Camera/CameraScreen.swift` coach overlay used the same rendering path.
- Partial pose support in scoring had been improved already, but rendering still looked fake because the renderer itself was still mannequin-driven.

## What changed in build 3

Build 3 introduces a separate render descriptor that preserves actual observed joints for rendering while still keeping smoothing and graceful partial-pose behavior.

### Main code changes

- Added `PoseTrackedJoint` and `PoseRenderDescriptor` in `AppCore/Models/PoseFrame.swift`
- Added:
  - `renderDescriptor(for:)`
  - `coachRenderDescriptor()`
  - tracked-joint extraction for observed elbows, wrists, knees, and ankles
- Rewired template overlay to use `PoseRenderDescriptor`
- Rewired coach overlay to use the same `PoseRenderDescriptor`
- Kept fallback placeholder behavior only for truly absent pose
- Kept smoothing by blending render descriptors frame to frame
- Updated the debug overlay mode label to reflect the real render path
- Added export-compliance key to `App/Info.plist`
- Bumped build number from `2` to `3`

### Behavior that should now be true

- Moving arms should change overlay arms.
- Changing knee / ankle placement should change overlay legs.
- Torso rotation / shear should affect overlay torso shape more naturally.
- Partial pose should still yield an adaptive overlay.
- Full-body readiness should still remain false until lower-body landmarks actually exist.
- Coach mode and template mode should both use the same real adaptive silhouette renderer.

## Files changed for the build 3 fix

- `App/Info.plist`
- `AppCore/Models/PoseFrame.swift`
- `BoyfriendCamNative.xcodeproj/project.pbxproj`
- `Features/Camera/CameraScreen.swift`
- `Features/Camera/CameraShellViewModel.swift`
- `Features/Camera/ShotTemplateOverlayView.swift`
- `Testing/Unit/PoseFrameFocusTests.swift`

## Important commits

- `89ab5f6` `Fix live pose overlay and checkpoint repo changes`
  - earlier attempt that was not sufficient on-device
- `ca1408b` `Bump iOS build number and upload TestFlight build 2`
  - shipped build 2
- `d0a286f` `Fix landmark-driven live silhouette overlay`
  - real follow-up fix after user reported build 2 still looked fake
- `3bca414` `Archive TestFlight build 3`
  - archived TestFlight build 3 artifacts in repo

## Test coverage added or verified

Targeted and full unit test runs passed locally.

Important test intent added in `Testing/Unit/PoseFrameFocusTests.swift`:

- changing elbow / wrist / knee / ankle landmarks changes rendered silhouette geometry
- partial pose still yields adaptive render data
- fallback only occurs when pose is absent
- full-body flows can remain not-ready without lower-body landmarks while still tracking visible pose

Latest known local verification:

- full unit test target passed: `39 tests, 0 failures`
- Release build passed
- archive succeeded for build 3
- upload to App Store Connect succeeded

## TestFlight / App Store Connect status

Build 3 was uploaded on March 24, 2026.

Known details:

- version/build: `1.0 (3)`
- upload completed successfully
- archive `Info.plist` confirmed `CFBundleVersion = 3`
- App Store Connect TestFlight iOS page showed build upload `1.0 (3)` as `Complete`
- the TestFlight page showed build `3` under version `1.0`
- the sidebar showed the internal testing group `cholegang`
- the build list showed a `CH` group badge and `2` invites for build `3`

At the time of verification, the TestFlight table displayed build 3 as `Ready to Submit`. If a future thread is checking whether testers can install it, verify the current internal-testing state in App Store Connect first because Apple status can change after processing.

## Known uncertainty

There is still an important distinction between:

- code correctness and local tests
- actual on-device UX in TestFlight

This build was strongly verified through code inspection, unit tests, release build, archive, upload, and App Store Connect presence. However, there was no direct physical-device revalidation from within Codex after upload. If the user reports that build 3 still feels wrong, assume the report is credible and inspect the real camera runtime path again rather than assuming the tests are sufficient.

## First things a future thread should check if the overlay is still wrong

1. Confirm the tester is actually on build `1.0 (3)` or later in TestFlight.
2. Turn on the debug overlay in-app and inspect:
   - `Overlay: adaptive` vs `fallback`
   - visible landmark count
3. Confirm `PoseDebugOverlayView` shows real landmarks moving while the rendered silhouette does or does not follow.
4. Compare coach mode and template mode side by side to make sure neither drifted.
5. Inspect whether wrists / knees / ankles are actually present in the live `PoseFrame` being generated on-device.
6. If landmarks are present but silhouette still looks generic, inspect `LivePoseOverlayRenderer` first.
7. If landmarks are missing in live capture but visible in debug inconsistently, inspect `PoseFrameMapper` / pose confidence thresholds / camera orientation handling.
8. If TestFlight behavior differs from local simulator behavior, verify no stale build or stale App Store Connect state is involved.

## Most relevant source files for future debugging

- `AppCore/Models/PoseFrame.swift`
- `Features/Camera/ShotTemplateOverlayView.swift`
- `Features/Camera/CameraScreen.swift`
- `Features/Camera/CameraShellViewModel.swift`
- `Features/Camera/PoseDebugOverlayView.swift`
- `Services/Pose/PoseFrameMapper.swift`
- `Services/Pose/PoseDetectionService.swift`
- `Services/Coaching/FrameScoringEngine.swift`
- `Services/Coaching/CoachingPipeline.swift`

## Practical summary for the next Codex thread

If a user says "the silhouette still looks fake," do not start from the assumption that the previous fix worked. The history here is that build 2 was shipped with an incomplete fix, the user tested it, and reported that it still failed. Build 3 is the more complete follow-up that moves both coach mode and template mode onto a shared landmark-driven render path. The next debugging pass should verify the live on-device `PoseFrame` joint availability, the debug overlay mode, and whether `LivePoseOverlayRenderer` is still producing a silhouette that visually over-smooths or genericizes the subject.
