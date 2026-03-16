import Foundation

enum LightingState: String, CaseIterable, Codable, Equatable {
    case balanced
    case lowLight = "low_light"
    case backlit
    case harshOverhead = "harsh_overhead"

    var label: String {
        switch self {
        case .balanced:
            return "Lighting good"
        case .lowLight:
            return "Need more light"
        case .backlit:
            return "Background too bright"
        case .harshOverhead:
            return "Light is too overhead"
        }
    }
}

struct LightingAnalysisSummary: Codable, Equatable {
    let state: LightingState
    let averageLuma: Double
    let centerLuma: Double
    let edgeLuma: Double
    let topLuma: Double
}
