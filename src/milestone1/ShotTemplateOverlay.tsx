import { StyleSheet } from 'react-native';
import Svg, { Circle, Line, Path, Rect } from 'react-native-svg';

import type { ShotTemplate } from '../config/shotTemplates';

type ShotTemplateOverlayProps = {
  height: number;
  isReady: boolean;
  template: ShotTemplate;
  width: number;
};

export function ShotTemplateOverlay({
  height,
  isReady,
  template,
  width,
}: ShotTemplateOverlayProps) {
  if (width === 0 || height === 0) {
    return null;
  }

  const stroke = isReady ? '#65f28f' : 'rgba(255, 255, 255, 0.38)';
  const shell = isReady ? 'rgba(101, 242, 143, 0.14)' : 'rgba(255, 255, 255, 0.05)';
  const box = {
    x: template.overlay.targetBox.x * width,
    y: template.overlay.targetBox.y * height,
    width: template.overlay.targetBox.width * width,
    height: template.overlay.targetBox.height * height,
  };
  const headCenterX = box.x + box.width / 2;
  const headCenterY = box.y + box.height * 0.16;
  const headRadius = box.width * template.overlay.headRadius;
  const shoulderY = box.y + box.height * 0.3;
  const hipY = box.y + box.height * 0.58;
  const footY = box.y + box.height * 0.94;
  const shoulderHalf = (box.width * template.overlay.shoulderWidth) / 2;
  const hipHalf = (box.width * template.overlay.hipWidth) / 2;
  const footInset = box.width * template.overlay.footInset;
  const leftShoulderX = headCenterX - shoulderHalf;
  const rightShoulderX = headCenterX + shoulderHalf;
  const leftHipX = headCenterX - hipHalf;
  const rightHipX = headCenterX + hipHalf;

  return (
    <Svg height={height} pointerEvents="none" style={StyleSheet.absoluteFill} width={width}>
      <Rect
        fill={shell}
        height={box.height}
        rx={28}
        ry={28}
        stroke={stroke}
        strokeDasharray={isReady ? '0' : '10 12'}
        strokeWidth={isReady ? 3 : 2}
        width={box.width}
        x={box.x}
        y={box.y}
      />
      {template.guideMode === 'crosshair' ? (
        <>
          <Line
            stroke="rgba(255,255,255,0.24)"
            strokeDasharray="8 10"
            strokeWidth={1.5}
            x1={width / 2}
            x2={width / 2}
            y1={0}
            y2={height}
          />
          <Line
            stroke="rgba(255,255,255,0.24)"
            strokeDasharray="8 10"
            strokeWidth={1.5}
            x1={0}
            x2={width}
            y1={height / 2}
            y2={height / 2}
          />
        </>
      ) : (
        <>
          {[1 / 3, 2 / 3].map((fraction) => (
            <Line
              key={`v-${fraction}`}
              stroke="rgba(255,255,255,0.22)"
              strokeDasharray="6 10"
              strokeWidth={1.25}
              x1={width * fraction}
              x2={width * fraction}
              y1={0}
              y2={height}
            />
          ))}
          {[1 / 3, 2 / 3].map((fraction) => (
            <Line
              key={`h-${fraction}`}
              stroke="rgba(255,255,255,0.22)"
              strokeDasharray="6 10"
              strokeWidth={1.25}
              x1={0}
              x2={width}
              y1={height * fraction}
              y2={height * fraction}
            />
          ))}
        </>
      )}
      <Circle
        cx={headCenterX}
        cy={headCenterY}
        fill="rgba(255,255,255,0.08)"
        r={headRadius}
        stroke={stroke}
        strokeWidth={2}
      />
      <Path
        d={[
          `M ${leftShoulderX} ${shoulderY}`,
          `Q ${headCenterX} ${shoulderY - box.height * 0.08} ${rightShoulderX} ${shoulderY}`,
          `L ${rightHipX} ${hipY}`,
          `Q ${headCenterX} ${hipY + box.height * 0.04} ${leftHipX} ${hipY}`,
          'Z',
        ].join(' ')}
        fill="rgba(255,255,255,0.08)"
        stroke={stroke}
        strokeWidth={2}
      />
      <Line
        stroke={stroke}
        strokeLinecap="round"
        strokeWidth={2}
        x1={headCenterX}
        x2={headCenterX}
        y1={headCenterY + headRadius}
        y2={shoulderY}
      />
      <Line
        stroke={stroke}
        strokeLinecap="round"
        strokeWidth={2}
        x1={leftShoulderX}
        x2={leftHipX}
        y1={shoulderY}
        y2={hipY}
      />
      <Line
        stroke={stroke}
        strokeLinecap="round"
        strokeWidth={2}
        x1={rightShoulderX}
        x2={rightHipX}
        y1={shoulderY}
        y2={hipY}
      />
      <Line
        stroke={stroke}
        strokeLinecap="round"
        strokeWidth={2}
        x1={leftHipX}
        x2={box.x + footInset}
        y1={hipY}
        y2={footY}
      />
      <Line
        stroke={stroke}
        strokeLinecap="round"
        strokeWidth={2}
        x1={rightHipX}
        x2={box.x + box.width - footInset}
        y1={hipY}
        y2={footY}
      />
    </Svg>
  );
}
