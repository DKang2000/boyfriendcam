# Vision Camera Pose Landmarks Plugin

A [Vision Camera](https://github.com/mrousavy/react-native-vision-camera) Frame Processor Plugin for real-time human pose detection using [MediaPipe Pose Landmarker](https://developers.google.com/mediapipe/solutions/vision/pose_landmarker). This plugin includes the ([`pose_landmarker_full.task`](https://github.com/google-ai-edge/mediapipe/blob/master/docs/solutions/pose.md)) model bundled with the package.

## Features

- 🚀 Real-time pose detection (30+ FPS on modern devices)
- 🎯 33 body landmarks with 3D coordinates (x, y, z)
- 📊 Visibility and presence scores for each landmark
- 🔄 Optimized for video streams with temporal tracking
- 📱 Works on both Android and iOS devices

## Platform Compatibility

| Android Device | Android Emulator | iOS Device | iOS Simulator | Web |
| -------------- | ---------------- | ---------- | ------------- | --- |
| ✅             | ✅               | ✅         | ❌            | ❌  |

## Installation

```sh
npm install vision-camera-pose-landmarks-plugin
# or
yarn add vision-camera-pose-landmarks-plugin
# or
pnpm add vision-camera-pose-landmarks-plugin
```

## Usage

### Basic Example

```tsx
import { usePoseLandmarksPlugin } from 'vision-camera-pose-landmarks-plugin';
import { useFrameProcessor } from 'react-native-vision-camera';

function App() {
  const { detectPoseLandmarks } = usePoseLandmarksPlugin();

  const frameProcessor = useFrameProcessor((frame) => {
    'worklet';
    const landmarks = detectPoseLandmarks(frame);

    // Access specific landmarks
    if (landmarks.nose) {
      console.log('Nose position:', landmarks.nose);
    }
  }, []);

  return <Camera device={device} isActive frameProcessor={frameProcessor} />;
}
```

## Credits

- Built with [MediaPipe](https://developers.google.com/mediapipe)
- Powered by [Vision Camera](https://github.com/mrousavy/react-native-vision-camera)
