# iOS Native 1.0.0-rc1 Manual QA Checklist

Use this checklist on real iPhones only.

Do not treat simulator results as release signoff for `1.0.0-rc1`.

## Test Metadata

- Build identifier:
- Device model:
- iOS version:
- Tester:
- Date:
- Native app commit / branch:

## Device Matrix

- Primary device:
  - Recommended: recent iPhone Pro or base model on current iOS
- Secondary device:
  - Recommended: older supported iPhone to catch preview/perf regressions

## Preflight

- Install the current native app build on the physical device.
- Confirm the build launches without Xcode debugger attached at least once.
- Confirm the app has camera permission available for the main test run.
- Confirm Photos permission is not pre-granted if you want to validate export prompts.
- Make sure at least one test environment supports:
  - normal indoor lighting
  - low light
  - strong backlight

## 1. Cold Launch

- [ ] Fresh cold launch reaches the camera shell without crash.
- [ ] First launch feels responsive and does not stall on a black screen.
- [ ] Camera permission prompt appears when expected on a fresh permission state.
- [ ] Granting permission transitions into live preview successfully.
- [ ] Denying permission keeps the app stable and shows a recoverable gate.
- [ ] Opening Settings from the denied state works.
- [ ] Returning from Settings after granting permission resumes correctly.

Notes:

## 2. Upright Portrait Camera Flow

- [ ] Live preview becomes visible quickly and stays stable.
- [ ] Prompt pill placement feels balanced and not too heavy.
- [ ] Prompt text remains readable over the preview.
- [ ] Silhouette and crosshair stay aligned with the subject.
- [ ] Overlay weight feels subtle rather than distracting.
- [ ] Level guide updates while moving the phone.
- [ ] Capture button feels centered and easy to hit.
- [ ] History/review affordances feel secondary to the camera surface.
- [ ] Changing shot templates updates the overlay immediately.
- [ ] Changing persona updates phrasing without layout glitches.

Notes:

## 3. Upside-Down Portrait

- [ ] Rotate into portrait-upside-down and confirm preview remains correct.
- [ ] Overlay remains aligned after rotation.
- [ ] Prompt pill still feels intentionally placed upside-down.
- [ ] Capture controls remain reachable and sensible when inverted.
- [ ] Level / tilt prompts still make directional sense upside-down.
- [ ] Taking a photo upside-down succeeds.
- [ ] Review of an upside-down capture opens normally.

Notes:

## 4. Long Camera Session Stability

- [ ] Leave the camera screen open for 5 minutes in upright portrait.
- [ ] Leave the camera screen open for 5 minutes with intermittent upside-down rotation.
- [ ] Preview does not freeze, hitch badly, or go black.
- [ ] Prompt updates do not start lagging over time.
- [ ] Phone does not become unreasonably hot during normal use.
- [ ] Backgrounding and returning to the app restores preview correctly.

Notes:

## 5. Lighting Checks

### Low Light

- [ ] In a dim scene, the app surfaces a low-light style warning when appropriate.
- [ ] Prompting remains stable and does not flicker rapidly.
- [ ] Preview remains usable and capture still works.

### Backlight

- [ ] In a strong backlit scene, the app surfaces a backlight-style warning when appropriate.
- [ ] The warning clears after moving to balanced lighting.
- [ ] Guidance remains readable in both conditions.

Notes:

## 6. Burst Capture

### Burst 3

- [ ] `3` shot burst completes successfully.
- [ ] Review opens with all burst frames available.
- [ ] Frame selection works after the burst.

### Burst 5

- [ ] `5` shot burst completes successfully.
- [ ] The app remains responsive during and after capture.
- [ ] No obvious dropped-state or UI corruption appears.

### Burst 10

- [ ] `10` shot burst completes successfully.
- [ ] The camera does not lock up after completion.
- [ ] Review still opens with the full frame strip.
- [ ] Device heat and responsiveness remain acceptable.

Notes:

## 7. Crop Preview Modes

- [ ] `Full` preview mask renders correctly.
- [ ] `1:1` preview mask renders correctly.
- [ ] `4:5` preview mask renders correctly.
- [ ] `9:16` preview mask renders correctly.
- [ ] Switching crop modes in the camera screen feels immediate.
- [ ] Switching crop modes in review updates the mask correctly.
- [ ] Crop selection persists when returning to the same review session.

Notes:

## 8. History And Persistence After Relaunch

- [ ] Capture at least one single-photo session.
- [ ] Capture at least one burst session.
- [ ] Confirm both appear in history.
- [ ] Fully terminate the app.
- [ ] Relaunch the app.
- [ ] Previously captured sessions still appear in history.
- [ ] Opening old sessions after relaunch works.
- [ ] Selected hero frame persists after relaunch.
- [ ] Selected crop preview persists after relaunch.
- [ ] Deleting a session from history works without corrupting the list.

Notes:

## 9. Save / Export Permission Flows

### Denied / Limited Permission Path

- [ ] Attempt `Save to Photos` with Photos access not yet granted.
- [ ] The app requests Photos access only when export is initiated.
- [ ] Denying Photos access does not crash the app.
- [ ] The app surfaces a clear failure state after denial.
- [ ] Re-trying export after denial behaves predictably.

### Granted Permission Path

- [ ] Grant Photos access from the export prompt.
- [ ] Export succeeds for a single capture.
- [ ] Export succeeds for a burst-selected hero frame.
- [ ] The saved image appears in Photos.
- [ ] Export success messaging is correct.

Notes:

## 10. Visual Polish Signoff

- [ ] Prompt pill feels clean, premium, and not oversized.
- [ ] Overlay feels thin and elegant rather than graphic-heavy.
- [ ] Camera surface remains visually primary at all times.
- [ ] Review and history screens feel supportive, not dominant.
- [ ] Upright and upside-down portrait both feel intentional.
- [ ] No obvious jank appears during prompt changes, capture, review open, or history open.

Notes:

## Release Decision

- [ ] Pass
- [ ] Pass with follow-up tickets
- [ ] Blocked for release

Blocking issues:

Follow-up tickets:
