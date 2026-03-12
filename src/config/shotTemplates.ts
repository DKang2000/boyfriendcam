import type { LandmarkName } from 'vision-camera-pose-landmarks-plugin';

export type ShotTemplateId =
  | 'full_body'
  | 'half_body'
  | 'portrait'
  | 'outfit'
  | 'instagram_story'
  | 'rule_of_thirds';

export type ShotTemplate = {
  id: ShotTemplateId;
  label: string;
  guideMode: 'crosshair' | 'rule-of-thirds';
  overlay: {
    targetBox: {
      x: number;
      y: number;
      width: number;
      height: number;
    };
    headRadius: number;
    shoulderWidth: number;
    hipWidth: number;
    footInset: number;
  };
  readyThreshold: number;
  scoring: {
    centerWeight: number;
    requiredWeight: number;
    coverageWeight: number;
    minVisibleLandmarks: number;
    requiredLandmarks: readonly LandmarkName[];
  };
  summary: string;
};

export const SHOT_TEMPLATES: readonly ShotTemplate[] = [
  {
    id: 'full_body',
    label: 'Full Body',
    guideMode: 'crosshair',
    overlay: {
      targetBox: { x: 0.23, y: 0.1, width: 0.54, height: 0.82 },
      headRadius: 0.085,
      shoulderWidth: 0.58,
      hipWidth: 0.42,
      footInset: 0.18,
    },
    readyThreshold: 0.78,
    scoring: {
      centerWeight: 0.4,
      requiredWeight: 0.35,
      coverageWeight: 0.25,
      minVisibleLandmarks: 16,
      requiredLandmarks: ['nose', 'leftShoulder', 'rightShoulder', 'leftAnkle', 'rightAnkle'],
    },
    summary: 'Head-to-toe framing with feet visible.',
  },
  {
    id: 'half_body',
    label: 'Half Body',
    guideMode: 'crosshair',
    overlay: {
      targetBox: { x: 0.22, y: 0.16, width: 0.56, height: 0.58 },
      headRadius: 0.1,
      shoulderWidth: 0.62,
      hipWidth: 0.46,
      footInset: 0.26,
    },
    readyThreshold: 0.72,
    scoring: {
      centerWeight: 0.42,
      requiredWeight: 0.33,
      coverageWeight: 0.25,
      minVisibleLandmarks: 12,
      requiredLandmarks: ['nose', 'leftShoulder', 'rightShoulder', 'leftHip', 'rightHip'],
    },
    summary: 'Waist-up composition with balanced shoulders.',
  },
  {
    id: 'portrait',
    label: 'Portrait',
    guideMode: 'crosshair',
    overlay: {
      targetBox: { x: 0.24, y: 0.12, width: 0.52, height: 0.46 },
      headRadius: 0.12,
      shoulderWidth: 0.66,
      hipWidth: 0.4,
      footInset: 0.3,
    },
    readyThreshold: 0.7,
    scoring: {
      centerWeight: 0.48,
      requiredWeight: 0.34,
      coverageWeight: 0.18,
      minVisibleLandmarks: 8,
      requiredLandmarks: ['nose', 'leftEye', 'rightEye', 'leftShoulder', 'rightShoulder'],
    },
    summary: 'Chest-up portrait with clean headroom.',
  },
  {
    id: 'outfit',
    label: 'Outfit',
    guideMode: 'crosshair',
    overlay: {
      targetBox: { x: 0.21, y: 0.08, width: 0.58, height: 0.84 },
      headRadius: 0.082,
      shoulderWidth: 0.62,
      hipWidth: 0.48,
      footInset: 0.16,
    },
    readyThreshold: 0.8,
    scoring: {
      centerWeight: 0.36,
      requiredWeight: 0.34,
      coverageWeight: 0.3,
      minVisibleLandmarks: 16,
      requiredLandmarks: ['nose', 'leftShoulder', 'rightShoulder', 'leftKnee', 'rightKnee'],
    },
    summary: 'Head-to-hem framing with extra space for styling.',
  },
  {
    id: 'instagram_story',
    label: 'IG Story',
    guideMode: 'rule-of-thirds',
    overlay: {
      targetBox: { x: 0.2, y: 0.06, width: 0.6, height: 0.88 },
      headRadius: 0.082,
      shoulderWidth: 0.58,
      hipWidth: 0.42,
      footInset: 0.18,
    },
    readyThreshold: 0.75,
    scoring: {
      centerWeight: 0.34,
      requiredWeight: 0.33,
      coverageWeight: 0.33,
      minVisibleLandmarks: 14,
      requiredLandmarks: ['nose', 'leftShoulder', 'rightShoulder', 'leftHip', 'rightHip'],
    },
    summary: 'Tall vertical framing with story-safe breathing room.',
  },
  {
    id: 'rule_of_thirds',
    label: 'Rule of Thirds',
    guideMode: 'rule-of-thirds',
    overlay: {
      targetBox: { x: 0.1, y: 0.14, width: 0.42, height: 0.68 },
      headRadius: 0.1,
      shoulderWidth: 0.64,
      hipWidth: 0.48,
      footInset: 0.22,
    },
    readyThreshold: 0.68,
    scoring: {
      centerWeight: 0.4,
      requiredWeight: 0.34,
      coverageWeight: 0.26,
      minVisibleLandmarks: 10,
      requiredLandmarks: ['nose', 'leftShoulder', 'rightShoulder'],
    },
    summary: 'Place the subject off-center on the thirds grid.',
  },
] as const;

export const SHOT_TEMPLATE_REGISTRY = Object.fromEntries(
  SHOT_TEMPLATES.map((template) => [template.id, template])
) as Record<ShotTemplateId, ShotTemplate>;
