import AppKit

struct PingResult: Identifiable {
    let id = UUID()
    let timestamp: Date
    let latency: Double?
    let host: String

    var isSuccess: Bool { latency != nil }
}

enum ConnectionStatus {
    case excellent
    case good
    case degraded
    case poor
    case down

    var color: NSColor {
        switch self {
        case .excellent: return .systemGreen
        case .good: return .systemGreen
        case .degraded: return .systemYellow
        case .poor: return .systemOrange
        case .down: return .systemRed
        }
    }

    var label: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .degraded: return "Degraded"
        case .poor: return "Poor"
        case .down: return "Down"
        }
    }
}
