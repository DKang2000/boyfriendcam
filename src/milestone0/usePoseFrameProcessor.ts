import { useRunOnJS } from 'react-native-worklets-core';
import {
  runAsync,
  runAtTargetFps,
  type Orientation,
  useFrameProcessor,
} from 'react-native-vision-camera';
import { usePoseLandmarksPlugin, type Landmarks } from 'vision-camera-pose-landmarks-plugin';

import { LANDMARK_PRESENCE_THRESHOLD, type PoseLandmarks } from './pose';

type PoseTelemetry = {
  orientation: Orientation;
  poseCount: number;
  timestampMs: number;
};

type PoseFrameCallback = (landmarks: PoseLandmarks, telemetry: PoseTelemetry) => void;

const FRAME_PROCESSOR_FPS = 10;

export function usePoseFrameProcessor(onPoseFrame: PoseFrameCallback) {
  const { detectPoseLandmarks } = usePoseLandmarksPlugin({
    numPoses: 1,
    minPoseDetectionConfidence: 0.55,
    minPosePresenceConfidence: 0.55,
    minTrackingConfidence: 0.55,
  });
  const reportPoseFrame = useRunOnJS(onPoseFrame, [onPoseFrame]);

  const frameProcessor = useFrameProcessor(
    (frame) => {
      'worklet';

      runAtTargetFps(FRAME_PROCESSOR_FPS, () => {
        'worklet';

        runAsync(frame, () => {
          'worklet';

          const poses = detectPoseLandmarks(frame);
          const primaryPose = poses[0];
          const landmarks = normalizePoseForPreview(primaryPose, frame.orientation);

          reportPoseFrame(landmarks, {
            orientation: frame.orientation,
            poseCount: poses.length,
            timestampMs: Number(frame.timestamp),
          });
        });
      });
    },
    [detectPoseLandmarks, reportPoseFrame]
  );

  return { frameProcessor, frameProcessorFps: FRAME_PROCESSOR_FPS };
}

function normalizePoseForPreview(
  pose: PoseLandmarks | undefined,
  orientation: Orientation
): PoseLandmarks {
  'worklet';

  if (pose == null) {
    return {};
  }

  const normalized: PoseLandmarks = {};

  for (const landmarkName in pose) {
    const typedLandmarkName = landmarkName as keyof Landmarks;
    const landmark = pose[typedLandmarkName];

    if (landmark == null || landmark.presence < LANDMARK_PRESENCE_THRESHOLD) {
      continue;
    }

    let nextX = landmark.x;
    let nextY = landmark.y;

    switch (orientation) {
      case 'landscape-right':
        nextX = 1 - landmark.y;
        nextY = landmark.x;
        break;
      case 'landscape-left':
        nextX = landmark.y;
        nextY = 1 - landmark.x;
        break;
      case 'portrait-upside-down':
        nextX = 1 - landmark.x;
        nextY = 1 - landmark.y;
        break;
      case 'portrait':
      default:
        break;
    }

    normalized[typedLandmarkName] = {
      ...landmark,
      x: nextX,
      y: nextY,
    };
  }

  return normalized;
}
