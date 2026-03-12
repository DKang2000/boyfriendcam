# Milestone 0 Manual QA Checklist

## Setup

- Install dependencies with `npm install`
- Generate native projects with `npx expo prebuild`
- Launch Android dev build with `npm run android`
- Launch iOS dev build with `npm run ios`

## Camera Permission Flow

- Fresh install prompts for camera permission on first launch
- Denying permission keeps the app on the permission gate without crashing
- Granting permission transitions into the camera spike screen
- Relaunching after permission grant resumes directly into preview

## Preview and Frame Processor

- Live camera preview appears within 2-3 seconds on Android
- Live camera preview appears within 2-3 seconds on iOS
- Preview remains stable for at least 60 seconds without freezing or going black
- Diagnostics panel updates while the preview is active
- Landmark count changes as a person enters and leaves frame
- Debug overlay tracks major joints in real time without obvious inversion

## Pose Landmarks to JS

- At least one human subject in frame causes the overlay to render dots/lines
- Orientation label changes when the device rotates
- Landmark updates continue while moving closer/farther from the subject
- No JS-side crashes occur when the subject leaves frame

## Upside-Down Portrait

- Inverting the phone to portrait-upside-down does not crash the preview
- Landmarks stay aligned with the subject after rotation
- Single photo capture still succeeds while upside-down
- Captured photo orientation metadata is correct when inspected on-device

## Single Photo Capture

- Tapping `Take single photo` saves a photo successfully on Android
- Tapping `Take single photo` saves a photo successfully on iOS
- The latest saved file path updates in the diagnostics panel
- Repeated single captures do not break preview or landmark updates

## Failure Cases

- Camera permission denied forever is recoverable via OS settings
- Camera runtime errors are surfaced in the diagnostics panel
- Backgrounding and returning to the app does not permanently break preview
- Thermal throttling or low-memory conditions do not immediately crash the app
