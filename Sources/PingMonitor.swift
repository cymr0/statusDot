import Combine
import Foundation

@MainActor
class PingMonitor: ObservableObject {
    @Published var status: ConnectionStatus = .down
    @Published var history: [PingResult] = []
    @Published var currentLatency: Double?
    @Published var averageLatency: Double?
    @Published var packetLoss: Double = 0
    @Published var minLatency: Double?
    @Published var maxLatency: Double?

    let settings: AppSettings
    private var timer: Timer?
    private let maxHistory = 120
    private var settingsCancellable: AnyCancellable?

    init(settings: AppSettings) {
        self.settings = settings
    }

    func start() {
        ping()
        scheduleTimer()

        settingsCancellable = settings.$pingInterval
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.stop()
                    self?.ping()
                    self?.scheduleTimer()
                }
            }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: settings.pingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.ping()
            }
        }
    }

    private func ping() {
        let hosts = settings.hosts
        guard !hosts.isEmpty else { return }
        let host = hosts[history.count % hosts.count]
        Task { [weak self] in
            let result = await Self.executePing(host: host)
            self?.recordResult(result)
        }
    }

    private static func executePing(host: String) async -> PingResult {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-c", "1", "-W", "3000", host]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if process.terminationStatus == 0,
               let latency = parsePingLatency(from: output) {
                return PingResult(timestamp: Date(), latency: latency, host: host)
            } else {
                return PingResult(timestamp: Date(), latency: nil, host: host)
            }
        } catch {
            return PingResult(timestamp: Date(), latency: nil, host: host)
        }
    }

    private static func parsePingLatency(from output: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: #"time=(\d+\.?\d*)\s*ms"#),
              let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
              let range = Range(match.range(at: 1), in: output) else {
            return nil
        }
        return Double(output[range])
    }

    private func recordResult(_ result: PingResult) {
        history.append(result)
        if history.count > maxHistory {
            history.removeFirst(history.count - maxHistory)
        }

        currentLatency = result.latency
        updateStats()
        updateStatus()
    }

    private func updateStats() {
        let recent = Array(history.suffix(20))
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
        let recent = Array(history.suffix(12))
        guard !recent.isEmpty else {
            status = .down
            return
        }

        let successes = recent.compactMap(\.latency)
        let lossRate = Double(recent.count - successes.count) / Double(recent.count)

        if successes.isEmpty {
            status = .down
        } else if lossRate > 0.5 {
            status = .poor
        } else if lossRate > 0.2 {
            status = .degraded
        } else if let avg = averageLatency {
            if avg < 50 {
                status = .excellent
            } else if avg < 100 {
                status = .good
            } else if avg < 200 {
                status = .degraded
            } else {
                status = .poor
            }
        } else {
            status = .down
        }
    }
}
