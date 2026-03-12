import { memo } from 'react';
import { StyleSheet } from 'react-native';
import Svg, { Circle, Line } from 'react-native-svg';

import { landmarkEntries, POSE_CONNECTIONS, type PoseLandmarks } from './pose';

type PoseOverlayProps = {
  height: number;
  landmarks: PoseLandmarks;
  width: number;
};

export const PoseOverlay = memo(function PoseOverlay({
  height,
  landmarks,
  width,
}: PoseOverlayProps) {
  if (width === 0 || height === 0) {
    return null;
  }

  const points = landmarkEntries(landmarks);

  return (
    <Svg height={height} pointerEvents="none" style={StyleSheet.absoluteFill} width={width}>
      {POSE_CONNECTIONS.map(([start, end]) => {
        const startPoint = landmarks[start];
        const endPoint = landmarks[end];

        if (startPoint == null || endPoint == null) {
          return null;
        }

        return (
          <Line
            key={`${start}-${end}`}
            stroke="#54f5d2"
            strokeLinecap="round"
            strokeOpacity={0.85}
            strokeWidth={2}
            x1={startPoint.x * width}
            x2={endPoint.x * width}
            y1={startPoint.y * height}
            y2={endPoint.y * height}
          />
        );
      })}
      {points.map(([name, point]) => (
        <Circle
          cx={point.x * width}
          cy={point.y * height}
          fill="#f4ff61"
          key={name}
          opacity={Math.max(point.visibility, 0.55)}
          r={4}
        />
      ))}
    </Svg>
  );
});
