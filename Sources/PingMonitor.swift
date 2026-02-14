import Foundation
import Observation
import os.log

private let logger = Logger(subsystem: "StatusDot", category: "PingMonitor")

@Observable
@MainActor
class PingMonitor {
    private(set) var status: ConnectionStatus = .down
    private(set) var history: [PingResult] = []
    private(set) var currentLatency: Double?
    private(set) var averageLatency: Double?
    private(set) var packetLoss: Double = 0
    private(set) var minLatency: Double?
    private(set) var maxLatency: Double?

    let settings: AppSettings
    @ObservationIgnored private let executor: PingExecutor
    @ObservationIgnored private var pingTask: Task<Void, Never>?
    private let maxHistory = 120
    let statsWindow = 20
    let statusWindow = 12
    @ObservationIgnored private static let historyKey = "pingHistory"
    /// Discard persisted pings older than this on load.
    private let maxHistoryAge: TimeInterval = 600

    init(settings: AppSettings, executor: PingExecutor = ProcessPingExecutor()) {
        self.settings = settings
        self.executor = executor
        loadHistory()
    }

    func start() {
        stop()
        pingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.ping()
                try? await Task.sleep(for: .seconds(self.settings.pingInterval))
            }
        }
    }

    func stop() {
        pingTask?.cancel()
        pingTask = nil
    }

    private func ping() async {
        let hosts = settings.hosts
        guard !hosts.isEmpty else { return }
        let host = hosts[history.count % hosts.count]
        let result = await executor.execute(host: host)
        recordResult(result)
    }

    nonisolated static func parsePingLatency(from output: String) -> Double? {
        guard let match = output.firstMatch(of: #/time=(\d+\.?\d*)\s*ms/#) else {
            return nil
        }
        return Double(match.1)
    }

    func recordResult(_ result: PingResult) {
        history.append(result)
        if history.count > maxHistory {
            history.removeFirst(history.count - maxHistory)
        }

        currentLatency = result.latency
        updateStats()
        updateStatus()
        saveHistory()
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: Self.historyKey)
        } catch {
            logger.error("Failed to encode history: \(error.localizedDescription)")
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: Self.historyKey) else { return }
        do {
            let saved = try JSONDecoder().decode([PingResult].self, from: data)
            let cutoff = Date.now.addingTimeInterval(-maxHistoryAge)
            history = Array(saved.filter { $0.timestamp > cutoff }.suffix(maxHistory))
        } catch {
            logger.error("Failed to decode history, clearing: \(error.localizedDescription)")
            UserDefaults.standard.removeObject(forKey: Self.historyKey)
            return
        }
        if let last = history.last {
            currentLatency = last.latency
        }
        updateStats()
        updateStatus()
    }

    private func updateStats() {
        let recent = Array(history.suffix(statsWindow))
        let successes = recent.compactMap(\.latency)

        if successes.isEmpty {
            averageLatency = nil
            minLatency = nil
            maxLatency = nil
            packetLoss = recent.isEmpty ? 0 : 100.0
        } else {
            averageLatency = successes.reduce(0, +) / Double(successes.count)
            minLatency = successes.min()
            maxLatency = successes.max()
            packetLoss = Double(recent.count - successes.count) / Double(recent.count) * 100.0
        }
    }

    private func updateStatus() {
        let recent = Array(history.suffix(statusWindow))
        guard !recent.isEmpty else {
            status = .down
            return
        }

        let successes = recent.compactMap(\.latency)
        let lossRate = Double(recent.count - successes.count) / Double(recent.count)

        if successes.isEmpty {
            status = .down
        } else if lossRate > ConnectionStatus.poorLossThreshold {
            status = .poor
        } else if lossRate > ConnectionStatus.degradedLossThreshold {
            status = .degraded
        } else if let avg = averageLatency {
            if avg < ConnectionStatus.excellentThreshold {
                status = .excellent
            } else if avg < ConnectionStatus.goodThreshold {
                status = .good
            } else if avg < ConnectionStatus.degradedThreshold {
                status = .degraded
            } else {
                status = .poor
            }
        } else {
            status = .down
        }
    }
}
