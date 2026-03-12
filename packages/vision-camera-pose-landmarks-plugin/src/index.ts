import { useMemo } from 'react';
import { type Frame, VisionCameraProxy } from 'react-native-vision-camera';

/** Get a new instance of the pose landmarks plugin. */
export function createPoseLandmarksPlugin(options: PluginOptions = {}) {
  const poseLandmarksPlugin = VisionCameraProxy.initFrameProcessorPlugin(
    'detectPoseLandmarks',
    options
  );

  if (poseLandmarksPlugin == null)
    throw new Error(
      'Cannot find vision-camera-pose-landmarks-plugin! Did you install the native dependency properly?'
    );

  return {
    /**
     * Detects human pose landmarks in a camera frame.
     *
     * @example
     * ```ts
     * const frameProcessor = useFrameProcessor((frame) => {
     *   'worklet';
     *   const landmarks = detectPoseLandmarks(frame);
     *   // Process landmarks...
     * }, []);
     * ```
     */
    detectPoseLandmarks: (frame: Frame): Poses => {
      'worklet';
      return (poseLandmarksPlugin.call(frame) as unknown as Poses) ?? [];
    },
  };
}

/** Use an instance of the pose landmarks plugin. */
export function usePoseLandmarksPlugin(options: PluginOptions = {}) {
  return useMemo(() => createPoseLandmarksPlugin(options), [options]);
}

type PluginOptions = {
  numPoses?: number;
  /**
   * Value between 0.0 and 1.0
   *
   * @default 0.5
   * */
  minTrackingConfidence?: number;
  /**
   * Value between 0.0 and 1.0
   *
   * @default 0.5
   * */
  minPosePresenceConfidence?: number;
  /**
   * Value between 0.0 and 1.0
   *
   * @default 0.5
   * */
  minPoseDetectionConfidence?: number;
};

type Poses = Landmarks[];

export type Landmarks = {
  nose: Landmark;
  leftEyeInner: Landmark;
  leftEye: Landmark;
  leftEyeOuter: Landmark;
  rightEyeInner: Landmark;
  rightEye: Landmark;
  rightEyeOuter: Landmark;
  leftEar: Landmark;
  rightEar: Landmark;
  leftMouth: Landmark;
  rightMouth: Landmark;
  leftShoulder: Landmark;
  rightShoulder: Landmark;
  leftElbow: Landmark;
  rightElbow: Landmark;
  leftWrist: Landmark;
  rightWrist: Landmark;
  leftPinky: Landmark;
  rightPinky: Landmark;
  leftIndex: Landmark;
  rightIndex: Landmark;
  leftThumb: Landmark;
  rightThumb: Landmark;
  leftHip: Landmark;
  rightHip: Landmark;
  leftKnee: Landmark;
  rightKnee: Landmark;
  leftAnkle: Landmark;
  rightAnkle: Landmark;
  leftHeel: Landmark;
  rightHeel: Landmark;
  leftFootIndex: Landmark;
  rightFootIndex: Landmark;
  unknown: Landmark;
};

export type Landmark = {
  x: NormalizedCoordinate;
  y: NormalizedCoordinate;
  z: NormalizedCoordinate;
  visibility: number;
  presence: number;
};

/** Normalized coordinate value in the range of [0, 1]. */
type NormalizedCoordinate = number;

export type LandmarkName = keyof Landmarks;
