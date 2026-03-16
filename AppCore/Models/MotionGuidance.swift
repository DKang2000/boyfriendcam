import Foundation

enum LevelState: String, Codable, Equatable {
    case level
    case tiltedLeft = "tilted_left"
    case tiltedRight = "tilted_right"
}

struct MotionGuidanceState: Codable, Equatable {
    let rollDegrees: Double
    let pitchDegrees: Double
    let normalizedPitchDegrees: Double
    let levelState: LevelState
    let phoneTiltSignal: PhoneTiltPromptSignal?
    let isPortraitUpright: Bool
    let isPortraitUpsideDown: Bool
}
