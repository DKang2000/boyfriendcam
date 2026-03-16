import CoreGraphics

struct PoseFrame: Equatable {
    let landmarks: PoseLandmarks
    let timestampSeconds: Double

    var visibleLandmarkCount: Int {
        landmarks.count
    }
}

struct PoseBodyDescriptor: Equatable {
    let headCenter: CGPoint
    let shoulderCenter: CGPoint
    let hipCenter: CGPoint
    let subjectCenter: CGPoint
    let footY: CGFloat
    let shoulderWidth: CGFloat
    let hipWidth: CGFloat
    let headWidth: CGFloat
    let subjectBounds: CGRect
    let confidence: CGFloat
    let hasLowerBodyAnchors: Bool

    func blended(toward target: PoseBodyDescriptor, factor: CGFloat) -> PoseBodyDescriptor {
        let resolvedFactor = min(max(factor, 0), 1)

        return PoseBodyDescriptor(
            headCenter: interpolated(from: headCenter, to: target.headCenter, factor: resolvedFactor),
            shoulderCenter: interpolated(from: shoulderCenter, to: target.shoulderCenter, factor: resolvedFactor),
            hipCenter: interpolated(from: hipCenter, to: target.hipCenter, factor: resolvedFactor),
            subjectCenter: interpolated(from: subjectCenter, to: target.subjectCenter, factor: resolvedFactor),
            footY: interpolated(from: footY, to: target.footY, factor: resolvedFactor),
            shoulderWidth: interpolated(from: shoulderWidth, to: target.shoulderWidth, factor: resolvedFactor),
            hipWidth: interpolated(from: hipWidth, to: target.hipWidth, factor: resolvedFactor),
            headWidth: interpolated(from: headWidth, to: target.headWidth, factor: resolvedFactor),
            subjectBounds: CGRect(
                x: interpolated(from: subjectBounds.minX, to: target.subjectBounds.minX, factor: resolvedFactor),
                y: interpolated(from: subjectBounds.minY, to: target.subjectBounds.minY, factor: resolvedFactor),
                width: interpolated(from: subjectBounds.width, to: target.subjectBounds.width, factor: resolvedFactor),
                height: interpolated(from: subjectBounds.height, to: target.subjectBounds.height, factor: resolvedFactor)
            ),
            confidence: interpolated(from: confidence, to: target.confidence, factor: resolvedFactor),
            hasLowerBodyAnchors: target.hasLowerBodyAnchors
        )
    }

    private func interpolated(from start: CGFloat, to end: CGFloat, factor: CGFloat) -> CGFloat {
        start + (end - start) * factor
    }

    private func interpolated(from start: CGPoint, to end: CGPoint, factor: CGFloat) -> CGPoint {
        CGPoint(
            x: interpolated(from: start.x, to: end.x, factor: factor),
            y: interpolated(from: start.y, to: end.y, factor: factor)
        )
    }
}

extension PoseFrame {
    func preferredSubjectFocusPoint() -> CGPoint? {
        if let eyeCenter = eyeCenter() {
            return clampedPoint(eyeCenter)
        }

        if let nose = landmarks[.nose] {
            return clampedPoint(CGPoint(x: nose.x, y: nose.y))
        }

        if let coachDescriptor = coachBodyDescriptor() {
            let upperBodyFocusPoint = CGPoint(
                x: coachDescriptor.headCenter.x,
                y: min(max(coachDescriptor.shoulderCenter.y - 0.03, 0), 1)
            )
            return clampedPoint(upperBodyFocusPoint)
        }

        return nil
    }

    func bodyDescriptor(for template: ShotTemplate) -> PoseBodyDescriptor? {
        guard
            let leftShoulder = landmarks[.leftShoulder],
            let rightShoulder = landmarks[.rightShoulder]
        else {
            return nil
        }

        let shoulderCenter = midpoint(leftShoulder, rightShoulder)
        let shoulderWidth = abs(rightShoulder.x - leftShoulder.x)
        let minimumTorsoHeight: CGFloat = template.id == .portrait ? 0.08 : 0.10
        let allowsCroppedTorso = allowsInferredHips(for: template)

        guard shoulderWidth >= 0.08 else {
            return nil
        }

        guard let resolvedHips = resolvedHipPair(
            template: template,
            shoulderCenter: shoulderCenter,
            shoulderWidth: shoulderWidth
        ) else {
            return nil
        }

        let hipCenter = midpoint(resolvedHips.left, resolvedHips.right)
        let hipWidth = abs(resolvedHips.right.x - resolvedHips.left.x)
        let torsoHeight = abs(hipCenter.y - shoulderCenter.y)
        let torsoLean = abs(shoulderCenter.x - hipCenter.x)
        let torsoConfidence = averageConfidence([leftShoulder, rightShoulder] + resolvedHips.confidenceLandmarks)
        let minimumConfidence: CGFloat = allowsCroppedTorso ? 0.34 : 0.45

        guard
            torsoConfidence >= minimumConfidence,
            hipWidth >= 0.05,
            torsoHeight >= minimumTorsoHeight,
            torsoHeight <= 0.62,
            torsoLean <= max(shoulderWidth, hipWidth) * (allowsCroppedTorso ? 0.9 : 0.7)
        else {
            return nil
        }

        let headCenter = resolvedHeadCenter(shoulderCenter: shoulderCenter)
        let eyeSpan = resolvedEyeSpan()
        let headWidth = max(shoulderWidth * 0.52, hipWidth * 0.44, eyeSpan * 2.7, 0.06)
        let topY = max(headCenter.y - headWidth * 0.64, 0)
        let lowerBodyAnchor = resolvedLowerBodyAnchor(hipCenterY: hipCenter.y, torsoHeight: torsoHeight)

        let bottomY: CGFloat
        switch template.id {
        case .portrait:
            bottomY = min(hipCenter.y + torsoHeight * 0.18, 1)
        case .halfBody:
            bottomY = min(hipCenter.y + torsoHeight * 0.58, 1)
        default:
            bottomY = min(max(lowerBodyAnchor.y, hipCenter.y + torsoHeight * 1.1), 1)
        }

        let subjectHeight = max(bottomY - topY, torsoHeight * (template.id == .portrait ? 1.35 : 1.7))
        let bodyWidth = min(max(max(shoulderWidth * 1.18, hipWidth * 1.26), 0.16), 0.76)
        let centerX = clamp((shoulderCenter.x + hipCenter.x) * 0.5)
        let subjectCenter = CGPoint(
            x: centerX,
            y: clamp((headCenter.y + shoulderCenter.y + hipCenter.y) / 3)
        )
        let subjectBounds = CGRect(
            x: clamp(centerX - bodyWidth * 0.5),
            y: topY,
            width: min(bodyWidth, 1),
            height: min(subjectHeight, 1 - topY)
        )

        guard
            subjectBounds.height >= 0.18,
            subjectBounds.maxY <= 1.001,
            subjectBounds.minY >= -0.001
        else {
            return nil
        }

        let lowerBodyConfidence = averageConfidence(lowerBodyAnchor.landmarks)
        let blendedConfidence = torsoConfidence * 0.80 + lowerBodyConfidence * 0.20

        return PoseBodyDescriptor(
            headCenter: headCenter,
            shoulderCenter: shoulderCenter,
            hipCenter: hipCenter,
            subjectCenter: subjectCenter,
            footY: bottomY,
            shoulderWidth: shoulderWidth,
            hipWidth: hipWidth,
            headWidth: headWidth,
            subjectBounds: subjectBounds,
            confidence: blendedConfidence,
            hasLowerBodyAnchors: lowerBodyAnchor.hasAnchors
        )
    }

    func coachBodyDescriptor() -> PoseBodyDescriptor? {
        let coachTemplate = ShotTemplateRegistry.template(for: .halfBody)

        guard
            let leftShoulder = landmarks[.leftShoulder],
            let rightShoulder = landmarks[.rightShoulder],
            let resolvedHips = resolvedHipPair(
                template: coachTemplate,
                shoulderCenter: midpoint(leftShoulder, rightShoulder),
                shoulderWidth: abs(rightShoulder.x - leftShoulder.x)
            )
        else {
            return nil
        }

        let shoulderCenter = midpoint(leftShoulder, rightShoulder)
        let shoulderWidth = abs(rightShoulder.x - leftShoulder.x)
        let hipCenter = midpoint(resolvedHips.left, resolvedHips.right)
        let hipWidth = abs(resolvedHips.right.x - resolvedHips.left.x)
        let torsoHeight = abs(hipCenter.y - shoulderCenter.y)
        let torsoConfidence = averageConfidence([leftShoulder, rightShoulder] + resolvedHips.confidenceLandmarks)

        guard
            shoulderWidth >= 0.08,
            hipWidth >= 0.05,
            torsoHeight >= 0.10,
            torsoHeight <= 0.62,
            torsoConfidence >= 0.34
        else {
            return nil
        }

        let headCenter = resolvedHeadCenter(shoulderCenter: shoulderCenter)
        let eyeSpan = resolvedEyeSpan()
        let headWidth = max(shoulderWidth * 0.52, hipWidth * 0.44, eyeSpan * 2.7, 0.06)
        let topY = max(headCenter.y - headWidth * 0.64, 0)
        let lowerBodyAnchor = resolvedLowerBodyAnchor(hipCenterY: hipCenter.y, torsoHeight: torsoHeight)
        let inferredBottomY = hipCenter.y + torsoHeight * (lowerBodyAnchor.hasAnchors ? 1.10 : 0.88)
        let bottomY = min(max(lowerBodyAnchor.y, inferredBottomY), 1)
        let subjectHeight = max(bottomY - topY, torsoHeight * 1.65)
        let bodyWidth = min(max(max(shoulderWidth * 1.18, hipWidth * 1.26), 0.16), 0.76)
        let centerX = clamp((shoulderCenter.x + hipCenter.x) * 0.5)
        let subjectCenter = CGPoint(
            x: centerX,
            y: clamp((headCenter.y + shoulderCenter.y + hipCenter.y) / 3)
        )
        let subjectBounds = CGRect(
            x: clamp(centerX - bodyWidth * 0.5),
            y: topY,
            width: min(bodyWidth, 1),
            height: min(subjectHeight, 1 - topY)
        )

        guard subjectBounds.height >= 0.18 else {
            return nil
        }

        let lowerBodyConfidence = averageConfidence(lowerBodyAnchor.landmarks)
        let blendedConfidence = torsoConfidence * 0.82 + lowerBodyConfidence * 0.18

        return PoseBodyDescriptor(
            headCenter: headCenter,
            shoulderCenter: shoulderCenter,
            hipCenter: hipCenter,
            subjectCenter: subjectCenter,
            footY: bottomY,
            shoulderWidth: shoulderWidth,
            hipWidth: hipWidth,
            headWidth: headWidth,
            subjectBounds: subjectBounds,
            confidence: blendedConfidence,
            hasLowerBodyAnchors: lowerBodyAnchor.hasAnchors
        )
    }

    func eyeCenter() -> CGPoint? {
        if
            let leftEye = landmarks[.leftEye],
            let rightEye = landmarks[.rightEye]
        {
            return midpoint(leftEye, rightEye)
        }

        return nil
    }

    func eyeSpan() -> CGFloat {
        resolvedEyeSpan()
    }

    private func resolvedHeadCenter(shoulderCenter: CGPoint) -> CGPoint {
        if
            let leftEar = landmarks[.leftEar],
            let rightEar = landmarks[.rightEar]
        {
            return midpoint(leftEar, rightEar)
        }

        if
            let leftEye = landmarks[.leftEye],
            let rightEye = landmarks[.rightEye]
        {
            let center = midpoint(leftEye, rightEye)
            return CGPoint(x: center.x, y: clamp(center.y + distance(leftEye, rightEye) * 0.22))
        }

        if let nose = landmarks[.nose] {
            return CGPoint(x: nose.x, y: clamp(nose.y + 0.01))
        }

        return CGPoint(x: shoulderCenter.x, y: clamp(shoulderCenter.y - 0.16))
    }

    private func resolvedEyeSpan() -> CGFloat {
        if
            let leftEar = landmarks[.leftEar],
            let rightEar = landmarks[.rightEar]
        {
            return distance(leftEar, rightEar)
        }

        if
            let leftEye = landmarks[.leftEye],
            let rightEye = landmarks[.rightEye]
        {
            return distance(leftEye, rightEye)
        }

        return 0
    }

    private func resolvedLowerBodyAnchor(
        hipCenterY: CGFloat,
        torsoHeight: CGFloat
    ) -> (y: CGFloat, landmarks: [PoseLandmark], hasAnchors: Bool) {
        if
            let leftAnkle = landmarks[.leftAnkle] ?? landmarks[.leftHeel],
            let rightAnkle = landmarks[.rightAnkle] ?? landmarks[.rightHeel]
        {
            return (max(leftAnkle.y, rightAnkle.y), [leftAnkle, rightAnkle], true)
        }

        if
            let leftKnee = landmarks[.leftKnee],
            let rightKnee = landmarks[.rightKnee]
        {
            return (max(leftKnee.y, rightKnee.y) + torsoHeight * 0.72, [leftKnee, rightKnee], true)
        }

        if let oneKnee = landmarks[.leftKnee] ?? landmarks[.rightKnee] {
            return (oneKnee.y + torsoHeight * 0.84, [oneKnee], true)
        }

        if let oneAnkle = landmarks[.leftAnkle] ?? landmarks[.rightAnkle] ?? landmarks[.leftHeel] ?? landmarks[.rightHeel] {
            return (oneAnkle.y, [oneAnkle], true)
        }

        let inferredY = max(hipCenterY + torsoHeight * 1.42, 0)
        return (inferredY, [], false)
    }

    private func resolvedHipPair(
        template: ShotTemplate,
        shoulderCenter: CGPoint,
        shoulderWidth: CGFloat
    ) -> (left: PoseLandmark, right: PoseLandmark, confidenceLandmarks: [PoseLandmark])? {
        if
            let leftHip = landmarks[.leftHip],
            let rightHip = landmarks[.rightHip]
        {
            return (leftHip, rightHip, [leftHip, rightHip])
        }

        guard allowsInferredHips(for: template) else {
            return nil
        }

        let inferredTorsoHeight = max(shoulderWidth * 0.92, 0.15)
        let inferredHipWidth = max(shoulderWidth * 0.82, 0.08)
        let defaultY = clamp(shoulderCenter.y + inferredTorsoHeight)

        if let leftHip = landmarks[.leftHip] {
            let mirroredX = clamp(shoulderCenter.x + (shoulderCenter.x - leftHip.x))
            let rightHip = PoseLandmark(x: mirroredX, y: defaultY, confidence: leftHip.confidence)
            return (leftHip, rightHip, [leftHip])
        }

        if let rightHip = landmarks[.rightHip] {
            let mirroredX = clamp(shoulderCenter.x - (rightHip.x - shoulderCenter.x))
            let leftHip = PoseLandmark(x: mirroredX, y: defaultY, confidence: rightHip.confidence)
            return (leftHip, rightHip, [rightHip])
        }

        let leftHip = PoseLandmark(
            x: clamp(shoulderCenter.x - inferredHipWidth * 0.5),
            y: defaultY,
            confidence: averageConfidence([landmarks[.leftShoulder], landmarks[.rightShoulder]].compactMap { $0 })
        )
        let rightHip = PoseLandmark(
            x: clamp(shoulderCenter.x + inferredHipWidth * 0.5),
            y: defaultY,
            confidence: leftHip.confidence
        )
        return (leftHip, rightHip, [])
    }

    private func allowsInferredHips(for template: ShotTemplate) -> Bool {
        switch template.id {
        case .portrait, .halfBody, .ruleOfThirds:
            return true
        case .fullBody, .outfit, .instagramStory:
            return false
        }
    }

    private func midpoint(_ lhs: PoseLandmark, _ rhs: PoseLandmark) -> CGPoint {
        CGPoint(x: (lhs.x + rhs.x) * 0.5, y: (lhs.y + rhs.y) * 0.5)
    }

    private func averageConfidence(_ values: [PoseLandmark]) -> CGFloat {
        guard !values.isEmpty else {
            return 0
        }

        let total = values.reduce(CGFloat.zero) { partialResult, landmark in
            partialResult + landmark.confidence
        }
        return total / CGFloat(values.count)
    }

    private func distance(_ lhs: PoseLandmark, _ rhs: PoseLandmark) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }

    private func clampedPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(x: clamp(point.x), y: clamp(point.y))
    }
}
