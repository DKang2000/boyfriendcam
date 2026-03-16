import CoreGraphics

struct PromptSelectionState: Equatable {
    var smoothedScore: Double?
    var isReady = false
    var displayedFramingSignal: FramingPromptSignal = .findSubject
    var pendingFramingSignal: FramingPromptSignal?
    var pendingFramingFrames = 0
    var displayedPhoneTiltSignal: PhoneTiltPromptSignal?
    var pendingPhoneTiltSignal: PhoneTiltPromptSignal?
    var pendingPhoneTiltFrames = 0
}

enum PromptSelectionEngine {
    static func nextState(
        previousState: PromptSelectionState,
        analysis: FrameAnalysis,
        template: ShotTemplate,
        phoneTiltSignal: PhoneTiltPromptSignal?
    ) -> PromptSelectionState {
        var nextState = previousState
        let alpha = template.scoring.smoothingAlpha
        let previousSmoothedScore = previousState.smoothedScore ?? analysis.scores.totalScore
        let smoothedScore = previousSmoothedScore + (analysis.scores.totalScore - previousSmoothedScore) * alpha
        nextState.smoothedScore = smoothedScore

        if previousState.isReady {
            nextState.isReady = smoothedScore >= template.scoring.readyExitThreshold
        } else {
            nextState.isReady = smoothedScore >= template.readyThreshold
        }

        let framingCandidate = framingCandidate(
            analysis: analysis,
            template: template,
            isReady: nextState.isReady
        )
        nextState = updateFramingSignal(
            currentState: nextState,
            candidate: framingCandidate,
            holdFrames: template.scoring.promptHoldFrames
        )
        nextState = updatePhoneTiltSignal(
            currentState: nextState,
            candidate: phoneTiltSignal,
            holdFrames: template.scoring.promptHoldFrames
        )

        return nextState
    }

    static func framingCandidate(
        analysis: FrameAnalysis,
        template: ShotTemplate,
        isReady: Bool
    ) -> FramingPromptSignal {
        if analysis.metrics.visibleLandmarkCount == 0 {
            return .findSubject
        }

        if isReady {
            return .ready
        }

        var movementCandidates: [(FramingPromptSignal, Double)] = []
        let horizontalTolerance = template.scoring.horizontalTolerance
        let verticalTolerance = template.scoring.verticalTolerance
        let scaleTolerance = template.scoring.scaleTolerance

        if analysis.metrics.subjectHeightRatio > 1 + scaleTolerance {
            movementCandidates.append((
                .moveBack,
                Double((analysis.metrics.subjectHeightRatio - (1 + scaleTolerance)) / scaleTolerance)
            ))
        } else if analysis.metrics.subjectHeightRatio < 1 - scaleTolerance {
            movementCandidates.append((
                .moveCloser,
                Double(((1 - scaleTolerance) - analysis.metrics.subjectHeightRatio) / scaleTolerance)
            ))
        }

        if analysis.metrics.centerXOffset < -horizontalTolerance {
            movementCandidates.append((
                .moveLeft,
                Double(abs(analysis.metrics.centerXOffset) - horizontalTolerance) / Double(horizontalTolerance)
            ))
        } else if analysis.metrics.centerXOffset > horizontalTolerance {
            movementCandidates.append((
                .moveRight,
                Double(analysis.metrics.centerXOffset - horizontalTolerance) / Double(horizontalTolerance)
            ))
        }

        if analysis.metrics.centerYOffset < -verticalTolerance {
            movementCandidates.append((
                .raiseCamera,
                Double(abs(analysis.metrics.centerYOffset) - verticalTolerance) / Double(verticalTolerance)
            ))
        } else if analysis.metrics.centerYOffset > verticalTolerance {
            movementCandidates.append((
                .lowerCamera,
                Double(analysis.metrics.centerYOffset - verticalTolerance) / Double(verticalTolerance)
            ))
        }

        if let strongestMovement = movementCandidates.max(by: { $0.1 < $1.1 }) {
            return strongestMovement.0
        }

        if analysis.metrics.requiredLandmarkRatio < 0.85 {
            return .fitSubject
        }

        return .adjustFraming
    }

    private static func updateFramingSignal(
        currentState: PromptSelectionState,
        candidate: FramingPromptSignal,
        holdFrames: Int
    ) -> PromptSelectionState {
        var nextState = currentState

        if currentState.displayedFramingSignal == candidate {
            nextState.pendingFramingSignal = nil
            nextState.pendingFramingFrames = 0
            return nextState
        }

        if currentState.pendingFramingSignal == candidate {
            nextState.pendingFramingFrames += 1
        } else {
            nextState.pendingFramingSignal = candidate
            nextState.pendingFramingFrames = 1
        }

        if nextState.pendingFramingFrames >= max(holdFrames, 1) {
            nextState.displayedFramingSignal = candidate
            nextState.pendingFramingSignal = nil
            nextState.pendingFramingFrames = 0
        }

        return nextState
    }

    private static func updatePhoneTiltSignal(
        currentState: PromptSelectionState,
        candidate: PhoneTiltPromptSignal?,
        holdFrames: Int
    ) -> PromptSelectionState {
        var nextState = currentState

        if currentState.displayedPhoneTiltSignal == candidate {
            nextState.pendingPhoneTiltSignal = nil
            nextState.pendingPhoneTiltFrames = 0
            return nextState
        }

        if currentState.pendingPhoneTiltSignal == candidate {
            nextState.pendingPhoneTiltFrames += 1
        } else {
            nextState.pendingPhoneTiltSignal = candidate
            nextState.pendingPhoneTiltFrames = 1
        }

        if nextState.pendingPhoneTiltFrames >= max(holdFrames, 1) {
            nextState.displayedPhoneTiltSignal = candidate
            nextState.pendingPhoneTiltSignal = nil
            nextState.pendingPhoneTiltFrames = 0
        }

        return nextState
    }
}
