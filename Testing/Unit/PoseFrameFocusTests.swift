import XCTest
@testable import BoyfriendCamNative

final class PoseFrameFocusTests: XCTestCase {
    func testPreferredSubjectFocusPointPrefersEyesWhenVisible() {
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

    func testPreferredSubjectFocusPointFallsBackToUpperBodyWhenEyesMissing() {
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
