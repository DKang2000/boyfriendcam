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
    let leftShoulder: CGPoint
    let rightShoulder: CGPoint
    let leftElbow: CGPoint
    let rightElbow: CGPoint
    let leftWrist: CGPoint
    let rightWrist: CGPoint
    let leftHip: CGPoint
    let rightHip: CGPoint
    let leftKnee: CGPoint
    let rightKnee: CGPoint
    let leftAnkle: CGPoint
    let rightAnkle: CGPoint

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
            hasLowerBodyAnchors: target.hasLowerBodyAnchors,
            leftShoulder: interpolated(from: leftShoulder, to: target.leftShoulder, factor: resolvedFactor),
            rightShoulder: interpolated(from: rightShoulder, to: target.rightShoulder, factor: resolvedFactor),
            leftElbow: interpolated(from: leftElbow, to: target.leftElbow, factor: resolvedFactor),
            rightElbow: interpolated(from: rightElbow, to: target.rightElbow, factor: resolvedFactor),
            leftWrist: interpolated(from: leftWrist, to: target.leftWrist, factor: resolvedFactor),
            rightWrist: interpolated(from: rightWrist, to: target.rightWrist, factor: resolvedFactor),
            leftHip: interpolated(from: leftHip, to: target.leftHip, factor: resolvedFactor),
            rightHip: interpolated(from: rightHip, to: target.rightHip, factor: resolvedFactor),
            leftKnee: interpolated(from: leftKnee, to: target.leftKnee, factor: resolvedFactor),
            rightKnee: interpolated(from: rightKnee, to: target.rightKnee, factor: resolvedFactor),
            leftAnkle: interpolated(from: leftAnkle, to: target.leftAnkle, factor: resolvedFactor),
            rightAnkle: interpolated(from: rightAnkle, to: target.rightAnkle, factor: resolvedFactor)
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

struct PoseTrackedJoint: Equatable {
    let point: CGPoint
    let isObserved: Bool

    func blended(toward target: PoseTrackedJoint, factor: CGFloat) -> PoseTrackedJoint {
        let resolvedFactor = min(max(factor, 0), 1)
        return PoseTrackedJoint(
            point: CGPoint(
                x: point.x + (target.point.x - point.x) * resolvedFactor,
                y: point.y + (target.point.y - point.y) * resolvedFactor
            ),
            isObserved: target.isObserved
        )
    }
}

struct PoseRenderDescriptor: Equatable {
    let headCenter: PoseTrackedJoint
    let headSize: CGSize
    let shoulderCenter: CGPoint
    let hipCenter: CGPoint
    let subjectCenter: CGPoint
    let subjectBounds: CGRect
    let confidence: CGFloat
    let visibleLandmarkCount: Int
    let hasLowerBodyAnchors: Bool
    let leftShoulder: PoseTrackedJoint
    let rightShoulder: PoseTrackedJoint
    let leftHip: PoseTrackedJoint
    let rightHip: PoseTrackedJoint
    let leftElbow: PoseTrackedJoint?
    let rightElbow: PoseTrackedJoint?
    let leftWrist: PoseTrackedJoint?
    let rightWrist: PoseTrackedJoint?
    let leftKnee: PoseTrackedJoint?
    let rightKnee: PoseTrackedJoint?
    let leftAnkle: PoseTrackedJoint?
    let rightAnkle: PoseTrackedJoint?

    func blended(toward target: PoseRenderDescriptor, factor: CGFloat) -> PoseRenderDescriptor {
        let resolvedFactor = min(max(factor, 0), 1)

        return PoseRenderDescriptor(
            headCenter: headCenter.blended(toward: target.headCenter, factor: resolvedFactor),
            headSize: CGSize(
                width: headSize.width + (target.headSize.width - headSize.width) * resolvedFactor,
                height: headSize.height + (target.headSize.height - headSize.height) * resolvedFactor
            ),
            shoulderCenter: interpolated(from: shoulderCenter, to: target.shoulderCenter, factor: resolvedFactor),
            hipCenter: interpolated(from: hipCenter, to: target.hipCenter, factor: resolvedFactor),
            subjectCenter: interpolated(from: subjectCenter, to: target.subjectCenter, factor: resolvedFactor),
            subjectBounds: CGRect(
                x: subjectBounds.minX + (target.subjectBounds.minX - subjectBounds.minX) * resolvedFactor,
                y: subjectBounds.minY + (target.subjectBounds.minY - subjectBounds.minY) * resolvedFactor,
                width: subjectBounds.width + (target.subjectBounds.width - subjectBounds.width) * resolvedFactor,
                height: subjectBounds.height + (target.subjectBounds.height - subjectBounds.height) * resolvedFactor
            ),
            confidence: confidence + (target.confidence - confidence) * resolvedFactor,
            visibleLandmarkCount: target.visibleLandmarkCount,
            hasLowerBodyAnchors: target.hasLowerBodyAnchors,
            leftShoulder: leftShoulder.blended(toward: target.leftShoulder, factor: resolvedFactor),
            rightShoulder: rightShoulder.blended(toward: target.rightShoulder, factor: resolvedFactor),
            leftHip: leftHip.blended(toward: target.leftHip, factor: resolvedFactor),
            rightHip: rightHip.blended(toward: target.rightHip, factor: resolvedFactor),
            leftElbow: blended(leftElbow, toward: target.leftElbow, factor: resolvedFactor),
            rightElbow: blended(rightElbow, toward: target.rightElbow, factor: resolvedFactor),
            leftWrist: blended(leftWrist, toward: target.leftWrist, factor: resolvedFactor),
            rightWrist: blended(rightWrist, toward: target.rightWrist, factor: resolvedFactor),
            leftKnee: blended(leftKnee, toward: target.leftKnee, factor: resolvedFactor),
            rightKnee: blended(rightKnee, toward: target.rightKnee, factor: resolvedFactor),
            leftAnkle: blended(leftAnkle, toward: target.leftAnkle, factor: resolvedFactor),
            rightAnkle: blended(rightAnkle, toward: target.rightAnkle, factor: resolvedFactor)
        )
    }

    private func blended(
        _ source: PoseTrackedJoint?,
        toward target: PoseTrackedJoint?,
        factor: CGFloat
    ) -> PoseTrackedJoint? {
        switch (source, target) {
        case let (source?, target?):
            return source.blended(toward: target, factor: factor)
        case (_, let target?):
            return target
        default:
            return nil
        }
    }

    private func interpolated(from start: CGPoint, to end: CGPoint, factor: CGFloat) -> CGPoint {
        CGPoint(
            x: start.x + (end.x - start.x) * factor,
            y: start.y + (end.y - start.y) * factor
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
        adaptiveBodyDescriptor()
    }

    func coachBodyDescriptor() -> PoseBodyDescriptor? {
        adaptiveBodyDescriptor()
    }

    func renderDescriptor(for template: ShotTemplate) -> PoseRenderDescriptor? {
        adaptiveRenderDescriptor()
    }

    func coachRenderDescriptor() -> PoseRenderDescriptor? {
        adaptiveRenderDescriptor()
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

    private func adaptiveRenderDescriptor() -> PoseRenderDescriptor? {
        guard let bodyDescriptor = adaptiveBodyDescriptor() else {
            return nil
        }

        let headSize = CGSize(
            width: max(bodyDescriptor.headWidth, 0.05),
            height: max(bodyDescriptor.headWidth * 1.24, 0.07)
        )

        return PoseRenderDescriptor(
            headCenter: PoseTrackedJoint(
                point: bodyDescriptor.headCenter,
                isObserved: landmarks[.leftEar] != nil
                    || landmarks[.rightEar] != nil
                    || landmarks[.leftEye] != nil
                    || landmarks[.rightEye] != nil
                    || landmarks[.nose] != nil
            ),
            headSize: headSize,
            shoulderCenter: bodyDescriptor.shoulderCenter,
            hipCenter: bodyDescriptor.hipCenter,
            subjectCenter: bodyDescriptor.subjectCenter,
            subjectBounds: bodyDescriptor.subjectBounds,
            confidence: bodyDescriptor.confidence,
            visibleLandmarkCount: visibleLandmarkCount,
            hasLowerBodyAnchors: bodyDescriptor.hasLowerBodyAnchors,
            leftShoulder: PoseTrackedJoint(
                point: bodyDescriptor.leftShoulder,
                isObserved: landmarks[.leftShoulder] != nil
            ),
            rightShoulder: PoseTrackedJoint(
                point: bodyDescriptor.rightShoulder,
                isObserved: landmarks[.rightShoulder] != nil
            ),
            leftHip: PoseTrackedJoint(
                point: bodyDescriptor.leftHip,
                isObserved: landmarks[.leftHip] != nil
            ),
            rightHip: PoseTrackedJoint(
                point: bodyDescriptor.rightHip,
                isObserved: landmarks[.rightHip] != nil
            ),
            leftElbow: trackedJoint(
                landmarkNames: [.leftElbow]
            ),
            rightElbow: trackedJoint(
                landmarkNames: [.rightElbow]
            ),
            leftWrist: trackedJoint(
                landmarkNames: [.leftWrist, .leftIndex, .leftPinky, .leftThumb]
            ),
            rightWrist: trackedJoint(
                landmarkNames: [.rightWrist, .rightIndex, .rightPinky, .rightThumb]
            ),
            leftKnee: trackedJoint(
                landmarkNames: [.leftKnee]
            ),
            rightKnee: trackedJoint(
                landmarkNames: [.rightKnee]
            ),
            leftAnkle: trackedJoint(
                landmarkNames: [.leftAnkle, .leftHeel, .leftFootIndex]
            ),
            rightAnkle: trackedJoint(
                landmarkNames: [.rightAnkle, .rightHeel, .rightFootIndex]
            )
        )
    }

    private func adaptiveBodyDescriptor() -> PoseBodyDescriptor? {
        guard
            let leftShoulderLandmark = landmarks[.leftShoulder],
            let rightShoulderLandmark = landmarks[.rightShoulder]
        else {
            return nil
        }

        let leftShoulder = point(from: leftShoulderLandmark)
        let rightShoulder = point(from: rightShoulderLandmark)
        let shoulderCenter = midpoint(leftShoulder, rightShoulder)
        let shoulderWidth = distance(leftShoulder, rightShoulder)

        guard shoulderWidth >= 0.06 else {
            return nil
        }

        let resolvedHips = resolvedHipPair(
            shoulderCenter: shoulderCenter,
            shoulderWidth: shoulderWidth
        )
        let leftHip = point(from: resolvedHips.left)
        let rightHip = point(from: resolvedHips.right)
        let hipCenter = midpoint(leftHip, rightHip)
        let hipWidth = max(distance(leftHip, rightHip), shoulderWidth * 0.62)
        let torsoHeight = max(abs(hipCenter.y - shoulderCenter.y), shoulderWidth * 0.78)
        let torsoLean = abs(shoulderCenter.x - hipCenter.x)
        let torsoConfidence = averageConfidence([leftShoulderLandmark, rightShoulderLandmark] + resolvedHips.confidenceLandmarks)

        guard
            hipWidth >= 0.04,
            torsoHeight >= 0.08,
            torsoHeight <= 0.72,
            torsoConfidence >= 0.20,
            torsoLean <= max(shoulderWidth, hipWidth) * 1.05
        else {
            return nil
        }

        let headCenter = resolvedHeadCenter(shoulderCenter: shoulderCenter)
        let headWidth = max(shoulderWidth * 0.52, hipWidth * 0.44, resolvedEyeSpan() * 2.7, 0.06)
        let leftArm = resolvedArm(
            side: .left,
            shoulder: leftShoulder,
            shoulderWidth: shoulderWidth,
            torsoHeight: torsoHeight
        )
        let rightArm = resolvedArm(
            side: .right,
            shoulder: rightShoulder,
            shoulderWidth: shoulderWidth,
            torsoHeight: torsoHeight
        )
        let leftLeg = resolvedLeg(
            side: .left,
            hip: leftHip,
            hipWidth: hipWidth,
            torsoHeight: torsoHeight
        )
        let rightLeg = resolvedLeg(
            side: .right,
            hip: rightHip,
            hipWidth: hipWidth,
            torsoHeight: torsoHeight
        )

        let topY = max(headCenter.y - headWidth * 0.64, 0)
        let inferredFootY = hipCenter.y + torsoHeight * 1.36
        let bottomY = min(
            max(
                leftLeg.ankle.y,
                rightLeg.ankle.y,
                inferredFootY
            ),
            1
        )

        let rawMinX = min(
            headCenter.x - headWidth * 0.52,
            leftShoulder.x,
            rightShoulder.x,
            leftHip.x,
            rightHip.x,
            leftLeg.knee.x,
            rightLeg.knee.x,
            leftLeg.ankle.x,
            rightLeg.ankle.x
        )
        let rawMaxX = max(
            headCenter.x + headWidth * 0.52,
            leftShoulder.x,
            rightShoulder.x,
            leftHip.x,
            rightHip.x,
            leftLeg.knee.x,
            rightLeg.knee.x,
            leftLeg.ankle.x,
            rightLeg.ankle.x
        )
        let horizontalPadding = max(shoulderWidth * 0.14, hipWidth * 0.10, 0.04)
        let minX = clamp(rawMinX - horizontalPadding)
        let maxX = clamp(rawMaxX + horizontalPadding)
        let subjectHeight = min(max(bottomY - topY, torsoHeight * 1.35), 1 - topY)
        let subjectWidth = min(max(maxX - minX, 0.14), 1 - minX)
        let subjectBounds = CGRect(
            x: minX,
            y: topY,
            width: subjectWidth,
            height: subjectHeight
        )

        guard subjectBounds.height >= 0.18 else {
            return nil
        }

        let subjectCenter = CGPoint(
            x: clamp((headCenter.x + shoulderCenter.x + hipCenter.x) / 3),
            y: clamp((headCenter.y + shoulderCenter.y + hipCenter.y) / 3)
        )
        let lowerBodyConfidenceLandmarks = leftLeg.confidenceLandmarks + rightLeg.confidenceLandmarks
        let actualConfidenceLandmarks =
            [leftShoulderLandmark, rightShoulderLandmark] +
            resolvedHips.confidenceLandmarks +
            leftArm.confidenceLandmarks +
            rightArm.confidenceLandmarks +
            lowerBodyConfidenceLandmarks
        let actualCoverage = CGFloat(actualConfidenceLandmarks.count) / 12
        let blendedConfidence = min(
            1,
            averageConfidence(actualConfidenceLandmarks) * 0.78 + actualCoverage * 0.22
        )

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
            hasLowerBodyAnchors: !lowerBodyConfidenceLandmarks.isEmpty,
            leftShoulder: leftShoulder,
            rightShoulder: rightShoulder,
            leftElbow: leftArm.elbow,
            rightElbow: rightArm.elbow,
            leftWrist: leftArm.wrist,
            rightWrist: rightArm.wrist,
            leftHip: leftHip,
            rightHip: rightHip,
            leftKnee: leftLeg.knee,
            rightKnee: rightLeg.knee,
            leftAnkle: leftLeg.ankle,
            rightAnkle: rightLeg.ankle
        )
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

    private func resolvedHipPair(
        shoulderCenter: CGPoint,
        shoulderWidth: CGFloat
    ) -> (left: PoseLandmark, right: PoseLandmark, confidenceLandmarks: [PoseLandmark]) {
        if
            let leftHip = landmarks[.leftHip],
            let rightHip = landmarks[.rightHip]
        {
            return (leftHip, rightHip, [leftHip, rightHip])
        }

        let inferredTorsoHeight = max(shoulderWidth * 0.92, 0.15)
        let inferredHipWidth = max(shoulderWidth * 0.82, 0.08)
        let defaultY = clamp(shoulderCenter.y + inferredTorsoHeight)

        if let leftHip = landmarks[.leftHip] {
            let mirroredX = clamp(shoulderCenter.x + (shoulderCenter.x - leftHip.x))
            let rightHip = PoseLandmark(x: mirroredX, y: leftHip.y, confidence: leftHip.confidence * 0.88)
            return (leftHip, rightHip, [leftHip])
        }

        if let rightHip = landmarks[.rightHip] {
            let mirroredX = clamp(shoulderCenter.x - (rightHip.x - shoulderCenter.x))
            let leftHip = PoseLandmark(x: mirroredX, y: rightHip.y, confidence: rightHip.confidence * 0.88)
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

    private func resolvedArm(
        side: PoseSide,
        shoulder: CGPoint,
        shoulderWidth: CGFloat,
        torsoHeight: CGFloat
    ) -> (elbow: CGPoint, wrist: CGPoint, confidenceLandmarks: [PoseLandmark]) {
        let elbowLandmark = landmarks[side.elbow]
        let wristLandmark = landmarks[side.wrist]
            ?? landmarks[side.index]
            ?? landmarks[side.pinky]
            ?? landmarks[side.thumb]
        let lateralDirection: CGFloat = side == .left ? -1 : 1
        let defaultElbow = CGPoint(
            x: clamp(shoulder.x + shoulderWidth * 0.26 * lateralDirection),
            y: clamp(shoulder.y + torsoHeight * 0.54)
        )
        let defaultWrist = CGPoint(
            x: clamp(shoulder.x + shoulderWidth * 0.32 * lateralDirection),
            y: clamp(shoulder.y + torsoHeight * 0.94)
        )

        let elbow: CGPoint
        let wrist: CGPoint

        switch (elbowLandmark, wristLandmark) {
        case let (elbowLandmark?, wristLandmark?):
            elbow = point(from: elbowLandmark)
            wrist = point(from: wristLandmark)
        case let (elbowLandmark?, nil):
            elbow = point(from: elbowLandmark)
            let shoulderToElbow = CGPoint(x: elbow.x - shoulder.x, y: elbow.y - shoulder.y)
            wrist = clampedPoint(
                CGPoint(
                    x: elbow.x + shoulderToElbow.x * 0.88,
                    y: elbow.y + shoulderToElbow.y * 0.88
                )
            )
        case let (nil, wristLandmark?):
            wrist = point(from: wristLandmark)
            elbow = clampedPoint(
                CGPoint(
                    x: shoulder.x + (wrist.x - shoulder.x) * 0.54,
                    y: shoulder.y + (wrist.y - shoulder.y) * 0.54
                )
            )
        case (nil, nil):
            elbow = defaultElbow
            wrist = defaultWrist
        }

        return (elbow, wrist, [elbowLandmark, wristLandmark].compactMap { $0 })
    }

    private func resolvedLeg(
        side: PoseSide,
        hip: CGPoint,
        hipWidth: CGFloat,
        torsoHeight: CGFloat
    ) -> (knee: CGPoint, ankle: CGPoint, confidenceLandmarks: [PoseLandmark]) {
        let kneeLandmark = landmarks[side.knee]
        let ankleLandmark = landmarks[side.ankle]
            ?? landmarks[side.heel]
            ?? landmarks[side.footIndex]
        let lateralDirection: CGFloat = side == .left ? -1 : 1
        let defaultKnee = CGPoint(
            x: clamp(hip.x + hipWidth * 0.08 * lateralDirection),
            y: clamp(hip.y + torsoHeight * 0.90)
        )
        let defaultAnkle = CGPoint(
            x: clamp(hip.x + hipWidth * 0.12 * lateralDirection),
            y: clamp(hip.y + torsoHeight * 1.68)
        )

        let knee: CGPoint
        let ankle: CGPoint

        switch (kneeLandmark, ankleLandmark) {
        case let (kneeLandmark?, ankleLandmark?):
            knee = point(from: kneeLandmark)
            ankle = point(from: ankleLandmark)
        case let (kneeLandmark?, nil):
            knee = point(from: kneeLandmark)
            let hipToKnee = CGPoint(x: knee.x - hip.x, y: knee.y - hip.y)
            ankle = clampedPoint(
                CGPoint(
                    x: knee.x + hipToKnee.x * 0.78,
                    y: max(knee.y + torsoHeight * 0.58, knee.y + hipToKnee.y * 0.78)
                )
            )
        case let (nil, ankleLandmark?):
            ankle = point(from: ankleLandmark)
            knee = clampedPoint(
                CGPoint(
                    x: hip.x + (ankle.x - hip.x) * 0.52,
                    y: hip.y + (ankle.y - hip.y) * 0.50
                )
            )
        case (nil, nil):
            knee = defaultKnee
            ankle = defaultAnkle
        }

        return (knee, ankle, [kneeLandmark, ankleLandmark].compactMap { $0 })
    }

    private func midpoint(_ lhs: PoseLandmark, _ rhs: PoseLandmark) -> CGPoint {
        CGPoint(x: (lhs.x + rhs.x) * 0.5, y: (lhs.y + rhs.y) * 0.5)
    }

    private func midpoint(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
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

    private func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    private func point(from landmark: PoseLandmark) -> CGPoint {
        CGPoint(x: landmark.x, y: landmark.y)
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }

    private func clampedPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(x: clamp(point.x), y: clamp(point.y))
    }

    private func trackedJoint(landmarkNames: [PoseLandmarkName]) -> PoseTrackedJoint? {
        for landmarkName in landmarkNames {
            if let landmark = landmarks[landmarkName] {
                return PoseTrackedJoint(point: point(from: landmark), isObserved: true)
            }
        }

        return nil
    }
}

private enum PoseSide {
    case left
    case right

    var elbow: PoseLandmarkName {
        switch self {
        case .left:
            return .leftElbow
        case .right:
            return .rightElbow
        }
    }

    var wrist: PoseLandmarkName {
        switch self {
        case .left:
            return .leftWrist
        case .right:
            return .rightWrist
        }
    }

    var thumb: PoseLandmarkName {
        switch self {
        case .left:
            return .leftThumb
        case .right:
            return .rightThumb
        }
    }

    var index: PoseLandmarkName {
        switch self {
        case .left:
            return .leftIndex
        case .right:
            return .rightIndex
        }
    }

    var pinky: PoseLandmarkName {
        switch self {
        case .left:
            return .leftPinky
        case .right:
            return .rightPinky
        }
    }

    var knee: PoseLandmarkName {
        switch self {
        case .left:
            return .leftKnee
        case .right:
            return .rightKnee
        }
    }

    var ankle: PoseLandmarkName {
        switch self {
        case .left:
            return .leftAnkle
        case .right:
            return .rightAnkle
        }
    }

    var heel: PoseLandmarkName {
        switch self {
        case .left:
            return .leftHeel
        case .right:
            return .rightHeel
        }
    }

    var footIndex: PoseLandmarkName {
        switch self {
        case .left:
            return .leftFootIndex
        case .right:
            return .rightFootIndex
        }
    }
}
