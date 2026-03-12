import type { ShotTemplate } from '../config/shotTemplates';
import type { PoseLandmarks } from '../milestone0/pose';

export type EmulatorQaScenario = 'no_subject' | 'off_target' | 'ready_pose';

export const EMULATOR_QA_SCENARIOS: readonly {
  id: EmulatorQaScenario;
  label: string;
  summary: string;
}[] = [
  {
    id: 'no_subject',
    label: 'No subject',
    summary: 'Validates empty-state copy and ready fallback.',
  },
  {
    id: 'off_target',
    label: 'Off target',
    summary: 'Shows a visible subject with low framing alignment.',
  },
  {
    id: 'ready_pose',
    label: 'Ready pose',
    summary: 'Places the simulated subject inside the selected template.',
  },
] as const;

type PoseLayout = {
  centerX: number;
  centerY: number;
  height: number;
  shoulderHalf: number;
  hipHalf: number;
};

export function buildEmulatorPose(
  template: ShotTemplate,
  scenario: EmulatorQaScenario
): PoseLandmarks {
  if (scenario === 'no_subject') {
    return {};
  }

  const targetCenterX = template.overlay.targetBox.x + template.overlay.targetBox.width / 2;
  const targetCenterY = template.overlay.targetBox.y + template.overlay.targetBox.height / 2;
  const baseHeight = template.overlay.targetBox.height;
  const layout: PoseLayout =
    scenario === 'ready_pose'
      ? {
          centerX: targetCenterX,
          centerY: targetCenterY,
          height: baseHeight,
          shoulderHalf: template.overlay.targetBox.width * 0.16,
          hipHalf: template.overlay.targetBox.width * 0.12,
        }
      : {
          centerX: clamp01(targetCenterX + 0.18),
          centerY: clamp01(targetCenterY + 0.1),
          height: baseHeight * 0.72,
          shoulderHalf: template.overlay.targetBox.width * 0.13,
          hipHalf: template.overlay.targetBox.width * 0.1,
        };

  const topY = layout.centerY - layout.height / 2;
  const bottomY = layout.centerY + layout.height / 2;
  const headCenterY = topY + layout.height * 0.11;
  const shoulderY = topY + layout.height * 0.24;
  const elbowY = topY + layout.height * 0.38;
  const wristY = topY + layout.height * 0.5;
  const hipY = topY + layout.height * 0.52;
  const kneeY = topY + layout.height * 0.74;
  const ankleY = topY + layout.height * 0.94;
  const heelY = bottomY;
  const footY = clamp01(bottomY + layout.height * 0.02);
  const mouthOffsetX = layout.shoulderHalf * 0.1;
  const eyeOffsetX = layout.shoulderHalf * 0.2;
  const eyeOffsetY = layout.height * 0.015;
  const earOffsetX = layout.shoulderHalf * 0.34;
  const shoulderYMid = shoulderY;
  const leftShoulderX = layout.centerX - layout.shoulderHalf;
  const rightShoulderX = layout.centerX + layout.shoulderHalf;
  const leftElbowX = layout.centerX - layout.shoulderHalf * 1.34;
  const rightElbowX = layout.centerX + layout.shoulderHalf * 1.34;
  const leftWristX = layout.centerX - layout.shoulderHalf * 1.7;
  const rightWristX = layout.centerX + layout.shoulderHalf * 1.7;
  const leftHipX = layout.centerX - layout.hipHalf;
  const rightHipX = layout.centerX + layout.hipHalf;
  const leftKneeX = layout.centerX - layout.hipHalf * 0.92;
  const rightKneeX = layout.centerX + layout.hipHalf * 0.92;
  const leftAnkleX = layout.centerX - layout.hipHalf * 0.86;
  const rightAnkleX = layout.centerX + layout.hipHalf * 0.86;
  const leftFootX = leftAnkleX - layout.hipHalf * 0.22;
  const rightFootX = rightAnkleX + layout.hipHalf * 0.22;

  return {
    nose: point(layout.centerX, headCenterY),
    leftEyeInner: point(layout.centerX - eyeOffsetX * 0.55, headCenterY - eyeOffsetY),
    leftEye: point(layout.centerX - eyeOffsetX, headCenterY - eyeOffsetY),
    leftEyeOuter: point(layout.centerX - eyeOffsetX * 1.35, headCenterY - eyeOffsetY * 0.9),
    rightEyeInner: point(layout.centerX + eyeOffsetX * 0.55, headCenterY - eyeOffsetY),
    rightEye: point(layout.centerX + eyeOffsetX, headCenterY - eyeOffsetY),
    rightEyeOuter: point(layout.centerX + eyeOffsetX * 1.35, headCenterY - eyeOffsetY * 0.9),
    leftEar: point(layout.centerX - earOffsetX, headCenterY),
    rightEar: point(layout.centerX + earOffsetX, headCenterY),
    leftMouth: point(layout.centerX - mouthOffsetX, headCenterY + layout.height * 0.04),
    rightMouth: point(layout.centerX + mouthOffsetX, headCenterY + layout.height * 0.04),
    leftShoulder: point(leftShoulderX, shoulderYMid),
    rightShoulder: point(rightShoulderX, shoulderYMid),
    leftElbow: point(leftElbowX, elbowY),
    rightElbow: point(rightElbowX, elbowY),
    leftWrist: point(leftWristX, wristY),
    rightWrist: point(rightWristX, wristY),
    leftPinky: point(leftWristX - layout.shoulderHalf * 0.08, wristY + layout.height * 0.015),
    rightPinky: point(rightWristX + layout.shoulderHalf * 0.08, wristY + layout.height * 0.015),
    leftIndex: point(leftWristX + layout.shoulderHalf * 0.03, wristY - layout.height * 0.01),
    rightIndex: point(rightWristX - layout.shoulderHalf * 0.03, wristY - layout.height * 0.01),
    leftThumb: point(leftWristX + layout.shoulderHalf * 0.08, wristY + layout.height * 0.01),
    rightThumb: point(rightWristX - layout.shoulderHalf * 0.08, wristY + layout.height * 0.01),
    leftHip: point(leftHipX, hipY),
    rightHip: point(rightHipX, hipY),
    leftKnee: point(leftKneeX, kneeY),
    rightKnee: point(rightKneeX, kneeY),
    leftAnkle: point(leftAnkleX, ankleY),
    rightAnkle: point(rightAnkleX, ankleY),
    leftHeel: point(leftAnkleX, heelY),
    rightHeel: point(rightAnkleX, heelY),
    leftFootIndex: point(leftFootX, footY),
    rightFootIndex: point(rightFootX, footY),
  };
}

function point(x: number, y: number) {
  return {
    x: clamp01(x),
    y: clamp01(y),
    z: 0,
    visibility: 0.98,
    presence: 0.98,
  };
}

function clamp01(value: number) {
  return Math.max(0.02, Math.min(0.98, value));
}
