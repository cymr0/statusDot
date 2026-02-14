import SwiftUI

enum ConnectionStatus: Sendable {
    case excellent
    case good
    case degraded
    case poor
    case down

    /// Latency thresholds in milliseconds used across the app for
    /// status evaluation, row coloring, and graph bands.
    static let excellentThreshold: Double = 50
    static let goodThreshold: Double = 100
    static let degradedThreshold: Double = 200

    /// Packet loss thresholds as fractions (0–1).
    static let degradedLossThreshold: Double = 0.2
    static let poorLossThreshold: Double = 0.5

    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .green
        case .degraded: return .yellow
        case .poor: return .orange
        case .down: return .red
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
