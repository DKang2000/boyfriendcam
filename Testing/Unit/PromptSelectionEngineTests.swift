import XCTest
@testable import BoyfriendCamNative

final class PromptSelectionEngineTests: XCTestCase {
    func testPromptDebounceRequiresRepeatedCandidateBeforeSwitching() {
        let template = ShotTemplateRegistry.template(for: .portrait)
        let candidateAnalysis = FrameScoringEngine.analyze(
            template: template,
            poseFrame: makeFrame(xOffset: 0.18, yOffset: 0, heightRatio: 1)
        )
        let candidate = PromptSelectionEngine.framingCandidate(
            analysis: candidateAnalysis,
            template: template,
            isReady: false
        )

        XCTAssertNotEqual(candidate, .findSubject)
        XCTAssertNotEqual(candidate, .ready)

        var state = PromptSelectionState()
        state = PromptSelectionEngine.nextState(
            previousState: state,
            analysis: candidateAnalysis,
            template: template,
            phoneTiltSignal: nil
        )

        XCTAssertEqual(state.displayedFramingSignal, .findSubject)

        state = PromptSelectionEngine.nextState(
            previousState: state,
            analysis: candidateAnalysis,
            template: template,
            phoneTiltSignal: nil
        )

        XCTAssertEqual(state.displayedFramingSignal, candidate)
    }

    func testReadyStateUsesHysteresis() {
        let template = ShotTemplateRegistry.template(for: .portrait)
        var state = PromptSelectionState()

        let strongAnalysis = FrameScoringEngine.analyze(
            template: template,
            poseFrame: makeFrame(xOffset: 0, yOffset: 0, heightRatio: 1)
        )
        for _ in 0..<5 {
            state = PromptSelectionEngine.nextState(
                previousState: state,
                analysis: strongAnalysis,
                template: template,
                phoneTiltSignal: nil
            )
        }

        XCTAssertTrue(state.isReady)

        let slightDropAnalysis = FrameScoringEngine.analyze(
            template: template,
            poseFrame: makeFrame(xOffset: 0.02, yOffset: 0.04, heightRatio: 1.08)
        )
        state = PromptSelectionEngine.nextState(
            previousState: state,
            analysis: slightDropAnalysis,
            template: template,
            phoneTiltSignal: nil
        )

        XCTAssertTrue(state.isReady)
    }

    func testPersonaPhrasesStayDeterministic() {
        XCTAssertEqual(
            PersonaPackRegistry.phrase(for: FramingPromptSignal.moveBack, persona: .nice),
            "Take a few steps back"
        )
        XCTAssertEqual(
            PersonaPackRegistry.phrase(for: FramingPromptSignal.moveBack, persona: .sassy),
            "Back it up a bit"
        )
        XCTAssertEqual(
            PersonaPackRegistry.phrase(for: FramingPromptSignal.moveBack, persona: .mean),
            "Back up."
        )
    }

    func testCoachingPipelinePromotesTiltPromptToPrimaryText() {
        let template = ShotTemplateRegistry.template(for: .portrait)
        let frame = makeFrame(xOffset: 0, yOffset: 0, heightRatio: 1)
        var state = PromptSelectionState()
        var snapshot: CoachingSnapshot?

        for _ in 0..<2 {
            let result = CoachingPipeline.snapshot(
                previousState: state,
                template: template,
                poseFrame: frame,
                persona: .nice,
                phoneTiltSignal: .tiltPhoneUp
            )
            state = result.0
            snapshot = result.1
        }

        XCTAssertEqual(snapshot?.primaryPromptText, "Tilt your camera up just a touch")
        XCTAssertNil(snapshot?.secondaryPromptText)
    }

    func testCoachingPipelineKeepsFindSubjectPrimaryWhenTiltSignalExists() {
        let template = ShotTemplateRegistry.template(for: .portrait)
        var state = PromptSelectionState()
        var snapshot: CoachingSnapshot?

        for _ in 0..<2 {
            let result = CoachingPipeline.snapshot(
                previousState: state,
                template: template,
                poseFrame: nil,
                persona: .nice,
                phoneTiltSignal: .tiltPhoneDown
            )
            state = result.0
            snapshot = result.1
        }

        XCTAssertEqual(snapshot?.primaryPromptText, "Find your subject")
        XCTAssertNil(snapshot?.secondaryPromptText)
        XCTAssertEqual(snapshot?.phoneTiltSignal, .tiltPhoneDown)
    }

    func testMotionGuidancePitchMappingMatchesMirrorHoldBehavior() {
        XCTAssertEqual(
            MotionGuidanceService.phoneTiltSignal(
                normalizedPitchDegrees: -22,
                normalizedRollDegrees: 0
            ),
            .tiltPhoneDown
        )
        XCTAssertEqual(
            MotionGuidanceService.phoneTiltSignal(
                normalizedPitchDegrees: 22,
                normalizedRollDegrees: 0
            ),
            .tiltPhoneUp
        )
    }

    func testCoachingPipelinePerformance() {
        let template = ShotTemplateRegistry.template(for: .portrait)
        let frame = makeFrame(xOffset: 0.02, yOffset: 0.01, heightRatio: 1.04)

        measure {
            var state = PromptSelectionState()
            for _ in 0..<250 {
                let result = CoachingPipeline.snapshot(
                    previousState: state,
                    template: template,
                    poseFrame: frame,
                    persona: .nice,
                    phoneTiltSignal: .levelPhone
                )
                state = result.0
                _ = result.1
            }
        }
    }

    private func makeFrame(
        xOffset: CGFloat,
        yOffset: CGFloat,
        heightRatio: CGFloat
    ) -> PoseFrame {
        let template = ShotTemplateRegistry.template(for: .portrait)
        let targetCenterX = template.overlay.targetBox.x + template.overlay.targetBox.width / 2 + xOffset
        let targetCenterY = template.overlay.targetBox.y + template.overlay.targetBox.height / 2 + yOffset
        let targetHeight = template.overlay.targetBox.height * heightRatio
        let halfHeight = targetHeight / 2
        let shoulderY = targetCenterY - halfHeight * 0.30
        let hipY = targetCenterY + halfHeight * 0.28

        return PoseFrame(
            landmarks: [
                .nose: PoseLandmark(x: targetCenterX, y: targetCenterY - halfHeight * 0.54, confidence: 0.9),
                .leftEye: PoseLandmark(x: targetCenterX - 0.04, y: targetCenterY - halfHeight * 0.58, confidence: 0.9),
                .rightEye: PoseLandmark(x: targetCenterX + 0.04, y: targetCenterY - halfHeight * 0.58, confidence: 0.9),
                .leftShoulder: PoseLandmark(x: targetCenterX - 0.12, y: shoulderY, confidence: 0.9),
                .rightShoulder: PoseLandmark(x: targetCenterX + 0.12, y: shoulderY, confidence: 0.9),
                .leftHip: PoseLandmark(x: targetCenterX - 0.08, y: hipY, confidence: 0.9),
                .rightHip: PoseLandmark(x: targetCenterX + 0.08, y: hipY, confidence: 0.9),
                .leftElbow: PoseLandmark(x: targetCenterX - 0.16, y: targetCenterY, confidence: 0.9),
                .rightElbow: PoseLandmark(x: targetCenterX + 0.16, y: targetCenterY, confidence: 0.9),
            ],
            timestampSeconds: 1
        )
    }
}
