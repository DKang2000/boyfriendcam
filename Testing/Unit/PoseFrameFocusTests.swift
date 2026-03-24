import XCTest
@testable import BoyfriendCamNative

final class PoseFrameFocusTests: XCTestCase {
    func testPreferredSubjectFocusPointPrefersEyesWhenVisible() throws {
        let poseFrame = PoseFrame(
            landmarks: [
                .leftEye: PoseLandmark(x: 0.42, y: 0.28, confidence: 0.92),
                .rightEye: PoseLandmark(x: 0.58, y: 0.28, confidence: 0.93),
                .leftShoulder: PoseLandmark(x: 0.36, y: 0.42, confidence: 0.88),
                .rightShoulder: PoseLandmark(x: 0.64, y: 0.42, confidence: 0.88),
                .leftHip: PoseLandmark(x: 0.42, y: 0.62, confidence: 0.84),
                .rightHip: PoseLandmark(x: 0.58, y: 0.62, confidence: 0.84),
            ],
            timestampSeconds: 1
        )

        let focusPoint = try XCTUnwrap(poseFrame.preferredSubjectFocusPoint())

        XCTAssertEqual(focusPoint.x, 0.50, accuracy: 0.0001)
        XCTAssertEqual(focusPoint.y, 0.28, accuracy: 0.0001)
    }

    func testPreferredSubjectFocusPointFallsBackToUpperBodyWhenEyesMissing() throws {
        let poseFrame = PoseFrame(
            landmarks: [
                .leftShoulder: PoseLandmark(x: 0.38, y: 0.36, confidence: 0.90),
                .rightShoulder: PoseLandmark(x: 0.62, y: 0.36, confidence: 0.91),
                .leftHip: PoseLandmark(x: 0.43, y: 0.58, confidence: 0.84),
                .rightHip: PoseLandmark(x: 0.57, y: 0.58, confidence: 0.84),
            ],
            timestampSeconds: 2
        )

        let focusPoint = try XCTUnwrap(poseFrame.preferredSubjectFocusPoint())

        XCTAssertEqual(focusPoint.x, 0.50, accuracy: 0.0001)
        XCTAssertLessThan(focusPoint.y, 0.36)
        XCTAssertGreaterThan(focusPoint.y, 0.20)
    }
}

final class PoseBodyDescriptorTests: XCTestCase {
    func testAdaptiveBodyDescriptorTracksActualLimbLandmarks() throws {
        let template = ShotTemplateRegistry.template(for: .fullBody)
        let baseline = try XCTUnwrap(
            makeFullBodyFrame(
                leftElbow: CGPoint(x: 0.34, y: 0.47),
                leftWrist: CGPoint(x: 0.30, y: 0.59),
                leftKnee: CGPoint(x: 0.44, y: 0.75),
                leftAnkle: CGPoint(x: 0.43, y: 0.90)
            ).bodyDescriptor(for: template)
        )
        let moved = try XCTUnwrap(
            makeFullBodyFrame(
                leftElbow: CGPoint(x: 0.26, y: 0.40),
                leftWrist: CGPoint(x: 0.20, y: 0.46),
                leftKnee: CGPoint(x: 0.36, y: 0.79),
                leftAnkle: CGPoint(x: 0.31, y: 0.94)
            ).bodyDescriptor(for: template)
        )

        XCTAssertNotEqual(baseline.leftElbow.x, moved.leftElbow.x)
        XCTAssertNotEqual(baseline.leftWrist.y, moved.leftWrist.y)
        XCTAssertNotEqual(baseline.leftKnee.x, moved.leftKnee.x)
        XCTAssertNotEqual(baseline.leftAnkle.x, moved.leftAnkle.x)
    }

    func testPartialPoseStillYieldsAdaptiveOverlayDataForFullBodyTemplate() throws {
        let template = ShotTemplateRegistry.template(for: .fullBody)
        let descriptor = try XCTUnwrap(makePartialUpperBodyFrame().bodyDescriptor(for: template))

        XCTAssertFalse(descriptor.hasLowerBodyAnchors)
        XCTAssertGreaterThan(descriptor.subjectBounds.height, 0.18)
        XCTAssertGreaterThan(descriptor.footY, descriptor.hipCenter.y)
    }

    func testFallbackOnlyOccursWhenPoseIsAbsent() {
        let template = ShotTemplateRegistry.template(for: .fullBody)

        XCTAssertNotNil(makePartialUpperBodyFrame().bodyDescriptor(for: template))
        XCTAssertNil(PoseFrame(landmarks: [:], timestampSeconds: 3).bodyDescriptor(for: template))
    }

    private func makeFullBodyFrame(
        leftElbow: CGPoint,
        leftWrist: CGPoint,
        leftKnee: CGPoint,
        leftAnkle: CGPoint
    ) -> PoseFrame {
        PoseFrame(
            landmarks: [
                .nose: PoseLandmark(x: 0.50, y: 0.20, confidence: 0.94),
                .leftEye: PoseLandmark(x: 0.47, y: 0.18, confidence: 0.90),
                .rightEye: PoseLandmark(x: 0.53, y: 0.18, confidence: 0.90),
                .leftShoulder: PoseLandmark(x: 0.38, y: 0.33, confidence: 0.92),
                .rightShoulder: PoseLandmark(x: 0.62, y: 0.33, confidence: 0.92),
                .leftElbow: PoseLandmark(x: leftElbow.x, y: leftElbow.y, confidence: 0.86),
                .rightElbow: PoseLandmark(x: 0.66, y: 0.46, confidence: 0.86),
                .leftWrist: PoseLandmark(x: leftWrist.x, y: leftWrist.y, confidence: 0.84),
                .rightWrist: PoseLandmark(x: 0.70, y: 0.58, confidence: 0.84),
                .leftHip: PoseLandmark(x: 0.43, y: 0.55, confidence: 0.90),
                .rightHip: PoseLandmark(x: 0.57, y: 0.55, confidence: 0.90),
                .leftKnee: PoseLandmark(x: leftKnee.x, y: leftKnee.y, confidence: 0.82),
                .rightKnee: PoseLandmark(x: 0.58, y: 0.77, confidence: 0.82),
                .leftAnkle: PoseLandmark(x: leftAnkle.x, y: leftAnkle.y, confidence: 0.80),
                .rightAnkle: PoseLandmark(x: 0.58, y: 0.91, confidence: 0.80),
            ],
            timestampSeconds: 1
        )
    }

    private func makePartialUpperBodyFrame() -> PoseFrame {
        PoseFrame(
            landmarks: [
                .nose: PoseLandmark(x: 0.50, y: 0.22, confidence: 0.94),
                .leftEye: PoseLandmark(x: 0.47, y: 0.20, confidence: 0.90),
                .rightEye: PoseLandmark(x: 0.53, y: 0.20, confidence: 0.90),
                .leftShoulder: PoseLandmark(x: 0.39, y: 0.34, confidence: 0.91),
                .rightShoulder: PoseLandmark(x: 0.61, y: 0.34, confidence: 0.91),
                .leftElbow: PoseLandmark(x: 0.35, y: 0.46, confidence: 0.82),
                .rightElbow: PoseLandmark(x: 0.65, y: 0.46, confidence: 0.82),
                .leftWrist: PoseLandmark(x: 0.31, y: 0.57, confidence: 0.78),
                .rightWrist: PoseLandmark(x: 0.69, y: 0.57, confidence: 0.78),
                .leftHip: PoseLandmark(x: 0.44, y: 0.54, confidence: 0.88),
                .rightHip: PoseLandmark(x: 0.56, y: 0.54, confidence: 0.88),
            ],
            timestampSeconds: 2
        )
    }
}

final class PoseRenderDescriptorTests: XCTestCase {
    func testSilhouetteTracksObservedArmAndLegGeometry() throws {
        let template = ShotTemplateRegistry.template(for: .fullBody)
        let baselineDescriptor = try XCTUnwrap(
            makeFullBodyFrame(
                leftShoulder: CGPoint(x: 0.38, y: 0.33),
                rightShoulder: CGPoint(x: 0.62, y: 0.33),
                leftHip: CGPoint(x: 0.43, y: 0.55),
                rightHip: CGPoint(x: 0.57, y: 0.55),
                leftElbow: CGPoint(x: 0.34, y: 0.47),
                leftWrist: CGPoint(x: 0.30, y: 0.59),
                leftKnee: CGPoint(x: 0.44, y: 0.75),
                leftAnkle: CGPoint(x: 0.43, y: 0.90)
            ).renderDescriptor(for: template)
        )
        let movedDescriptor = try XCTUnwrap(
            makeFullBodyFrame(
                leftShoulder: CGPoint(x: 0.34, y: 0.31),
                rightShoulder: CGPoint(x: 0.59, y: 0.36),
                leftHip: CGPoint(x: 0.42, y: 0.58),
                rightHip: CGPoint(x: 0.56, y: 0.53),
                leftElbow: CGPoint(x: 0.23, y: 0.39),
                leftWrist: CGPoint(x: 0.18, y: 0.45),
                leftKnee: CGPoint(x: 0.36, y: 0.79),
                leftAnkle: CGPoint(x: 0.31, y: 0.94)
            ).renderDescriptor(for: template)
        )

        let size = CGSize(width: 1000, height: 1800)
        let baselineSilhouette = LivePoseOverlayRenderer.resolvedSilhouette(
            for: baselineDescriptor,
            in: size,
            isUpsideDown: false
        )
        let movedSilhouette = LivePoseOverlayRenderer.resolvedSilhouette(
            for: movedDescriptor,
            in: size,
            isUpsideDown: false
        )

        XCTAssertNotEqual(baselineSilhouette.leftArm.boundingRect.minX, movedSilhouette.leftArm.boundingRect.minX)
        XCTAssertNotEqual(baselineSilhouette.leftArm.boundingRect.maxY, movedSilhouette.leftArm.boundingRect.maxY)
        XCTAssertNotEqual(baselineSilhouette.leftLeg.boundingRect.minX, movedSilhouette.leftLeg.boundingRect.minX)
        XCTAssertNotEqual(baselineSilhouette.leftLeg.boundingRect.maxY, movedSilhouette.leftLeg.boundingRect.maxY)
        XCTAssertNotEqual(baselineSilhouette.torso.boundingRect.width, movedSilhouette.torso.boundingRect.width)
    }

    func testPartialPoseStillYieldsAdaptiveRenderDescriptorWithoutFakeLegs() throws {
        let template = ShotTemplateRegistry.template(for: .fullBody)
        let descriptor = try XCTUnwrap(makePartialUpperBodyFrame().renderDescriptor(for: template))

        XCTAssertNil(descriptor.leftKnee)
        XCTAssertNil(descriptor.rightKnee)
        XCTAssertNil(descriptor.leftAnkle)
        XCTAssertNil(descriptor.rightAnkle)
        XCTAssertGreaterThan(descriptor.subjectBounds.height, 0.18)
    }

    func testRenderFallbackOnlyOccursWhenPoseIsAbsent() {
        let template = ShotTemplateRegistry.template(for: .fullBody)

        XCTAssertNotNil(makePartialUpperBodyFrame().renderDescriptor(for: template))
        XCTAssertNil(PoseFrame(landmarks: [:], timestampSeconds: 3).renderDescriptor(for: template))
    }

    private func makeFullBodyFrame(
        leftShoulder: CGPoint,
        rightShoulder: CGPoint,
        leftHip: CGPoint,
        rightHip: CGPoint,
        leftElbow: CGPoint,
        leftWrist: CGPoint,
        leftKnee: CGPoint,
        leftAnkle: CGPoint
    ) -> PoseFrame {
        PoseFrame(
            landmarks: [
                .nose: PoseLandmark(x: 0.50, y: 0.20, confidence: 0.94),
                .leftEye: PoseLandmark(x: 0.47, y: 0.18, confidence: 0.90),
                .rightEye: PoseLandmark(x: 0.53, y: 0.18, confidence: 0.90),
                .leftShoulder: PoseLandmark(x: leftShoulder.x, y: leftShoulder.y, confidence: 0.92),
                .rightShoulder: PoseLandmark(x: rightShoulder.x, y: rightShoulder.y, confidence: 0.92),
                .leftElbow: PoseLandmark(x: leftElbow.x, y: leftElbow.y, confidence: 0.86),
                .rightElbow: PoseLandmark(x: 0.66, y: 0.46, confidence: 0.86),
                .leftWrist: PoseLandmark(x: leftWrist.x, y: leftWrist.y, confidence: 0.84),
                .rightWrist: PoseLandmark(x: 0.70, y: 0.58, confidence: 0.84),
                .leftHip: PoseLandmark(x: leftHip.x, y: leftHip.y, confidence: 0.90),
                .rightHip: PoseLandmark(x: rightHip.x, y: rightHip.y, confidence: 0.90),
                .leftKnee: PoseLandmark(x: leftKnee.x, y: leftKnee.y, confidence: 0.82),
                .rightKnee: PoseLandmark(x: 0.58, y: 0.77, confidence: 0.82),
                .leftAnkle: PoseLandmark(x: leftAnkle.x, y: leftAnkle.y, confidence: 0.80),
                .rightAnkle: PoseLandmark(x: 0.58, y: 0.91, confidence: 0.80),
            ],
            timestampSeconds: 1
        )
    }

    private func makePartialUpperBodyFrame() -> PoseFrame {
        PoseFrame(
            landmarks: [
                .nose: PoseLandmark(x: 0.50, y: 0.22, confidence: 0.94),
                .leftEye: PoseLandmark(x: 0.47, y: 0.20, confidence: 0.90),
                .rightEye: PoseLandmark(x: 0.53, y: 0.20, confidence: 0.90),
                .leftShoulder: PoseLandmark(x: 0.39, y: 0.34, confidence: 0.91),
                .rightShoulder: PoseLandmark(x: 0.61, y: 0.34, confidence: 0.91),
                .leftElbow: PoseLandmark(x: 0.35, y: 0.46, confidence: 0.82),
                .rightElbow: PoseLandmark(x: 0.65, y: 0.46, confidence: 0.82),
                .leftWrist: PoseLandmark(x: 0.31, y: 0.57, confidence: 0.78),
                .rightWrist: PoseLandmark(x: 0.69, y: 0.57, confidence: 0.78),
                .leftHip: PoseLandmark(x: 0.44, y: 0.54, confidence: 0.88),
                .rightHip: PoseLandmark(x: 0.56, y: 0.54, confidence: 0.88),
            ],
            timestampSeconds: 2
        )
    }
}
