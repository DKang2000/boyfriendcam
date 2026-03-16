import XCTest
@testable import BoyfriendCamNative

final class ShotTemplateRegistryTests: XCTestCase {
    func testRegistryMatchesExpectedTemplateCount() {
        XCTAssertEqual(ShotTemplateRegistry.templates.count, 6)
    }

    func testFullBodyTemplatePreservesReferenceGeometry() {
        let template = ShotTemplateRegistry.template(for: .fullBody)

        XCTAssertEqual(template.guideMode, .crosshair)
        XCTAssertEqual(template.overlay.targetBox.x, 0.23, accuracy: 0.0001)
        XCTAssertEqual(template.overlay.targetBox.y, 0.10, accuracy: 0.0001)
        XCTAssertEqual(template.overlay.targetBox.width, 0.54, accuracy: 0.0001)
        XCTAssertEqual(template.overlay.targetBox.height, 0.82, accuracy: 0.0001)
        XCTAssertEqual(template.summary, "Head-to-toe framing with feet visible.")
    }

    func testRuleOfThirdsTemplateUsesThirdsGuideMode() {
        let template = ShotTemplateRegistry.template(for: .ruleOfThirds)

        XCTAssertEqual(template.guideMode, .ruleOfThirds)
        XCTAssertEqual(template.overlay.targetBox.width, 0.42, accuracy: 0.0001)
    }
}
