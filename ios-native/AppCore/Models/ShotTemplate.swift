import CoreGraphics

enum ShotTemplateID: String, CaseIterable, Identifiable, Codable {
    case fullBody = "full_body"
    case halfBody = "half_body"
    case portrait
    case outfit
    case instagramStory = "instagram_story"
    case ruleOfThirds = "rule_of_thirds"

    var id: String {
        rawValue
    }
}

enum ShotGuideMode: String, Equatable, Codable {
    case crosshair
    case ruleOfThirds = "rule_of_thirds"
}

struct NormalizedRect: Equatable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    func rect(in size: CGSize) -> CGRect {
        CGRect(
            x: x * size.width,
            y: y * size.height,
            width: width * size.width,
            height: height * size.height
        )
    }

    func embedded(in container: NormalizedRect) -> NormalizedRect {
        NormalizedRect(
            x: container.x + x * container.width,
            y: container.y + y * container.height,
            width: width * container.width,
            height: height * container.height
        )
    }
}

struct ShotTemplateOverlaySpec: Equatable {
    let targetBox: NormalizedRect
    let headRadius: CGFloat
    let shoulderWidth: CGFloat
    let hipWidth: CGFloat
    let footInset: CGFloat
}

struct ShotTemplateScoringSpec: Equatable {
    let centerWeight: Double
    let requiredWeight: Double
    let coverageWeight: Double
    let minVisibleLandmarks: Int
    let requiredLandmarks: [PoseLandmarkName]
    let horizontalTolerance: CGFloat
    let verticalTolerance: CGFloat
    let scaleTolerance: CGFloat
    let smoothingAlpha: Double
    let promptHoldFrames: Int
    let readyExitThreshold: Double
}

struct ShotTemplate: Equatable, Identifiable {
    let id: ShotTemplateID
    let label: String
    let guideMode: ShotGuideMode
    let overlay: ShotTemplateOverlaySpec
    let readyThreshold: Double
    let scoring: ShotTemplateScoringSpec
    let summary: String

    func adapted(
        to cropPreview: CropPreviewConfiguration,
        previewAspectRatio: CGFloat
    ) -> ShotTemplate {
        let cropRect = cropPreview.normalizedRect(inContainerAspectRatio: previewAspectRatio)
        let adaptedOverlay = ShotTemplateOverlaySpec(
            targetBox: overlay.targetBox.embedded(in: cropRect),
            headRadius: overlay.headRadius,
            shoulderWidth: overlay.shoulderWidth,
            hipWidth: overlay.hipWidth,
            footInset: overlay.footInset
        )

        return ShotTemplate(
            id: id,
            label: label,
            guideMode: guideMode,
            overlay: adaptedOverlay,
            readyThreshold: readyThreshold,
            scoring: scoring,
            summary: summary
        )
    }
}

enum ShotTemplateRegistry {
    static let templates: [ShotTemplate] = [
        ShotTemplate(
            id: .fullBody,
            label: "Full Body",
            guideMode: .crosshair,
            overlay: ShotTemplateOverlaySpec(
                targetBox: NormalizedRect(x: 0.23, y: 0.10, width: 0.54, height: 0.82),
                headRadius: 0.085,
                shoulderWidth: 0.58,
                hipWidth: 0.42,
                footInset: 0.18
            ),
            readyThreshold: 0.78,
            scoring: ShotTemplateScoringSpec(
                centerWeight: 0.40,
                requiredWeight: 0.35,
                coverageWeight: 0.25,
                minVisibleLandmarks: 16,
                requiredLandmarks: [.nose, .leftShoulder, .rightShoulder, .leftAnkle, .rightAnkle],
                horizontalTolerance: 0.08,
                verticalTolerance: 0.10,
                scaleTolerance: 0.16,
                smoothingAlpha: 0.28,
                promptHoldFrames: 3,
                readyExitThreshold: 0.71
            ),
            summary: "Head-to-toe framing with feet visible."
        ),
        ShotTemplate(
            id: .halfBody,
            label: "Half Body",
            guideMode: .crosshair,
            overlay: ShotTemplateOverlaySpec(
                targetBox: NormalizedRect(x: 0.22, y: 0.16, width: 0.56, height: 0.58),
                headRadius: 0.10,
                shoulderWidth: 0.62,
                hipWidth: 0.46,
                footInset: 0.26
            ),
            readyThreshold: 0.72,
            scoring: ShotTemplateScoringSpec(
                centerWeight: 0.42,
                requiredWeight: 0.33,
                coverageWeight: 0.25,
                minVisibleLandmarks: 12,
                requiredLandmarks: [.nose, .leftShoulder, .rightShoulder, .leftHip, .rightHip],
                horizontalTolerance: 0.075,
                verticalTolerance: 0.09,
                scaleTolerance: 0.14,
                smoothingAlpha: 0.30,
                promptHoldFrames: 3,
                readyExitThreshold: 0.64
            ),
            summary: "Waist-up composition with balanced shoulders."
        ),
        ShotTemplate(
            id: .portrait,
            label: "Portrait",
            guideMode: .crosshair,
            overlay: ShotTemplateOverlaySpec(
                targetBox: NormalizedRect(x: 0.24, y: 0.12, width: 0.52, height: 0.46),
                headRadius: 0.12,
                shoulderWidth: 0.66,
                hipWidth: 0.40,
                footInset: 0.30
            ),
            readyThreshold: 0.70,
            scoring: ShotTemplateScoringSpec(
                centerWeight: 0.48,
                requiredWeight: 0.34,
                coverageWeight: 0.18,
                minVisibleLandmarks: 8,
                requiredLandmarks: [.nose, .leftEye, .rightEye, .leftShoulder, .rightShoulder],
                horizontalTolerance: 0.07,
                verticalTolerance: 0.08,
                scaleTolerance: 0.12,
                smoothingAlpha: 0.32,
                promptHoldFrames: 2,
                readyExitThreshold: 0.62
            ),
            summary: "Chest-up portrait with clean headroom."
        ),
        ShotTemplate(
            id: .outfit,
            label: "Outfit",
            guideMode: .crosshair,
            overlay: ShotTemplateOverlaySpec(
                targetBox: NormalizedRect(x: 0.21, y: 0.08, width: 0.58, height: 0.84),
                headRadius: 0.082,
                shoulderWidth: 0.62,
                hipWidth: 0.48,
                footInset: 0.16
            ),
            readyThreshold: 0.80,
            scoring: ShotTemplateScoringSpec(
                centerWeight: 0.36,
                requiredWeight: 0.34,
                coverageWeight: 0.30,
                minVisibleLandmarks: 16,
                requiredLandmarks: [.nose, .leftShoulder, .rightShoulder, .leftKnee, .rightKnee],
                horizontalTolerance: 0.08,
                verticalTolerance: 0.10,
                scaleTolerance: 0.15,
                smoothingAlpha: 0.28,
                promptHoldFrames: 3,
                readyExitThreshold: 0.73
            ),
            summary: "Head-to-hem framing with extra space for styling."
        ),
        ShotTemplate(
            id: .instagramStory,
            label: "IG Story",
            guideMode: .ruleOfThirds,
            overlay: ShotTemplateOverlaySpec(
                targetBox: NormalizedRect(x: 0.20, y: 0.06, width: 0.60, height: 0.88),
                headRadius: 0.082,
                shoulderWidth: 0.58,
                hipWidth: 0.42,
                footInset: 0.18
            ),
            readyThreshold: 0.75,
            scoring: ShotTemplateScoringSpec(
                centerWeight: 0.34,
                requiredWeight: 0.33,
                coverageWeight: 0.33,
                minVisibleLandmarks: 14,
                requiredLandmarks: [.nose, .leftShoulder, .rightShoulder, .leftHip, .rightHip],
                horizontalTolerance: 0.09,
                verticalTolerance: 0.10,
                scaleTolerance: 0.15,
                smoothingAlpha: 0.28,
                promptHoldFrames: 3,
                readyExitThreshold: 0.68
            ),
            summary: "Tall vertical framing with story-safe breathing room."
        ),
        ShotTemplate(
            id: .ruleOfThirds,
            label: "Rule of Thirds",
            guideMode: .ruleOfThirds,
            overlay: ShotTemplateOverlaySpec(
                targetBox: NormalizedRect(x: 0.10, y: 0.14, width: 0.42, height: 0.68),
                headRadius: 0.10,
                shoulderWidth: 0.64,
                hipWidth: 0.48,
                footInset: 0.22
            ),
            readyThreshold: 0.68,
            scoring: ShotTemplateScoringSpec(
                centerWeight: 0.40,
                requiredWeight: 0.34,
                coverageWeight: 0.26,
                minVisibleLandmarks: 10,
                requiredLandmarks: [.nose, .leftShoulder, .rightShoulder],
                horizontalTolerance: 0.08,
                verticalTolerance: 0.09,
                scaleTolerance: 0.14,
                smoothingAlpha: 0.30,
                promptHoldFrames: 3,
                readyExitThreshold: 0.60
            ),
            summary: "Place the subject off-center on the thirds grid."
        ),
    ]

    static let registry: [ShotTemplateID: ShotTemplate] = {
        Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
    }()

    static let defaultTemplate = templates[0]

    static func template(for id: ShotTemplateID) -> ShotTemplate {
        registry[id] ?? defaultTemplate
    }
}
