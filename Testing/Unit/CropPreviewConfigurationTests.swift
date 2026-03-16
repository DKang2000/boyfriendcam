import CoreGraphics
import XCTest
@testable import BoyfriendCamNative

final class CropPreviewConfigurationTests: XCTestCase {
    func testRegistryContainsExpectedCropModes() {
        XCTAssertEqual(CropPreviewRegistry.configurations.map(\.id), [.none, .square, .fourByFive, .nineBySixteen])
    }

    func testSquareMaskCentersInsidePortraitCanvas() {
        let rect = CropPreviewRegistry.configuration(for: .square).maskRect(
            in: CGSize(width: 900, height: 1600)
        )

        XCTAssertEqual(rect.width, 900, accuracy: 0.001)
        XCTAssertEqual(rect.height, 900, accuracy: 0.001)
        XCTAssertEqual(rect.origin.y, 350, accuracy: 0.001)
    }

    func testFourByFiveMaskUsesFullWidthWhenCanvasIsNarrowerThanTarget() {
        let rect = CropPreviewRegistry.configuration(for: .fourByFive).maskRect(
            in: CGSize(width: 800, height: 1600)
        )

        XCTAssertEqual(rect.width, 800, accuracy: 0.001)
        XCTAssertEqual(rect.height, 1000, accuracy: 0.001)
        XCTAssertEqual(rect.origin.y, 300, accuracy: 0.001)
    }

    func testSquareNormalizedRectCentersInsidePortraitPreview() {
        let rect = CropPreviewRegistry.configuration(for: .square).normalizedRect(
            inContainerAspectRatio: 9.0 / 16.0
        )

        XCTAssertEqual(rect.x, 0, accuracy: 0.001)
        XCTAssertEqual(rect.y, 0.21875, accuracy: 0.001)
        XCTAssertEqual(rect.width, 1, accuracy: 0.001)
        XCTAssertEqual(rect.height, 0.5625, accuracy: 0.001)
    }

    func testTemplateAdaptsTargetBoxInsideSquareCrop() {
        let template = ShotTemplateRegistry.template(for: .halfBody).adapted(
            to: CropPreviewRegistry.configuration(for: .square),
            previewAspectRatio: 9.0 / 16.0
        )

        XCTAssertEqual(template.overlay.targetBox.x, 0.22, accuracy: 0.001)
        XCTAssertEqual(template.overlay.targetBox.y, 0.30875, accuracy: 0.001)
        XCTAssertEqual(template.overlay.targetBox.width, 0.56, accuracy: 0.001)
        XCTAssertEqual(template.overlay.targetBox.height, 0.32625, accuracy: 0.001)
    }
}
