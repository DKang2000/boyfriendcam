import XCTest
@testable import BoyfriendCamNative

final class FrameScoringEngineTests: XCTestCase {
    func testCenteredTemplateProducesHighScore() {
        let template = ShotTemplateRegistry.template(for: .portrait)
        let analysis = FrameScoringEngine.analyze(
            template: template,
            poseFrame: makeCenteredPortraitFrame()
        )

        XCTAssertGreaterThan(analysis.scores.totalScore, template.readyThreshold)
        XCTAssertGreaterThan(analysis.scores.centerScore, 0.7)
    }

    func testOversizedSubjectLowersCoverageScore() {
        let analysis = FrameScoringEngine.analyze(
            template: ShotTemplateRegistry.template(for: .portrait),
            poseFrame: makeOversizedPortraitFrame()
        )

        XCTAssertLessThan(analysis.scores.coverageScore, 0.55)
        XCTAssertGreaterThan(analysis.metrics.subjectHeightRatio, 1.15)
    }

    func testFullBodyTemplateRejectsTorsoOnlyPose() {
        let analysis = FrameScoringEngine.analyze(
            template: ShotTemplateRegistry.template(for: .fullBody),
            poseFrame: makeCenteredPortraitFrame()
        )

        XCTAssertEqual(analysis.metrics.visibleLandmarkCount, 0)
        XCTAssertEqual(analysis.scores.totalScore, 0)
    }

    func testWeakTorsoPoseFallsBackToNoSubject() {
        let analysis = FrameScoringEngine.analyze(
            template: ShotTemplateRegistry.template(for: .portrait),
            poseFrame: PoseFrame(
                landmarks: [
                    .leftShoulder: PoseLandmark(x: 0.48, y: 0.38, confidence: 0.4),
                    .rightShoulder: PoseLandmark(x: 0.52, y: 0.38, confidence: 0.4),
                    .leftHip: PoseLandmark(x: 0.49, y: 0.44, confidence: 0.4),
                    .rightHip: PoseLandmark(x: 0.51, y: 0.44, confidence: 0.4),
                ],
                timestampSeconds: 1
            )
        )

        XCTAssertEqual(analysis.metrics.visibleLandmarkCount, 0)
        XCTAssertEqual(analysis.scores.totalScore, 0)
    }

    func testHalfBodyTemplateAcceptsUpperBodyPoseWithoutVisibleHips() {
        let analysis = FrameScoringEngine.analyze(
            template: ShotTemplateRegistry.template(for: .halfBody),
            poseFrame: PoseFrame(
                landmarks: [
                    .nose: PoseLandmark(x: 0.51, y: 0.20, confidence: 0.92),
                    .leftEye: PoseLandmark(x: 0.47, y: 0.18, confidence: 0.88),
                    .rightEye: PoseLandmark(x: 0.55, y: 0.18, confidence: 0.88),
                    .leftShoulder: PoseLandmark(x: 0.40, y: 0.33, confidence: 0.84),
                    .rightShoulder: PoseLandmark(x: 0.62, y: 0.34, confidence: 0.85),
                    .leftElbow: PoseLandmark(x: 0.37, y: 0.47, confidence: 0.74),
                    .rightElbow: PoseLandmark(x: 0.65, y: 0.48, confidence: 0.76),
                ],
                timestampSeconds: 1
            )
        )

        XCTAssertGreaterThan(analysis.metrics.visibleLandmarkCount, 0)
        XCTAssertNotNil(analysis.metrics.subjectBounds)
        XCTAssertGreaterThan(analysis.scores.totalScore, 0)
    }

    func testAdaptiveCoachFindsSubjectWhenPoseMissing() {
        let result = AdaptiveCoachEngine.snapshot(
            previousState: AdaptiveCoachState(),
            poseFrame: nil,
            motion: nil,
            persona: .nice
        )

        XCTAssertEqual(result.1.experienceMode, .coach)
        XCTAssertEqual(result.1.overlayMode, .coachHighlight)
        XCTAssertEqual(result.1.coachRecommendation?.signal, .findSubject)
        XCTAssertEqual(result.1.primaryPromptText, "Find your subject")
        XCTAssertTrue(result.1.isGuidanceActive)
    }

    func testAdaptiveCoachCanReturnReadyForBalancedPortraitFrame() {
        let result = AdaptiveCoachEngine.snapshot(
            previousState: AdaptiveCoachState(
                displayedRecommendation: CoachRecommendation(
                    signal: .ready,
                    audience: .photographer,
                    confidence: 1,
                    isGuidanceActive: false
                )
            ),
            poseFrame: makeStraightOnCoachFrame(),
            motion: MotionGuidanceState(
                rollDegrees: 0,
                pitchDegrees: 10,
                normalizedPitchDegrees: 10,
                levelState: .level,
                phoneTiltSignal: nil,
                isPortraitUpright: true,
                isPortraitUpsideDown: false
            ),
            persona: .nice
        )

        XCTAssertEqual(result.1.coachRecommendation?.signal, .ready)
        XCTAssertEqual(result.1.coachRecommendation?.audience, .photographer)
        XCTAssertEqual(result.1.primaryPromptText, "Perfect. Take the shot.")
        XCTAssertEqual(result.1.framingSignal, .ready)
        XCTAssertFalse(result.1.isGuidanceActive)
    }

    func testAdaptiveCoachCanSurfaceSubjectDirectionForStrongFullBodyFrame() {
        let frame = makeFullBodyCoachFrame()
        let initial = AdaptiveCoachEngine.snapshot(
            previousState: AdaptiveCoachState(
                displayedRecommendation: CoachRecommendation(
                    signal: .ready,
                    audience: .photographer,
                    confidence: 1,
                    isGuidanceActive: false
                )
            ),
            poseFrame: frame,
            motion: MotionGuidanceState(
                rollDegrees: 0,
                pitchDegrees: 4,
                normalizedPitchDegrees: 4,
                levelState: .level,
                phoneTiltSignal: nil,
                isPortraitUpright: true,
                isPortraitUpsideDown: false
            ),
            persona: .nice
        )
        let held = AdaptiveCoachEngine.snapshot(
            previousState: initial.0,
            poseFrame: frame,
            motion: MotionGuidanceState(
                rollDegrees: 0,
                pitchDegrees: 4,
                normalizedPitchDegrees: 4,
                levelState: .level,
                phoneTiltSignal: nil,
                isPortraitUpright: true,
                isPortraitUpsideDown: false
            ),
            persona: .nice
        )

        XCTAssertEqual(held.1.coachRecommendation?.signal, .chinForward)
        XCTAssertEqual(held.1.primaryPromptText, "Ask them to bring their chin forward just a touch")
        XCTAssertEqual(held.1.coachRecommendation?.audience, .subject)
        XCTAssertTrue(held.1.isGuidanceActive)
    }

    func testFrameScoringPerformance() {
        let template = ShotTemplateRegistry.template(for: .portrait)
        let frame = makeCenteredPortraitFrame()

        measure {
            for _ in 0..<500 {
                _ = FrameScoringEngine.analyze(
                    template: template,
                    poseFrame: frame
                )
            }
        }
    }

    private func makeCenteredPortraitFrame() -> PoseFrame {
        PoseFrame(
            landmarks: [
                .nose: PoseLandmark(x: 0.50, y: 0.24, confidence: 0.9),
                .leftEye: PoseLandmark(x: 0.46, y: 0.22, confidence: 0.9),
                .rightEye: PoseLandmark(x: 0.54, y: 0.22, confidence: 0.9),
                .leftShoulder: PoseLandmark(x: 0.38, y: 0.34, confidence: 0.9),
                .rightShoulder: PoseLandmark(x: 0.62, y: 0.34, confidence: 0.9),
                .leftHip: PoseLandmark(x: 0.42, y: 0.52, confidence: 0.9),
                .rightHip: PoseLandmark(x: 0.58, y: 0.52, confidence: 0.9),
                .leftElbow: PoseLandmark(x: 0.35, y: 0.44, confidence: 0.9),
                .rightElbow: PoseLandmark(x: 0.65, y: 0.44, confidence: 0.9),
            ],
            timestampSeconds: 1
        )
    }

    private func makeOversizedPortraitFrame() -> PoseFrame {
        PoseFrame(
            landmarks: [
                .nose: PoseLandmark(x: 0.50, y: 0.12, confidence: 0.9),
                .leftEye: PoseLandmark(x: 0.44, y: 0.10, confidence: 0.9),
                .rightEye: PoseLandmark(x: 0.56, y: 0.10, confidence: 0.9),
                .leftShoulder: PoseLandmark(x: 0.34, y: 0.24, confidence: 0.9),
                .rightShoulder: PoseLandmark(x: 0.66, y: 0.24, confidence: 0.9),
                .leftHip: PoseLandmark(x: 0.36, y: 0.66, confidence: 0.9),
                .rightHip: PoseLandmark(x: 0.64, y: 0.66, confidence: 0.9),
                .leftElbow: PoseLandmark(x: 0.30, y: 0.40, confidence: 0.9),
                .rightElbow: PoseLandmark(x: 0.70, y: 0.40, confidence: 0.9),
            ],
            timestampSeconds: 1
        )
    }

    private func makeStraightOnCoachFrame() -> PoseFrame {
        PoseFrame(
            landmarks: [
                .nose: PoseLandmark(x: 0.50, y: 0.24, confidence: 0.92),
                .leftEye: PoseLandmark(x: 0.47, y: 0.22, confidence: 0.88),
                .rightEye: PoseLandmark(x: 0.53, y: 0.22, confidence: 0.88),
                .leftShoulder: PoseLandmark(x: 0.34, y: 0.34, confidence: 0.92),
                .rightShoulder: PoseLandmark(x: 0.66, y: 0.34, confidence: 0.92),
                .leftHip: PoseLandmark(x: 0.37, y: 0.58, confidence: 0.88),
                .rightHip: PoseLandmark(x: 0.63, y: 0.58, confidence: 0.88),
                .leftKnee: PoseLandmark(x: 0.40, y: 0.77, confidence: 0.78),
                .rightKnee: PoseLandmark(x: 0.60, y: 0.77, confidence: 0.78),
            ],
            timestampSeconds: 1
        )
    }

    private func makeFullBodyCoachFrame() -> PoseFrame {
        PoseFrame(
            landmarks: [
                .nose: PoseLandmark(x: 0.50, y: 0.33, confidence: 0.92),
                .leftEye: PoseLandmark(x: 0.47, y: 0.31, confidence: 0.88),
                .rightEye: PoseLandmark(x: 0.53, y: 0.31, confidence: 0.88),
                .leftShoulder: PoseLandmark(x: 0.41, y: 0.45, confidence: 0.92),
                .rightShoulder: PoseLandmark(x: 0.59, y: 0.45, confidence: 0.92),
                .leftHip: PoseLandmark(x: 0.46, y: 0.64, confidence: 0.90),
                .rightHip: PoseLandmark(x: 0.57, y: 0.64, confidence: 0.90),
                .leftKnee: PoseLandmark(x: 0.47, y: 0.77, confidence: 0.84),
                .rightKnee: PoseLandmark(x: 0.56, y: 0.77, confidence: 0.84),
                .leftAnkle: PoseLandmark(x: 0.48, y: 0.89, confidence: 0.80),
                .rightAnkle: PoseLandmark(x: 0.56, y: 0.89, confidence: 0.80),
            ],
            timestampSeconds: 1
        )
    }
}
