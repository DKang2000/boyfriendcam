import CoreGraphics

enum CameraExperienceMode: String, CaseIterable, Identifiable, Codable, Equatable {
    case coach
    case templates

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .coach:
            return "Coach"
        case .templates:
            return "Templates"
        }
    }
}

enum FramingPromptSignal: String, Equatable, Codable {
    case ready
    case findSubject
    case moveLeft
    case moveRight
    case moveBack
    case moveCloser
    case raiseCamera
    case lowerCamera
    case fitSubject
    case adjustFraming
}

enum PhoneTiltPromptSignal: String, Equatable, Codable {
    case tiltPhoneUp
    case tiltPhoneDown
    case levelPhone
}

enum CoachPromptSignal: String, Equatable, Codable {
    case ready
    case findSubject
    case moveLeft
    case moveRight
    case moveBack
    case moveCloser
    case raiseCamera
    case lowerCamera
    case tiltPhoneUp
    case tiltPhoneDown
    case flipUpsideDown
    case turnBody
    case turnFace
    case chinForward
    case chinDown
}

enum CoachingAudience: String, Equatable, Codable {
    case photographer
    case subject
}

enum CoachingOverlayMode: String, Equatable, Codable {
    case coachHighlight
    case templateGuide
}

struct CoachRecommendation: Equatable, Codable {
    let signal: CoachPromptSignal
    let audience: CoachingAudience
    let confidence: Double
    let isGuidanceActive: Bool
}

struct FramingMetrics: Equatable {
    let visibleLandmarkCount: Int
    let requiredLandmarkRatio: Double
    let centerXOffset: CGFloat
    let centerYOffset: CGFloat
    let subjectHeightRatio: CGFloat
    let targetCenter: CGPoint
    let subjectCenter: CGPoint?
    let subjectBounds: CGRect?
}

struct FrameScoreBreakdown: Equatable {
    let centerScore: Double
    let requiredScore: Double
    let coverageScore: Double
    let totalScore: Double
}

struct FrameAnalysis: Equatable {
    let metrics: FramingMetrics
    let scores: FrameScoreBreakdown
}

struct CoachingSnapshot: Equatable {
    let analysis: FrameAnalysis
    let smoothedScore: Double
    let isReady: Bool
    let statusLabel: String
    let experienceMode: CameraExperienceMode
    let overlayMode: CoachingOverlayMode
    let isGuidanceActive: Bool
    let framingSignal: FramingPromptSignal
    let phoneTiltSignal: PhoneTiltPromptSignal?
    let coachRecommendation: CoachRecommendation?
    let primaryPromptText: String
    let secondaryPromptText: String?
}
