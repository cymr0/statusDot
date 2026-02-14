import Foundation
import os.log

private let logger = Logger(subsystem: "StatusDot", category: "PingExecutor")

protocol PingExecutor: Sendable {
    func execute(host: String) async -> PingResult
}

struct ProcessPingExecutor: PingExecutor {
    func execute(host: String) async -> PingResult {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(filePath: "/sbin/ping")
        process.arguments = ["-c", "1", "-W", "3000", host]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            return try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { _ in
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""

                    if process.terminationStatus == 0,
                       let latency = PingMonitor.parsePingLatency(from: output) {
                        continuation.resume(returning: PingResult(timestamp: Date(), latency: latency, host: host))
                    } else {
                        continuation.resume(returning: PingResult(timestamp: Date(), latency: nil, host: host, failureReason: .timeout))
                    }
                }
                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.warning("Ping process failed for \(host): \(error.localizedDescription)")
            return PingResult(timestamp: Date(), latency: nil, host: host, failureReason: .processError)
        }
    }
}
