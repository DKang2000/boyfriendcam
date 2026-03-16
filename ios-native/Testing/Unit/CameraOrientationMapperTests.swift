import AVFoundation
import UIKit
import XCTest
@testable import BoyfriendCamNative

final class CameraOrientationMapperTests: XCTestCase {
    func testPortraitMapsToPortraitVideoOrientation() {
        XCTAssertEqual(
            CameraOrientationMapper.videoOrientation(for: .portrait),
            .portrait
        )
    }

    func testPortraitUpsideDownMapsToPortraitUpsideDownVideoOrientation() {
        XCTAssertEqual(
            CameraOrientationMapper.videoOrientation(for: .portraitUpsideDown),
            .portraitUpsideDown
        )
    }

    func testFaceUpDoesNotProduceVideoOrientation() {
        XCTAssertNil(CameraOrientationMapper.videoOrientation(for: .faceUp))
    }
}
