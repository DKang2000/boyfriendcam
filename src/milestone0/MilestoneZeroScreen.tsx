import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
  type LayoutChangeEvent,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  Camera,
  useCameraDevice,
  useCameraFormat,
  useCameraPermission,
  type CameraRuntimeError,
  type Orientation,
  type PhotoFile,
} from 'react-native-vision-camera';

import {
  SHOT_TEMPLATE_REGISTRY,
  type ShotTemplateId,
} from '../config/shotTemplates';
import { countVisibleLandmarks, type PoseLandmarks } from './pose';
import { PoseOverlay } from './PoseOverlay';
import { usePoseFrameProcessor } from './usePoseFrameProcessor';
import { ShotTemplateSelector } from '../milestone1/ShotTemplateSelector';
import { ShotTemplateOverlay } from '../milestone1/ShotTemplateOverlay';
import { evaluateShotReadiness } from '../milestone1/readiness';
import {
  buildEmulatorPose,
  EMULATOR_QA_SCENARIOS,
  type EmulatorQaScenario,
} from '../milestone1/emulatorQa';

type CameraLayout = {
  height: number;
  width: number;
};

type PoseFrameSnapshot = {
  lastPhotoPath: string | null;
  lastUpdateAt: number | null;
  landmarkCount: number;
  orientation: Orientation;
  poseCount: number;
  previewStatus: 'idle' | 'tracking';
};

type PoseTelemetry = {
  orientation: Orientation;
  poseCount: number;
  timestampMs: number;
};

const INITIAL_LAYOUT: CameraLayout = { height: 0, width: 0 };

export function MilestoneZeroScreen() {
  const cameraRef = useRef<Camera | null>(null);
  const { hasPermission, requestPermission } = useCameraPermission();
  const backDevice = useCameraDevice('back');
  const frontDevice = useCameraDevice('front');
  const device = backDevice ?? frontDevice;
  const isEmulatorQaMode = __DEV__ && device == null;
  const format = useCameraFormat(device, [{ videoResolution: { width: 1280, height: 720 } }]);
  const [cameraLayout, setCameraLayout] = useState(INITIAL_LAYOUT);
  const [isCapturing, setIsCapturing] = useState(false);
  const [runtimeError, setRuntimeError] = useState<string | null>(null);
  const [landmarks, setLandmarks] = useState<PoseLandmarks>({});
  const [selectedTemplateId, setSelectedTemplateId] = useState<ShotTemplateId>('full_body');
  const [showDebugOverlay, setShowDebugOverlay] = useState(__DEV__);
  const [emulatorScenario, setEmulatorScenario] = useState<EmulatorQaScenario>('ready_pose');
  const [emulatorOrientation, setEmulatorOrientation] = useState<Orientation>('portrait');
  const [snapshot, setSnapshot] = useState<PoseFrameSnapshot>({
    lastPhotoPath: null,
    lastUpdateAt: null,
    landmarkCount: 0,
    orientation: 'portrait',
    poseCount: 0,
    previewStatus: 'idle',
  });

  const handlePoseFrame = useCallback((nextLandmarks: PoseLandmarks, telemetry: PoseTelemetry) => {
    const visibleCount = countVisibleLandmarks(nextLandmarks);

    setLandmarks(nextLandmarks);
    setSnapshot((current) => ({
      ...current,
      landmarkCount: visibleCount,
      lastUpdateAt: telemetry.timestampMs,
      orientation: telemetry.orientation,
      poseCount: telemetry.poseCount,
      previewStatus: visibleCount > 0 ? 'tracking' : 'idle',
    }));
  }, []);

  const { frameProcessor, frameProcessorFps } = usePoseFrameProcessor(handlePoseFrame);
  const selectedTemplate = SHOT_TEMPLATE_REGISTRY[selectedTemplateId];

  useEffect(() => {
    if (!isEmulatorQaMode) {
      return;
    }

    const nextLandmarks = buildEmulatorPose(selectedTemplate, emulatorScenario);
    const visibleCount = countVisibleLandmarks(nextLandmarks);

    setLandmarks(nextLandmarks);
    setRuntimeError(null);
    setSnapshot((current) => ({
      ...current,
      landmarkCount: visibleCount,
      lastUpdateAt: Date.now(),
      orientation: emulatorOrientation,
      poseCount: visibleCount > 0 ? 1 : 0,
      previewStatus: visibleCount > 0 ? 'tracking' : 'idle',
    }));
  }, [emulatorOrientation, emulatorScenario, isEmulatorQaMode, selectedTemplate]);

  const activeCameraLabel = useMemo(() => {
    if (isEmulatorQaMode) {
      return 'emulator qa';
    }

    if (backDevice != null) {
      return 'back';
    }

    if (frontDevice != null) {
      return 'front (fallback)';
    }

    return 'none';
  }, [backDevice, frontDevice, isEmulatorQaMode]);
  const readyScore = useMemo(
    () => evaluateShotReadiness(selectedTemplate, landmarks, snapshot.landmarkCount),
    [landmarks, selectedTemplate, snapshot.landmarkCount]
  );

  const diagnostics = useMemo(
    () => [
      `template: ${selectedTemplate.label}`,
      `score: ${readyScore.score.toFixed(2)}`,
      `status: ${readyScore.statusLabel}`,
      `camera: ${activeCameraLabel}`,
      `preview: ${snapshot.previewStatus}`,
      `poses: ${snapshot.poseCount}`,
      `landmarks: ${snapshot.landmarkCount}`,
      `orientation: ${snapshot.orientation}`,
      `processor fps target: ${frameProcessorFps}`,
      snapshot.lastUpdateAt == null
        ? 'last update: waiting'
        : `last update: ${new Date(snapshot.lastUpdateAt).toLocaleTimeString()}`,
      snapshot.lastPhotoPath == null ? 'capture: none yet' : `capture: ${snapshot.lastPhotoPath}`,
    ],
    [
      activeCameraLabel,
      frameProcessorFps,
      readyScore.score,
      readyScore.statusLabel,
      selectedTemplate.label,
      snapshot,
    ]
  );

  const handleLayout = useCallback((event: LayoutChangeEvent) => {
    setCameraLayout(event.nativeEvent.layout);
  }, []);

  const handleCapture = useCallback(async () => {
    if (isCapturing) {
      return;
    }

    try {
      setIsCapturing(true);
      if (isEmulatorQaMode) {
        setSnapshot((current) => ({
          ...current,
          lastPhotoPath: `file://emulator-qa/${selectedTemplate.id}-${emulatorScenario}-${Date.now()}.jpg`,
        }));
      } else if (cameraRef.current != null) {
        const photo = await cameraRef.current.takePhoto({
          enableShutterSound: false,
        });

        setSnapshot((current) => ({
          ...current,
          lastPhotoPath: normalizePhotoPath(photo),
        }));
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown capture error';
      Alert.alert('Capture failed', message);
    } finally {
      setIsCapturing(false);
    }
  }, [emulatorScenario, isCapturing, isEmulatorQaMode, selectedTemplate.id]);

  const handleCameraError = useCallback((error: CameraRuntimeError) => {
    setRuntimeError(`${error.code}: ${error.message}`);
  }, []);

  if (!hasPermission) {
    return (
      <SafeAreaView edges={['top', 'bottom']} style={styles.permissionScreen}>
        <Text style={styles.eyebrow}>BoyfriendCam Milestone 0</Text>
        <Text style={styles.title}>Camera access is required for the live pose spike.</Text>
        <Text style={styles.body}>
          This build only validates the technical core: preview, frame processing, pose landmarks,
          upside-down portrait handling, and single capture.
        </Text>
        <Pressable onPress={requestPermission} style={styles.primaryButton}>
          <Text style={styles.primaryButtonLabel}>Grant camera permission</Text>
        </Pressable>
      </SafeAreaView>
    );
  }

  if (device == null && !isEmulatorQaMode) {
    return (
      <SafeAreaView edges={['top', 'bottom']} style={styles.permissionScreen}>
        <ActivityIndicator color="#ffffff" size="large" />
        <Text style={styles.title}>No usable camera was found.</Text>
        <Text style={styles.body}>
          This build prefers the back camera and falls back to the front camera. If you are using
          an emulator, set `Extended controls` {`>`} `Camera` and map at least one camera to
          `VirtualScene` or a webcam before reopening the app.
        </Text>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView edges={['top', 'bottom']} style={styles.screen}>
      <ScrollView
        contentContainerStyle={styles.screenContent}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <Text style={styles.eyebrow}>BoyfriendCam Milestone 1A</Text>
          <Text style={styles.title}>First product-layer camera UI shell</Text>
          <Text style={styles.body}>
            Product overlays now sit on top of the existing camera spike. Native pose and capture
            plumbing stays unchanged.
          </Text>
        </View>

        <ShotTemplateSelector
          onSelect={setSelectedTemplateId}
          selectedTemplateId={selectedTemplateId}
        />

        <View
          onLayout={handleLayout}
          style={[styles.previewCard, readyScore.isReady ? styles.previewCardReady : null]}
        >
          {isEmulatorQaMode ? (
            <View style={styles.emulatorPreview}>
              <Text style={styles.emulatorPreviewEyebrow}>Emulator QA mode</Text>
              <Text style={styles.emulatorPreviewTitle}>Mock preview surface active</Text>
              <Text style={styles.emulatorPreviewBody}>
                No compatible emulator camera was exposed, so this build is replaying simulated
                pose states to keep Milestone 1 UI and capture flows testable.
              </Text>
            </View>
          ) : (
            <Camera
              androidPreviewViewType="texture-view"
              device={device!}
              enableBufferCompression={false}
              fps={30}
              format={format}
              frameProcessor={frameProcessor}
              isActive
              outputOrientation="device"
              photo
              pixelFormat="rgb"
              preview
              ref={cameraRef}
              resizeMode="cover"
              style={StyleSheet.absoluteFillObject}
              videoStabilizationMode="off"
              onError={handleCameraError}
            />
          )}
          <ShotTemplateOverlay
            height={cameraLayout.height}
            isReady={readyScore.isReady}
            template={selectedTemplate}
            width={cameraLayout.width}
          />
          {showDebugOverlay ? (
            <PoseOverlay
              height={cameraLayout.height}
              landmarks={landmarks}
              width={cameraLayout.width}
            />
          ) : null}
          <View pointerEvents="none" style={styles.topChrome}>
            <View style={[styles.readyBadge, readyScore.isReady ? styles.readyBadgeActive : null]}>
              <Text
                style={[
                  styles.readyBadgeLabel,
                  readyScore.isReady ? styles.readyBadgeLabelActive : null,
                ]}
              >
                {readyScore.statusLabel}
              </Text>
            </View>
            <View style={styles.topChromeRight}>
              <Text style={styles.cameraPill}>{activeCameraLabel}</Text>
              <Text style={styles.templateSummary}>{selectedTemplate.summary}</Text>
            </View>
          </View>
          <View pointerEvents="none" style={styles.debugBadge}>
            <Text style={styles.debugBadgeText}>
              {readyScore.isReady
                ? `${selectedTemplate.label} locked`
                : snapshot.previewStatus === 'tracking'
                  ? 'match the template'
                  : 'waiting for pose'}
            </Text>
          </View>
        </View>

        <View style={styles.controlRow}>
          <View style={styles.scorePanel}>
            <Text style={styles.scoreLabel}>Ready score</Text>
            <Text style={[styles.scoreValue, readyScore.isReady ? styles.scoreValueReady : null]}>
              {Math.round(readyScore.score * 100)}%
            </Text>
            <Text style={styles.scoreHint}>
              Placeholder scoring uses current pose coverage and alignment plumbing.
            </Text>
          </View>

          {__DEV__ ? (
            <Pressable
              onPress={() => setShowDebugOverlay((current) => !current)}
              style={[styles.debugToggle, showDebugOverlay ? styles.debugToggleActive : null]}
            >
              <Text
                style={[
                  styles.debugToggleLabel,
                  showDebugOverlay ? styles.debugToggleLabelActive : null,
                ]}
              >
                {showDebugOverlay ? 'Hide debug' : 'Show debug'}
              </Text>
            </Pressable>
          ) : null}
        </View>

        {isEmulatorQaMode ? (
          <View style={styles.panel}>
            <Text style={styles.emulatorPanelLabel}>Emulator scenarios</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false}>
              <View style={styles.emulatorChipRow}>
                {EMULATOR_QA_SCENARIOS.map((scenario) => {
                  const selected = scenario.id === emulatorScenario;

                  return (
                    <Pressable
                      key={scenario.id}
                      onPress={() => setEmulatorScenario(scenario.id)}
                      style={[styles.emulatorChip, selected ? styles.emulatorChipSelected : null]}
                    >
                      <Text
                        style={[
                          styles.emulatorChipTitle,
                          selected ? styles.emulatorChipTitleSelected : null,
                        ]}
                      >
                        {scenario.label}
                      </Text>
                      <Text
                        style={[
                          styles.emulatorChipSummary,
                          selected ? styles.emulatorChipSummarySelected : null,
                        ]}
                      >
                        {scenario.summary}
                      </Text>
                    </Pressable>
                  );
                })}
              </View>
            </ScrollView>

            <Text style={[styles.emulatorPanelLabel, styles.emulatorOrientationLabel]}>
              Orientation
            </Text>
            <View style={styles.orientationRow}>
              <Pressable
                onPress={() => setEmulatorOrientation('portrait')}
                style={[
                  styles.orientationChip,
                  emulatorOrientation === 'portrait' ? styles.orientationChipSelected : null,
                ]}
              >
                <Text
                  style={[
                    styles.orientationChipLabel,
                    emulatorOrientation === 'portrait'
                      ? styles.orientationChipLabelSelected
                      : null,
                  ]}
                >
                  Portrait
                </Text>
              </Pressable>
              <Pressable
                onPress={() => setEmulatorOrientation('portrait-upside-down')}
                style={[
                  styles.orientationChip,
                  emulatorOrientation === 'portrait-upside-down'
                    ? styles.orientationChipSelected
                    : null,
                ]}
              >
                <Text
                  style={[
                    styles.orientationChipLabel,
                    emulatorOrientation === 'portrait-upside-down'
                      ? styles.orientationChipLabelSelected
                      : null,
                  ]}
                >
                  Upside down
                </Text>
              </Pressable>
            </View>
          </View>
        ) : null}

        {showDebugOverlay ? (
          <View style={styles.panel}>
            <ScrollView horizontal showsHorizontalScrollIndicator={false}>
              <View>
                {diagnostics.map((line) => (
                  <Text key={line} style={styles.panelText}>
                    {line}
                  </Text>
                ))}
                {runtimeError == null ? null : <Text style={styles.errorText}>{runtimeError}</Text>}
              </View>
            </ScrollView>
          </View>
        ) : null}

        <View style={styles.footer}>
          <Pressable disabled={isCapturing} onPress={handleCapture} style={styles.captureButton}>
            <Text style={styles.captureButtonLabel}>
              {isCapturing ? 'Capturing...' : 'Take single photo'}
            </Text>
          </Pressable>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function normalizePhotoPath(photo: PhotoFile) {
  if (photo.path.startsWith('file://')) {
    return photo.path;
  }

  return `file://${photo.path}`;
}

const styles = StyleSheet.create({
  body: {
    color: '#d6deeb',
    fontSize: 15,
    lineHeight: 22,
  },
  emulatorChip: {
    backgroundColor: '#101b2d',
    borderColor: '#1d2a40',
    borderRadius: 18,
    borderWidth: 1,
    gap: 6,
    marginRight: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    width: 170,
  },
  emulatorChipRow: {
    flexDirection: 'row',
    paddingRight: 12,
  },
  emulatorChipSelected: {
    backgroundColor: '#effd95',
    borderColor: '#effd95',
  },
  emulatorChipSummary: {
    color: '#94a7c2',
    fontSize: 12,
    lineHeight: 17,
  },
  emulatorChipSummarySelected: {
    color: '#31431b',
  },
  emulatorChipTitle: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '700',
  },
  emulatorChipTitleSelected: {
    color: '#11190d',
  },
  emulatorOrientationLabel: {
    marginTop: 16,
  },
  emulatorPanelLabel: {
    color: '#8ea0b8',
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 1.2,
    marginBottom: 10,
    textTransform: 'uppercase',
  },
  emulatorPreview: {
    alignItems: 'flex-start',
    backgroundColor: '#132238',
    justifyContent: 'flex-end',
    padding: 24,
    ...StyleSheet.absoluteFillObject,
  },
  emulatorPreviewBody: {
    color: '#d6deeb',
    fontSize: 15,
    lineHeight: 22,
    maxWidth: 280,
  },
  emulatorPreviewEyebrow: {
    color: '#effd95',
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 1.2,
    marginBottom: 8,
    textTransform: 'uppercase',
  },
  emulatorPreviewTitle: {
    color: '#ffffff',
    fontSize: 30,
    fontWeight: '800',
    lineHeight: 34,
    marginBottom: 10,
    maxWidth: 280,
  },
  captureButton: {
    alignItems: 'center',
    backgroundColor: '#f4ff61',
    borderRadius: 999,
    minWidth: 220,
    paddingHorizontal: 24,
    paddingVertical: 18,
  },
  captureButtonLabel: {
    color: '#07111f',
    fontSize: 16,
    fontWeight: '700',
  },
  controlRow: {
    alignItems: 'stretch',
    flexDirection: 'row',
    gap: 12,
    marginTop: 18,
  },
  debugBadge: {
    backgroundColor: 'rgba(7, 17, 31, 0.74)',
    borderColor: 'rgba(244, 255, 97, 0.32)',
    borderRadius: 999,
    borderWidth: 1,
    left: 16,
    paddingHorizontal: 12,
    paddingVertical: 8,
    position: 'absolute',
    top: 16,
  },
  debugBadgeText: {
    color: '#f4ff61',
    fontSize: 13,
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  debugToggle: {
    alignItems: 'center',
    backgroundColor: '#101b2d',
    borderColor: '#1d2a40',
    borderRadius: 18,
    borderWidth: 1,
    justifyContent: 'center',
    minWidth: 128,
    paddingHorizontal: 16,
    paddingVertical: 14,
  },
  debugToggleActive: {
    backgroundColor: '#24314a',
    borderColor: '#4f6385',
  },
  debugToggleLabel: {
    color: '#d8e1f1',
    fontSize: 14,
    fontWeight: '700',
  },
  debugToggleLabelActive: {
    color: '#ffffff',
  },
  errorText: {
    color: '#ff7b7b',
    fontSize: 13,
    lineHeight: 18,
    marginTop: 10,
  },
  eyebrow: {
    color: '#8ea0b8',
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 1.2,
    marginBottom: 8,
    textTransform: 'uppercase',
  },
  footer: {
    alignItems: 'center',
    marginTop: 20,
  },
  header: {
    gap: 8,
  },
  panel: {
    backgroundColor: '#101b2d',
    borderColor: '#1d2a40',
    borderRadius: 20,
    borderWidth: 1,
    marginTop: 20,
    padding: 16,
  },
  panelText: {
    color: '#eaf1ff',
    fontSize: 14,
    lineHeight: 22,
  },
  orientationChip: {
    alignItems: 'center',
    backgroundColor: '#101b2d',
    borderColor: '#1d2a40',
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  orientationChipLabel: {
    color: '#d8e1f1',
    fontSize: 13,
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  orientationChipLabelSelected: {
    color: '#11190d',
  },
  orientationChipSelected: {
    backgroundColor: '#effd95',
    borderColor: '#effd95',
  },
  orientationRow: {
    flexDirection: 'row',
    gap: 10,
  },
  permissionScreen: {
    backgroundColor: '#07111f',
    flex: 1,
    gap: 16,
    justifyContent: 'center',
    padding: 24,
  },
  previewCard: {
    aspectRatio: 9 / 16,
    backgroundColor: '#02070d',
    borderColor: '#1d2a40',
    borderRadius: 28,
    borderWidth: 1,
    marginTop: 20,
    overflow: 'hidden',
  },
  previewCardReady: {
    borderColor: '#65f28f',
    shadowColor: '#65f28f',
    shadowOpacity: 0.35,
    shadowRadius: 22,
  },
  primaryButton: {
    alignItems: 'center',
    alignSelf: 'flex-start',
    backgroundColor: '#f4ff61',
    borderRadius: 999,
    paddingHorizontal: 18,
    paddingVertical: 14,
  },
  primaryButtonLabel: {
    color: '#07111f',
    fontSize: 15,
    fontWeight: '700',
  },
  screen: {
    backgroundColor: '#07111f',
    flex: 1,
  },
  screenContent: {
    paddingHorizontal: 20,
    paddingVertical: 16,
  },
  scoreHint: {
    color: '#8ea0b8',
    fontSize: 12,
    lineHeight: 17,
    marginTop: 6,
  },
  scoreLabel: {
    color: '#8ea0b8',
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 1.2,
    textTransform: 'uppercase',
  },
  scorePanel: {
    backgroundColor: '#101b2d',
    borderColor: '#1d2a40',
    borderRadius: 20,
    borderWidth: 1,
    flex: 1,
    padding: 16,
  },
  scoreValue: {
    color: '#ffffff',
    fontSize: 34,
    fontWeight: '800',
    marginTop: 4,
  },
  scoreValueReady: {
    color: '#65f28f',
  },
  readyBadge: {
    alignSelf: 'flex-start',
    backgroundColor: 'rgba(7, 17, 31, 0.76)',
    borderColor: 'rgba(255, 255, 255, 0.24)',
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  readyBadgeActive: {
    backgroundColor: 'rgba(26, 74, 38, 0.92)',
    borderColor: '#65f28f',
  },
  readyBadgeLabel: {
    color: '#ffffff',
    fontSize: 13,
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  readyBadgeLabelActive: {
    color: '#dcffe2',
  },
  templateSummary: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: '700',
    lineHeight: 20,
    maxWidth: 210,
    textAlign: 'right',
  },
  cameraPill: {
    alignSelf: 'flex-end',
    backgroundColor: 'rgba(7, 17, 31, 0.76)',
    borderColor: 'rgba(255, 255, 255, 0.18)',
    borderRadius: 999,
    borderWidth: 1,
    color: '#d6deeb',
    fontSize: 11,
    fontWeight: '700',
    marginBottom: 8,
    overflow: 'hidden',
    paddingHorizontal: 10,
    paddingVertical: 6,
    textTransform: 'uppercase',
  },
  topChrome: {
    alignItems: 'flex-start',
    flexDirection: 'row',
    justifyContent: 'space-between',
    left: 16,
    position: 'absolute',
    right: 16,
    top: 16,
  },
  topChromeRight: {
    alignItems: 'flex-end',
    maxWidth: 210,
  },
  title: {
    color: '#ffffff',
    fontSize: 28,
    fontWeight: '800',
    lineHeight: 34,
  },
});
