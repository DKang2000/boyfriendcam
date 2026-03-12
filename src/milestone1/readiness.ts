import type { ShotTemplate } from '../config/shotTemplates';
import type { PoseLandmarks } from '../milestone0/pose';

type Bounds = {
  maxX: number;
  maxY: number;
  minX: number;
  minY: number;
};

export type ReadyScore = {
  isReady: boolean;
  score: number;
  statusLabel: string;
};

export function evaluateShotReadiness(
  template: ShotTemplate,
  landmarks: PoseLandmarks,
  visibleLandmarkCount: number
): ReadyScore {
  if (visibleLandmarkCount === 0) {
    return {
      isReady: false,
      score: 0,
      statusLabel: 'Find the subject',
    };
  }

  const bounds = getLandmarkBounds(landmarks);
  const centerScore = computeCenterScore(template, landmarks, bounds);
  const requiredScore = computeRequiredLandmarkScore(template, landmarks);
  const coverageScore = computeCoverageScore(template, bounds, visibleLandmarkCount);
  const score =
    centerScore * template.scoring.centerWeight +
    requiredScore * template.scoring.requiredWeight +
    coverageScore * template.scoring.coverageWeight;

  return {
    isReady: score >= template.readyThreshold,
    score,
    statusLabel: score >= template.readyThreshold ? 'Ready' : 'Adjust framing',
  };
}

function computeCenterScore(template: ShotTemplate, landmarks: PoseLandmarks, bounds: Bounds | null) {
  const targetCenterX = template.overlay.targetBox.x + template.overlay.targetBox.width / 2;
  const targetCenterY = template.overlay.targetBox.y + template.overlay.targetBox.height / 2;

  const torsoPoints = [
    landmarks.leftShoulder,
    landmarks.rightShoulder,
    landmarks.leftHip,
    landmarks.rightHip,
    landmarks.nose,
  ].filter(isDefined);

  if (torsoPoints.length === 0 && bounds == null) {
    return 0;
  }

  const averageX =
    torsoPoints.length > 0
      ? torsoPoints.reduce((sum, point) => sum + point.x, 0) / torsoPoints.length
      : (bounds!.minX + bounds!.maxX) / 2;
  const averageY =
    torsoPoints.length > 0
      ? torsoPoints.reduce((sum, point) => sum + point.y, 0) / torsoPoints.length
      : (bounds!.minY + bounds!.maxY) / 2;

  const deltaX = Math.min(Math.abs(averageX - targetCenterX) / 0.28, 1);
  const deltaY = Math.min(Math.abs(averageY - targetCenterY) / 0.34, 1);

  return Math.max(0, 1 - (deltaX + deltaY) / 2);
}

function computeRequiredLandmarkScore(template: ShotTemplate, landmarks: PoseLandmarks) {
  const hits = template.scoring.requiredLandmarks.filter((name) => landmarks[name] != null).length;
  return hits / template.scoring.requiredLandmarks.length;
}

function computeCoverageScore(
  template: ShotTemplate,
  bounds: Bounds | null,
  visibleLandmarkCount: number
) {
  if (bounds == null) {
    return 0;
  }

  const expectedHeight = template.overlay.targetBox.height;
  const actualHeight = bounds.maxY - bounds.minY;
  const heightRatio = actualHeight / expectedHeight;
  const heightScore = Math.max(0, 1 - Math.min(Math.abs(heightRatio - 1), 1));
  const densityScore = Math.min(
    visibleLandmarkCount / Math.max(template.scoring.minVisibleLandmarks, 1),
    1
  );

  return heightScore * 0.6 + densityScore * 0.4;
}

function getLandmarkBounds(landmarks: PoseLandmarks): Bounds | null {
  const entries = Object.values(landmarks);

  if (entries.length === 0) {
    return null;
  }

  return entries.reduce<Bounds>(
    (current, landmark) => ({
      maxX: Math.max(current.maxX, landmark.x),
      maxY: Math.max(current.maxY, landmark.y),
      minX: Math.min(current.minX, landmark.x),
      minY: Math.min(current.minY, landmark.y),
    }),
    {
      maxX: Number.NEGATIVE_INFINITY,
      maxY: Number.NEGATIVE_INFINITY,
      minX: Number.POSITIVE_INFINITY,
      minY: Number.POSITIVE_INFINITY,
    }
  );
}

function isDefined<T>(value: T | undefined): value is T {
  return value !== undefined;
}
