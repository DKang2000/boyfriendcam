import type { Landmark, LandmarkName, Landmarks } from 'vision-camera-pose-landmarks-plugin';

export type PoseLandmarks = Partial<Landmarks>;

export const POSE_CONNECTIONS: readonly [LandmarkName, LandmarkName][] = [
  ['leftEyeInner', 'leftEye'],
  ['leftEye', 'leftEyeOuter'],
  ['leftEyeOuter', 'leftEar'],
  ['rightEyeInner', 'rightEye'],
  ['rightEye', 'rightEyeOuter'],
  ['rightEyeOuter', 'rightEar'],
  ['nose', 'leftEyeInner'],
  ['nose', 'rightEyeInner'],
  ['leftMouth', 'rightMouth'],
  ['leftShoulder', 'rightShoulder'],
  ['leftShoulder', 'leftElbow'],
  ['leftElbow', 'leftWrist'],
  ['leftWrist', 'leftThumb'],
  ['leftWrist', 'leftPinky'],
  ['leftWrist', 'leftIndex'],
  ['leftPinky', 'leftIndex'],
  ['rightShoulder', 'rightElbow'],
  ['rightElbow', 'rightWrist'],
  ['rightWrist', 'rightThumb'],
  ['rightWrist', 'rightPinky'],
  ['rightWrist', 'rightIndex'],
  ['rightPinky', 'rightIndex'],
  ['leftShoulder', 'leftHip'],
  ['rightShoulder', 'rightHip'],
  ['leftHip', 'rightHip'],
  ['leftHip', 'leftKnee'],
  ['leftKnee', 'leftAnkle'],
  ['leftAnkle', 'leftHeel'],
  ['leftHeel', 'leftFootIndex'],
  ['leftAnkle', 'leftFootIndex'],
  ['rightHip', 'rightKnee'],
  ['rightKnee', 'rightAnkle'],
  ['rightAnkle', 'rightHeel'],
  ['rightHeel', 'rightFootIndex'],
  ['rightAnkle', 'rightFootIndex'],
] as const;

export const LANDMARK_PRESENCE_THRESHOLD = 0.2;

export function countVisibleLandmarks(landmarks: PoseLandmarks) {
  return Object.keys(landmarks).length;
}

export function landmarkEntries(landmarks: PoseLandmarks) {
  return Object.entries(landmarks) as [LandmarkName, Landmark][];
}
