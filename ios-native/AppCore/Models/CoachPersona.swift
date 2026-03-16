enum CoachPersona: String, CaseIterable, Identifiable, Codable {
    case nice
    case sassy
    case mean

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .nice:
            return "Nice"
        case .sassy:
            return "Sassy"
        case .mean:
            return "Mean"
        }
    }
}
