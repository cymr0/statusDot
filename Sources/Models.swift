import Foundation

struct PingResult: Identifiable, Sendable, Codable {
    enum FailureReason: String, Codable, Sendable {
        case timeout
        case processError
    }

    let id: UUID
    let timestamp: Date
    let latency: Double?
    let host: String
    let failureReason: FailureReason?

    var isSuccess: Bool { latency != nil }

    var failureLabel: String {
        switch failureReason {
        case .timeout: "timeout"
        case .processError: "error"
        case nil: "failed"
        }
    }

    init(timestamp: Date, latency: Double?, host: String, failureReason: FailureReason? = nil) {
        self.id = UUID()
        self.timestamp = timestamp
        self.latency = latency
        self.host = host
        self.failureReason = failureReason
    }
}
