import CoreGraphics

enum FrameScoringEngine {
    static func analyze(
        template: ShotTemplate,
        poseFrame: PoseFrame?
    ) -> FrameAnalysis {
        let targetCenter = CGPoint(
            x: template.overlay.targetBox.x + template.overlay.targetBox.width / 2,
            y: template.overlay.targetBox.y + template.overlay.targetBox.height / 2
        )

        guard
            let poseFrame,
            !poseFrame.landmarks.isEmpty,
            let descriptor = poseFrame.bodyDescriptor(for: template)
        else {
            return FrameAnalysis(
                metrics: FramingMetrics(
                    visibleLandmarkCount: 0,
                    requiredLandmarkRatio: 0,
                    centerXOffset: 0,
                    centerYOffset: 0,
                    subjectHeightRatio: 0,
                    targetCenter: targetCenter,
                    subjectCenter: nil,
                    subjectBounds: nil
                ),
                scores: FrameScoreBreakdown(
                    centerScore: 0,
                    requiredScore: 0,
                    coverageScore: 0,
                    totalScore: 0
                )
            )
        }

        let bounds = subjectBounds(for: descriptor, template: template)
        let subjectCenter = subjectCenter(for: descriptor, template: template)
        let centerXOffset = subjectCenter.x - targetCenter.x
        let centerYOffset = subjectCenter.y - targetCenter.y
        let requiredRatio = requiredLandmarkRatio(
            requiredLandmarks: template.scoring.requiredLandmarks,
            landmarks: poseFrame.landmarks
        )
        let subjectHeightRatio = bounds.height / max(template.overlay.targetBox.height, 0.0001)

        let centerScore = axisScore(
            offset: centerXOffset,
            tolerance: template.scoring.horizontalTolerance
        ) * 0.5 + axisScore(
            offset: centerYOffset,
            tolerance: template.scoring.verticalTolerance
        ) * 0.5
        let requiredScore =
            isMissingCriticalLowerBodyLandmarks(template: template, landmarks: poseFrame.landmarks)
            ? 0
            : requiredRatio
        let coverageScore = coverageScore(
            template: template,
            visibleLandmarkCount: poseFrame.visibleLandmarkCount,
            subjectHeightRatio: subjectHeightRatio
        )
        let totalScore =
            centerScore * template.scoring.centerWeight +
            requiredScore * template.scoring.requiredWeight +
            coverageScore * template.scoring.coverageWeight

        return FrameAnalysis(
            metrics: FramingMetrics(
                visibleLandmarkCount: poseFrame.visibleLandmarkCount,
                requiredLandmarkRatio: requiredRatio,
                centerXOffset: centerXOffset,
                centerYOffset: centerYOffset,
                subjectHeightRatio: subjectHeightRatio,
                targetCenter: targetCenter,
                subjectCenter: subjectCenter,
                subjectBounds: bounds
            ),
            scores: FrameScoreBreakdown(
                centerScore: centerScore,
                requiredScore: requiredScore,
                coverageScore: coverageScore,
                totalScore: totalScore
            )
        )
    }

    private static func subjectBounds(
        for descriptor: PoseBodyDescriptor,
        template: ShotTemplate
    ) -> CGRect {
        let torsoHeight = abs(descriptor.hipCenter.y - descriptor.shoulderCenter.y)
        let topY = descriptor.subjectBounds.minY
        let width = descriptor.subjectBounds.width
        let centerX = descriptor.subjectBounds.midX

        let bottomY: CGFloat
        switch template.id {
        case .portrait:
            bottomY = min(descriptor.hipCenter.y + torsoHeight * 0.18, descriptor.subjectBounds.maxY)
        case .halfBody:
            bottomY = min(descriptor.hipCenter.y + torsoHeight * 0.55, descriptor.subjectBounds.maxY)
        default:
            bottomY = descriptor.subjectBounds.maxY
        }

        return CGRect(
            x: centerX - width * 0.5,
            y: topY,
            width: width,
            height: max(bottomY - topY, torsoHeight)
        )
    }

    private static func subjectCenter(
        for descriptor: PoseBodyDescriptor,
        template: ShotTemplate
    ) -> CGPoint {
        switch template.id {
        case .portrait, .halfBody:
            return CGPoint(
                x: descriptor.subjectCenter.x,
                y: (descriptor.headCenter.y + descriptor.shoulderCenter.y + descriptor.hipCenter.y) / 3
            )
        default:
            return CGPoint(
                x: descriptor.subjectBounds.midX,
                y: descriptor.subjectBounds.midY
            )
        }
    }

    private static func isMissingCriticalLowerBodyLandmarks(
        template: ShotTemplate,
        landmarks: PoseLandmarks
    ) -> Bool {
        let criticalLowerBodyLandmarks = template.scoring.requiredLandmarks.filter(isLowerBodyLandmark)

        guard !criticalLowerBodyLandmarks.isEmpty else {
            return false
        }

        return !criticalLowerBodyLandmarks.allSatisfy { landmarks[$0] != nil }
    }

    private static func isLowerBodyLandmark(_ landmark: PoseLandmarkName) -> Bool {
        switch landmark {
        case .leftHip,
                .rightHip,
                .leftKnee,
                .rightKnee,
                .leftAnkle,
                .rightAnkle,
                .leftHeel,
                .rightHeel,
                .leftFootIndex,
                .rightFootIndex:
            return true
        default:
            return false
        }
    }

    private static func axisScore(offset: CGFloat, tolerance: CGFloat) -> Double {
        let normalizedDelta = min(abs(offset) / max(tolerance, 0.0001), 1)
        return max(0, 1 - Double(normalizedDelta))
    }

    private static func coverageScore(
        template: ShotTemplate,
        visibleLandmarkCount: Int,
        subjectHeightRatio: CGFloat
    ) -> Double {
        let expectedRatio: CGFloat = 1
        let heightDelta = abs(subjectHeightRatio - expectedRatio)
        let heightScore = max(
            0,
            1 - Double(min(heightDelta / max(template.scoring.scaleTolerance, 0.0001), 1))
        )
        let densityScore = min(
            Double(visibleLandmarkCount) / Double(max(template.scoring.minVisibleLandmarks, 1)),
            1
        )

        return heightScore * 0.6 + densityScore * 0.4
    }

    private static func requiredLandmarkRatio(
        requiredLandmarks: [PoseLandmarkName],
        landmarks: PoseLandmarks
    ) -> Double {
        guard !requiredLandmarks.isEmpty else {
            return 1
        }

        let hits = requiredLandmarks.filter { landmarks[$0] != nil }.count
        return Double(hits) / Double(requiredLandmarks.count)
    }

}
