import CoreGraphics

enum CoachingPipeline {
    static func snapshot(
        previousState: PromptSelectionState,
        template: ShotTemplate,
        poseFrame: PoseFrame?,
        persona: CoachPersona,
        phoneTiltSignal: PhoneTiltPromptSignal? = nil
    ) -> (PromptSelectionState, CoachingSnapshot) {
        let analysis = FrameScoringEngine.analyze(template: template, poseFrame: poseFrame)
        let nextState = PromptSelectionEngine.nextState(
            previousState: previousState,
            analysis: analysis,
            template: template,
            phoneTiltSignal: phoneTiltSignal
        )

        let primaryText: String
        let secondaryText: String?

        if shouldLeadWithPhoneTilt(nextState),
           let displayedPhoneTiltSignal = nextState.displayedPhoneTiltSignal {
            primaryText = PersonaPackRegistry.phrase(for: displayedPhoneTiltSignal, persona: persona)
            secondaryText = supportingFramingText(
                for: nextState.displayedFramingSignal,
                persona: persona
            )
        } else {
            primaryText = PersonaPackRegistry.phrase(
                for: nextState.displayedFramingSignal,
                persona: persona
            )
            secondaryText = nil
        }
        let statusLabel = nextState.isReady ? "Ready" : "Adjust framing"

        return (
            nextState,
            CoachingSnapshot(
                analysis: analysis,
                smoothedScore: nextState.smoothedScore ?? analysis.scores.totalScore,
                isReady: nextState.isReady,
                statusLabel: statusLabel,
                experienceMode: .templates,
                overlayMode: .templateGuide,
                isGuidanceActive: !nextState.isReady,
                framingSignal: nextState.displayedFramingSignal,
                phoneTiltSignal: nextState.displayedPhoneTiltSignal,
                coachRecommendation: nil,
                primaryPromptText: primaryText,
                secondaryPromptText: secondaryText
            )
        )
    }

    private static func supportingFramingText(
        for signal: FramingPromptSignal,
        persona: CoachPersona
    ) -> String? {
        switch signal {
        case .ready, .findSubject, .adjustFraming:
            return nil
        default:
            return PersonaPackRegistry.phrase(for: signal, persona: persona)
        }
    }

    private static func shouldLeadWithPhoneTilt(_ state: PromptSelectionState) -> Bool {
        guard state.displayedPhoneTiltSignal != nil else {
            return false
        }

        switch state.displayedFramingSignal {
        case .findSubject, .fitSubject:
            return false
        default:
            return true
        }
    }
}

enum PersonaPackRegistry {
    static func phrase(
        for signal: FramingPromptSignal,
        persona: CoachPersona
    ) -> String {
        switch persona {
        case .nice:
            return niceFramingPhrase(for: signal)
        case .sassy:
            return sassyFramingPhrase(for: signal)
        case .mean:
            return meanFramingPhrase(for: signal)
        }
    }

    static func phrase(
        for signal: PhoneTiltPromptSignal,
        persona: CoachPersona
    ) -> String {
        switch persona {
        case .nice:
            return nicePhonePhrase(for: signal)
        case .sassy:
            return sassyPhonePhrase(for: signal)
        case .mean:
            return meanPhonePhrase(for: signal)
        }
    }

    static func phrase(
        for signal: CoachPromptSignal,
        persona: CoachPersona
    ) -> String {
        switch persona {
        case .nice:
            return niceCoachPhrase(for: signal)
        case .sassy:
            return sassyCoachPhrase(for: signal)
        case .mean:
            return meanCoachPhrase(for: signal)
        }
    }

    private static func niceFramingPhrase(for signal: FramingPromptSignal) -> String {
        switch signal {
        case .ready:
            return "Perfect. Take the shot."
        case .findSubject:
            return "Find your subject"
        case .moveLeft:
            return "Move a little left"
        case .moveRight:
            return "Move a little right"
        case .moveBack:
            return "Take a few steps back"
        case .moveCloser:
            return "Step a little closer"
        case .raiseCamera:
            return "Lift your camera just a little"
        case .lowerCamera:
            return "Lower your camera just a little"
        case .fitSubject:
            return "Fit a little more of them in frame"
        case .adjustFraming:
            return "Adjust the framing a little"
        }
    }

    private static func sassyFramingPhrase(for signal: FramingPromptSignal) -> String {
        switch signal {
        case .ready:
            return "Yep. That's the one."
        case .findSubject:
            return "Where'd they go? Find the subject."
        case .moveLeft:
            return "Scoot left a little"
        case .moveRight:
            return "Scoot right a little"
        case .moveBack:
            return "Back it up a bit"
        case .moveCloser:
            return "Come in a little closer"
        case .raiseCamera:
            return "Bring the camera up a touch"
        case .lowerCamera:
            return "Drop the camera a touch"
        case .fitSubject:
            return "Get more of them in frame"
        case .adjustFraming:
            return "Clean up that framing"
        }
    }

    private static func meanFramingPhrase(for signal: FramingPromptSignal) -> String {
        switch signal {
        case .ready:
            return "Finally. Take it."
        case .findSubject:
            return "Find the subject."
        case .moveLeft:
            return "Move left."
        case .moveRight:
            return "Move right."
        case .moveBack:
            return "Back up."
        case .moveCloser:
            return "Get closer."
        case .raiseCamera:
            return "Raise the camera."
        case .lowerCamera:
            return "Lower the camera."
        case .fitSubject:
            return "Fit them in the frame."
        case .adjustFraming:
            return "Fix the framing."
        }
    }

    private static func nicePhonePhrase(for signal: PhoneTiltPromptSignal) -> String {
        switch signal {
        case .tiltPhoneUp:
            return "Tilt your camera up just a touch"
        case .tiltPhoneDown:
            return "Tilt your camera down just a touch"
        case .levelPhone:
            return "Straighten your camera a little"
        }
    }

    private static func sassyPhonePhrase(for signal: PhoneTiltPromptSignal) -> String {
        switch signal {
        case .tiltPhoneUp:
            return "Tilt the phone up a touch"
        case .tiltPhoneDown:
            return "Tilt the phone down a touch"
        case .levelPhone:
            return "Straighten the phone out"
        }
    }

    private static func meanPhonePhrase(for signal: PhoneTiltPromptSignal) -> String {
        switch signal {
        case .tiltPhoneUp:
            return "Tilt the phone up."
        case .tiltPhoneDown:
            return "Tilt the phone down."
        case .levelPhone:
            return "Level the phone."
        }
    }

    private static func niceCoachPhrase(for signal: CoachPromptSignal) -> String {
        switch signal {
        case .ready:
            return "Perfect. Take the shot."
        case .findSubject:
            return "Find your subject"
        case .moveLeft:
            return "Move a little left"
        case .moveRight:
            return "Move a little right"
        case .moveBack:
            return "Take a few steps back"
        case .moveCloser:
            return "Step a little closer"
        case .raiseCamera:
            return "Lift your camera just a little"
        case .lowerCamera:
            return "Lower your camera just a little"
        case .tiltPhoneUp:
            return "Tilt your camera up just a touch"
        case .tiltPhoneDown:
            return "Tilt your camera down just a touch"
        case .flipUpsideDown:
            return "Try flipping upside down for a taller look"
        case .turnBody:
            return "Have them turn a little sideways"
        case .turnFace:
            return "Ask them to face back toward you"
        case .chinForward:
            return "Ask them to bring their chin forward just a touch"
        case .chinDown:
            return "Ask them to lower their chin just a touch"
        }
    }

    private static func sassyCoachPhrase(for signal: CoachPromptSignal) -> String {
        switch signal {
        case .ready:
            return "Yep. That's the one."
        case .findSubject:
            return "Where'd they go? Find the subject."
        case .moveLeft:
            return "Scoot left a little"
        case .moveRight:
            return "Scoot right a little"
        case .moveBack:
            return "Back it up a bit"
        case .moveCloser:
            return "Come in a little closer"
        case .raiseCamera:
            return "Bring the camera up a touch"
        case .lowerCamera:
            return "Drop the camera a touch"
        case .tiltPhoneUp:
            return "Tilt the phone up a touch"
        case .tiltPhoneDown:
            return "Tilt the phone down a touch"
        case .flipUpsideDown:
            return "Flip it upside down for extra length"
        case .turnBody:
            return "Have them cheat a little sideways"
        case .turnFace:
            return "Have them look back to the lens"
        case .chinForward:
            return "Ask for a tiny chin-forward moment"
        case .chinDown:
            return "Ask for just a touch more chin down"
        }
    }

    private static func meanCoachPhrase(for signal: CoachPromptSignal) -> String {
        switch signal {
        case .ready:
            return "Finally. Take it."
        case .findSubject:
            return "Find the subject."
        case .moveLeft:
            return "Move left."
        case .moveRight:
            return "Move right."
        case .moveBack:
            return "Back up."
        case .moveCloser:
            return "Get closer."
        case .raiseCamera:
            return "Raise the camera."
        case .lowerCamera:
            return "Lower the camera."
        case .tiltPhoneUp:
            return "Tilt the phone up."
        case .tiltPhoneDown:
            return "Tilt the phone down."
        case .flipUpsideDown:
            return "Flip it upside down."
        case .turnBody:
            return "Turn them sideways."
        case .turnFace:
            return "Have them face the lens."
        case .chinForward:
            return "Chin forward."
        case .chinDown:
            return "Chin down."
        }
    }
}

struct AdaptiveCoachState: Equatable {
    var displayedRecommendation: CoachRecommendation = CoachRecommendation(
        signal: .findSubject,
        audience: .photographer,
        confidence: 1,
        isGuidanceActive: true
    )
    var pendingRecommendation: CoachRecommendation?
    var pendingFrames = 0
}

enum AdaptiveCoachEngine {
    static func snapshot(
        previousState: AdaptiveCoachState,
        poseFrame: PoseFrame?,
        motion: MotionGuidanceState?,
        persona: CoachPersona
    ) -> (AdaptiveCoachState, CoachingSnapshot) {
        let scene = CoachSceneMetrics(poseFrame: poseFrame, motion: motion)
        let candidate = recommendation(for: scene)
        let nextState = debouncedState(
            currentState: previousState,
            candidate: candidate,
            holdFrames: scene.holdFrames
        )
        let displayedRecommendation = nextState.displayedRecommendation
        let snapshot = CoachingSnapshot(
            analysis: scene.analysis,
            smoothedScore: displayedRecommendation.confidence,
            isReady: displayedRecommendation.signal == .ready,
            statusLabel: displayedRecommendation.signal == .ready ? "Ready" : "Coach",
            experienceMode: .coach,
            overlayMode: .coachHighlight,
            isGuidanceActive: displayedRecommendation.isGuidanceActive,
            framingSignal: framingSignal(for: displayedRecommendation.signal),
            phoneTiltSignal: phoneTiltSignal(for: displayedRecommendation.signal),
            coachRecommendation: displayedRecommendation,
            primaryPromptText: PersonaPackRegistry.phrase(for: displayedRecommendation.signal, persona: persona),
            secondaryPromptText: nil
        )

        return (nextState, snapshot)
    }

    private static func debouncedState(
        currentState: AdaptiveCoachState,
        candidate: CoachRecommendation,
        holdFrames: Int
    ) -> AdaptiveCoachState {
        var nextState = currentState

        if currentState.displayedRecommendation.signal == candidate.signal {
            nextState.displayedRecommendation = candidate
            nextState.pendingRecommendation = nil
            nextState.pendingFrames = 0
            return nextState
        }

        if currentState.pendingRecommendation?.signal == candidate.signal {
            nextState.pendingRecommendation = candidate
            nextState.pendingFrames += 1
        } else {
            nextState.pendingRecommendation = candidate
            nextState.pendingFrames = 1
        }

        if nextState.pendingFrames >= max(holdFrames, 1) {
            nextState.displayedRecommendation = candidate
            nextState.pendingRecommendation = nil
            nextState.pendingFrames = 0
        }

        return nextState
    }

    private static func recommendation(for scene: CoachSceneMetrics) -> CoachRecommendation {
        guard let descriptor = scene.descriptor else {
            return CoachRecommendation(
                signal: .findSubject,
                audience: .photographer,
                confidence: 1,
                isGuidanceActive: true
            )
        }

        var candidates: [CoachRecommendation] = []
        let subjectHeight = descriptor.subjectBounds.height
        let centerXOffset = descriptor.subjectCenter.x - 0.5
        let centerYOffset = descriptor.subjectCenter.y - scene.targetCenterY

        if subjectHeight > scene.maximumHeight {
            candidates.append(
                CoachRecommendation(
                    signal: .moveBack,
                    audience: .photographer,
                    confidence: 0.56 + Double(min((subjectHeight - scene.maximumHeight) / 0.20, 1)) * 0.34,
                    isGuidanceActive: true
                )
            )
        } else if subjectHeight < scene.minimumHeight {
            candidates.append(
                CoachRecommendation(
                    signal: .moveCloser,
                    audience: .photographer,
                    confidence: 0.44 + Double(min((scene.minimumHeight - subjectHeight) / 0.20, 1)) * 0.28,
                    isGuidanceActive: true
                )
            )
        }

        if centerXOffset < -0.08 {
            candidates.append(
                CoachRecommendation(
                    signal: .moveLeft,
                    audience: .photographer,
                    confidence: 0.42 + Double(min(abs(centerXOffset) / 0.20, 1)) * 0.24,
                    isGuidanceActive: true
                )
            )
        } else if centerXOffset > 0.08 {
            candidates.append(
                CoachRecommendation(
                    signal: .moveRight,
                    audience: .photographer,
                    confidence: 0.42 + Double(min(abs(centerXOffset) / 0.20, 1)) * 0.24,
                    isGuidanceActive: true
                )
            )
        }

        if centerYOffset < -0.09 {
            candidates.append(
                CoachRecommendation(
                    signal: .raiseCamera,
                    audience: .photographer,
                    confidence: 0.42 + Double(min(abs(centerYOffset) / 0.20, 1)) * 0.26,
                    isGuidanceActive: true
                )
            )
        } else if centerYOffset > 0.09 {
            candidates.append(
                CoachRecommendation(
                    signal: .lowerCamera,
                    audience: .photographer,
                    confidence: 0.42 + Double(min(abs(centerYOffset) / 0.20, 1)) * 0.26,
                    isGuidanceActive: true
                )
            )
        }

        if scene.isFramingReasonable {
            if scene.pitchDelta < -8 {
                candidates.append(
                    CoachRecommendation(
                        signal: .tiltPhoneUp,
                        audience: .photographer,
                        confidence: 0.36 + Double(min(abs(scene.pitchDelta) / 18, 1)) * 0.20,
                        isGuidanceActive: true
                    )
                )
            } else if scene.pitchDelta > 8 {
                candidates.append(
                    CoachRecommendation(
                        signal: .tiltPhoneDown,
                        audience: .photographer,
                        confidence: 0.36 + Double(min(abs(scene.pitchDelta) / 18, 1)) * 0.20,
                        isGuidanceActive: true
                    )
                )
            }
        }

        if scene.prefersSubjectDirection {
            if scene.bodyTurnQuality < 0.46 {
                candidates.append(
                    CoachRecommendation(
                        signal: .turnBody,
                        audience: .subject,
                        confidence: 0.40 + (1 - scene.bodyTurnQuality) * 0.28,
                        isGuidanceActive: true
                    )
                )
            } else if scene.faceReturnQuality < 0.48 {
                candidates.append(
                    CoachRecommendation(
                        signal: .turnFace,
                        audience: .subject,
                        confidence: 0.38 + (1 - scene.faceReturnQuality) * 0.24,
                        isGuidanceActive: true
                    )
                )
            } else if scene.chinDownQuality < 0.38 {
                candidates.append(
                    CoachRecommendation(
                        signal: .chinDown,
                        audience: .subject,
                        confidence: 0.32 + (1 - scene.chinDownQuality) * 0.18,
                        isGuidanceActive: true
                    )
                )
            } else if scene.chinForwardQuality < 0.40 {
                candidates.append(
                    CoachRecommendation(
                        signal: .chinForward,
                        audience: .subject,
                        confidence: 0.30 + (1 - scene.chinForwardQuality) * 0.16,
                        isGuidanceActive: true
                    )
                )
            }
        }

        if scene.upsideDownHelpful && !scene.isPortraitUpsideDown && scene.isFramingReasonable {
            candidates.append(
                CoachRecommendation(
                    signal: .flipUpsideDown,
                    audience: .photographer,
                    confidence: 0.34 + Double(min((subjectHeight - 0.56) / 0.20, 1)) * 0.20,
                    isGuidanceActive: true
                )
            )
        }

        if let strongest = candidates.max(by: { $0.confidence < $1.confidence }), strongest.confidence >= 0.28 {
            return strongest
        }

        return CoachRecommendation(
            signal: .ready,
            audience: .photographer,
            confidence: 1,
            isGuidanceActive: false
        )
    }

    private static func framingSignal(for signal: CoachPromptSignal) -> FramingPromptSignal {
        switch signal {
        case .ready:
            return .ready
        case .findSubject:
            return .findSubject
        case .moveLeft:
            return .moveLeft
        case .moveRight:
            return .moveRight
        case .moveBack:
            return .moveBack
        case .moveCloser:
            return .moveCloser
        case .raiseCamera:
            return .raiseCamera
        case .lowerCamera:
            return .lowerCamera
        case .tiltPhoneUp,
                .tiltPhoneDown,
                .flipUpsideDown,
                .turnBody,
                .turnFace,
                .chinForward,
                .chinDown:
            return .adjustFraming
        }
    }

    private static func phoneTiltSignal(for signal: CoachPromptSignal) -> PhoneTiltPromptSignal? {
        switch signal {
        case .tiltPhoneUp:
            return .tiltPhoneUp
        case .tiltPhoneDown:
            return .tiltPhoneDown
        default:
            return nil
        }
    }
}

private struct CoachSceneMetrics {
    let descriptor: PoseBodyDescriptor?
    let analysis: FrameAnalysis
    let minimumHeight: CGFloat
    let maximumHeight: CGFloat
    let targetCenterY: CGFloat
    let pitchDelta: Double
    let isPortraitUpsideDown: Bool
    let upsideDownHelpful: Bool
    let bodyTurnQuality: Double
    let faceReturnQuality: Double
    let chinDownQuality: Double
    let chinForwardQuality: Double
    let prefersSubjectDirection: Bool
    let isFramingReasonable: Bool
    let holdFrames: Int

    init(poseFrame: PoseFrame?, motion: MotionGuidanceState?) {
        let descriptor = poseFrame?.coachBodyDescriptor()
        self.descriptor = descriptor

        let visibleLandmarkCount = poseFrame?.visibleLandmarkCount ?? 0
        let subjectCenter = descriptor?.subjectCenter
        let subjectBounds = descriptor?.subjectBounds
        let subjectHeight = subjectBounds?.height ?? 0
        let fullBodyVisible = descriptor?.hasLowerBodyAnchors == true && (descriptor?.footY ?? 0) > 0.84 && subjectHeight > 0.50
        let closePortrait = subjectHeight > 0.70 && !fullBodyVisible

        minimumHeight = fullBodyVisible ? 0.48 : 0.40
        maximumHeight = fullBodyVisible ? 0.78 : 0.74
        targetCenterY = fullBodyVisible ? 0.54 : 0.46

        let preferredPitch = fullBodyVisible ? 4.0 : 10.0
        let normalizedPitch = motion?.normalizedPitchDegrees ?? preferredPitch
        pitchDelta = normalizedPitch - preferredPitch
        isPortraitUpsideDown = motion?.isPortraitUpsideDown ?? false

        let centerXOffset = (subjectCenter?.x ?? 0.5) - 0.5
        let centerYOffset = (subjectCenter?.y ?? targetCenterY) - targetCenterY
        let sizeIsReasonable = descriptor != nil && subjectHeight >= minimumHeight && subjectHeight <= maximumHeight
        isFramingReasonable = sizeIsReasonable && abs(centerXOffset) < 0.08 && abs(centerYOffset) < 0.10

        if
            let descriptor,
            let poseFrame
        {
            let torsoShear = abs(descriptor.shoulderCenter.x - descriptor.hipCenter.x) / max(descriptor.shoulderWidth, 0.001)
            let targetTurnShear: CGFloat = fullBodyVisible ? 0.14 : 0.18
            bodyTurnQuality = max(0, 1 - Double(min(abs(torsoShear - targetTurnShear) / 0.18, 1)))

            if
                let eyeCenter = poseFrame.eyeCenter(),
                let nose = poseFrame.landmarks[.nose]
            {
                let eyeSpan = max(poseFrame.eyeSpan(), 0.001)
                let noseOffset = abs(nose.x - eyeCenter.x) / eyeSpan
                faceReturnQuality = max(0, 1 - Double(min(noseOffset / 0.40, 1)))

                let noseGap = (nose.y - eyeCenter.y) / eyeSpan
                chinDownQuality = max(0, 1 - Double(min(abs(noseGap - 0.34) / 0.18, 1)))

                let shoulderGap = (descriptor.shoulderCenter.y - eyeCenter.y) / eyeSpan
                chinForwardQuality = max(0, 1 - Double(min(abs(shoulderGap - 1.28) / 0.55, 1)))
            } else {
                faceReturnQuality = 0.62
                chinDownQuality = 0.58
                chinForwardQuality = 0.58
            }
        } else {
            bodyTurnQuality = 0
            faceReturnQuality = 0
            chinDownQuality = 0
            chinForwardQuality = 0
        }

        prefersSubjectDirection = descriptor != nil && (closePortrait || subjectHeight > 0.48)
        upsideDownHelpful =
            fullBodyVisible &&
            subjectHeight > 0.58 &&
            abs(centerXOffset) < 0.08 &&
            abs(centerYOffset) < 0.12 &&
            abs(pitchDelta) < 12
        holdFrames = 2

        let analysisCenter = CGPoint(x: 0.5, y: targetCenterY)
        let centerScore = max(
            0,
            1 - Double(
                min(
                    hypot(centerXOffset, centerYOffset) / 0.18,
                    1
                )
            )
        )
        let heightScore = max(
            0,
            1 - Double(min(abs(subjectHeight - (minimumHeight + maximumHeight) * 0.5) / 0.28, 1))
        )
        let requiredScore = descriptor == nil ? 0 : Double(min((descriptor?.confidence ?? 0) / 0.75, 1))
        let totalScore = (centerScore * 0.42) + (heightScore * 0.28) + (requiredScore * 0.30)

        analysis = FrameAnalysis(
            metrics: FramingMetrics(
                visibleLandmarkCount: visibleLandmarkCount,
                requiredLandmarkRatio: requiredScore,
                centerXOffset: centerXOffset,
                centerYOffset: centerYOffset,
                subjectHeightRatio: subjectHeight,
                targetCenter: analysisCenter,
                subjectCenter: subjectCenter,
                subjectBounds: subjectBounds
            ),
            scores: FrameScoreBreakdown(
                centerScore: centerScore,
                requiredScore: requiredScore,
                coverageScore: heightScore,
                totalScore: totalScore
            )
        )
    }
}
