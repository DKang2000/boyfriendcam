import XCTest
@testable import BoyfriendCamNative

final class PoseFrameMapperTests: XCTestCase {
    func testMapperFlipsVisionYAxisForPreviewCoordinates() {
        let poseFrame = PoseFrameMapper.map(
            candidates: [
                .nose: PoseLandmarkCandidate(x: 0.25, y: 0.80, confidence: 0.95),
            ],
            timestampSeconds: 12
        )

        XCTAssertEqual(poseFrame.visibleLandmarkCount, 1)
        XCTAssertEqual(Double(poseFrame.landmarks[.nose]?.x ?? -1), 0.25, accuracy: 0.0001)
        XCTAssertEqual(Double(poseFrame.landmarks[.nose]?.y ?? -1), 0.20, accuracy: 0.0001)
    }

    func testMapperFiltersLowConfidenceLandmarks() {
        let poseFrame = PoseFrameMapper.map(
            candidates: [
                .nose: PoseLandmarkCandidate(x: 0.25, y: 0.80, confidence: 0.19),
                .leftShoulder: PoseLandmarkCandidate(x: 0.35, y: 0.55, confidence: 0.75),
            ],
            timestampSeconds: 24
        )

        XCTAssertNil(poseFrame.landmarks[.nose])
        XCTAssertNotNil(poseFrame.landmarks[.leftShoulder])
    }
}
