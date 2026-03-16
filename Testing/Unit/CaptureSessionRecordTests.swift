import XCTest
@testable import BoyfriendCamNative

final class CaptureSessionRecordTests: XCTestCase {
    func testSelectedFrameFallsBackToFirstFrameWhenSelectionMissing() {
        let firstFrame = CapturedFrameRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            capturedAt: Date(timeIntervalSince1970: 1),
            fileURL: URL(fileURLWithPath: "/tmp/first.jpg")
        )
        let secondFrame = CapturedFrameRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            capturedAt: Date(timeIntervalSince1970: 2),
            fileURL: URL(fileURLWithPath: "/tmp/second.jpg")
        )
        let session = CaptureSessionRecord(
            templateID: .portrait,
            persona: .nice,
            captureMode: .burst3,
            cropPreviewID: .fourByFive,
            frames: [firstFrame, secondFrame],
            selectedFrameID: UUID(uuidString: "00000000-0000-0000-0000-000000000099")!
        )

        XCTAssertEqual(session.selectedFrame?.id, firstFrame.id)
        XCTAssertEqual(session.frameCountSummary, "2 shots")
    }

    func testMarkExportedUpdatesSpecificFrameOnly() {
        let firstFrame = CapturedFrameRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
            capturedAt: Date(timeIntervalSince1970: 1),
            fileURL: URL(fileURLWithPath: "/tmp/first.jpg")
        )
        let secondFrame = CapturedFrameRecord(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
            capturedAt: Date(timeIntervalSince1970: 2),
            fileURL: URL(fileURLWithPath: "/tmp/second.jpg")
        )
        var session = CaptureSessionRecord(
            templateID: .fullBody,
            persona: .sassy,
            captureMode: .burst3,
            cropPreviewID: .none,
            frames: [firstFrame, secondFrame]
        )

        session.markExported(frameID: secondFrame.id, at: Date(timeIntervalSince1970: 10))

        XCTAssertFalse(session.frames[0].wasExported)
        XCTAssertTrue(session.frames[1].wasExported)
        XCTAssertEqual(session.frames[1].exportedAt, Date(timeIntervalSince1970: 10))
    }
}
