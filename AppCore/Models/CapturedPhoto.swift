import Foundation

struct CapturedPhoto: Equatable, Identifiable {
    let id: UUID
    let capturedAt: Date
    let fileURL: URL

    init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        fileURL: URL
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.fileURL = fileURL
    }
}
