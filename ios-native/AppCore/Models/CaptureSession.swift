import CoreGraphics
import Foundation

enum CameraZoomPreset: String, CaseIterable, Identifiable, Codable {
    case zoom05
    case zoom1
    case zoom2
    case zoom5

    var id: String {
        rawValue
    }

    var displayLabel: String {
        switch self {
        case .zoom05:
            return "0.5"
        case .zoom1:
            return "1"
        case .zoom2:
            return "2"
        case .zoom5:
            return "5"
        }
    }

    var requestedFactor: CGFloat {
        switch self {
        case .zoom05:
            return 0.5
        case .zoom1:
            return 1
        case .zoom2:
            return 2
        case .zoom5:
            return 5
        }
    }
}

enum CaptureMode: String, CaseIterable, Identifiable, Codable {
    case single
    case burst3
    case burst5
    case burst10

    var id: String {
        rawValue
    }

    var frameCount: Int {
        switch self {
        case .single:
            return 1
        case .burst3:
            return 3
        case .burst5:
            return 5
        case .burst10:
            return 10
        }
    }

    var label: String {
        switch self {
        case .single:
            return "1"
        case .burst3:
            return "3"
        case .burst5:
            return "5"
        case .burst10:
            return "10"
        }
    }
}

struct CapturedFrameRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let capturedAt: Date
    let fileURL: URL
    var wasExported: Bool
    var exportedAt: Date?

    init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        fileURL: URL,
        wasExported: Bool = false,
        exportedAt: Date? = nil
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.fileURL = fileURL
        self.wasExported = wasExported
        self.exportedAt = exportedAt
    }

    init(photo: CapturedPhoto) {
        self.init(
            id: photo.id,
            capturedAt: photo.capturedAt,
            fileURL: photo.fileURL
        )
    }
}

struct CaptureSessionRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    var templateID: ShotTemplateID
    var persona: CoachPersona
    var captureMode: CaptureMode
    var cropPreviewID: CropPreviewID
    var frames: [CapturedFrameRecord]
    var selectedFrameID: UUID
    var readyScore: Double?
    var primaryPromptText: String?
    var lighting: LightingAnalysisSummary?
    var motion: MotionGuidanceState?
    var orientationLabel: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        templateID: ShotTemplateID,
        persona: CoachPersona,
        captureMode: CaptureMode,
        cropPreviewID: CropPreviewID,
        frames: [CapturedFrameRecord],
        selectedFrameID: UUID? = nil,
        readyScore: Double? = nil,
        primaryPromptText: String? = nil,
        lighting: LightingAnalysisSummary? = nil,
        motion: MotionGuidanceState? = nil,
        orientationLabel: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.templateID = templateID
        self.persona = persona
        self.captureMode = captureMode
        self.cropPreviewID = cropPreviewID
        self.frames = frames
        self.selectedFrameID = selectedFrameID ?? frames.first?.id ?? UUID()
        self.readyScore = readyScore
        self.primaryPromptText = primaryPromptText
        self.lighting = lighting
        self.motion = motion
        self.orientationLabel = orientationLabel
    }

    var selectedFrame: CapturedFrameRecord? {
        frames.first(where: { $0.id == selectedFrameID }) ?? frames.first
    }

    var frameCountSummary: String {
        let count = frames.count
        return count == 1 ? "1 shot" : "\(count) shots"
    }

    mutating func selectFrame(id: UUID) {
        guard frames.contains(where: { $0.id == id }) else {
            return
        }

        selectedFrameID = id
    }

    mutating func updateCropPreview(_ cropPreviewID: CropPreviewID) {
        self.cropPreviewID = cropPreviewID
    }

    mutating func markExported(frameID: UUID, at date: Date = Date()) {
        guard let index = frames.firstIndex(where: { $0.id == frameID }) else {
            return
        }

        frames[index].wasExported = true
        frames[index].exportedAt = date
    }
}
