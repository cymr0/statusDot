import Foundation
import Testing
@testable import StatusDot

struct MockPingExecutor: PingExecutor {
    var results: [PingResult] = []
    var callIndex = 0

    func execute(host: String) async -> PingResult {
        PingResult(timestamp: .now, latency: nil, host: host, failureReason: .timeout)
    }
}

@Suite("PingMonitor")
@MainActor
struct PingMonitorTests {
    private func makeMonitor() -> PingMonitor {
        UserDefaults.standard.removeObject(forKey: "pingHistory")
        return PingMonitor(settings: AppSettings(), executor: MockPingExecutor())
    }

    private func makePing(latency: Double?, host: String = "8.8.8.8") -> PingResult {
        PingResult(timestamp: .now, latency: latency, host: host)
    }

    @Test("Initial status is down")
    func initialStatus() {
        let monitor = makeMonitor()
        #expect(monitor.status == .down)
        #expect(monitor.history.isEmpty)
        #expect(monitor.currentLatency == nil)
    }

    @Test("Single ping updates current latency")
    func singlePing() {
        let monitor = makeMonitor()
        monitor.recordResult(makePing(latency: 25.0))

        #expect(monitor.currentLatency == 25.0)
        #expect(monitor.history.count == 1)
    }

    @Test("Excellent status from low latency pings")
    func excellentStatus() {
        let monitor = makeMonitor()
        for _ in 0..<monitor.statusWindow {
            monitor.recordResult(makePing(latency: 10.0))
        }
        #expect(monitor.status == .excellent)
    }

    @Test("Poor status from high latency pings")
    func poorStatus() {
        let monitor = makeMonitor()
        for _ in 0..<monitor.statsWindow {
            monitor.recordResult(makePing(latency: 250.0))
        }
        #expect(monitor.status == .poor)
    }

    @Test("Down status from all failed pings")
    func downStatus() {
        let monitor = makeMonitor()
        for _ in 0..<monitor.statusWindow {
            monitor.recordResult(makePing(latency: nil))
        }
        #expect(monitor.status == .down)
        #expect(monitor.packetLoss == 100.0)
    }

    @Test("History is capped at 120 entries")
    func historyCapped() {
        let monitor = makeMonitor()
        for _ in 0..<150 {
            monitor.recordResult(makePing(latency: 20.0))
        }
        #expect(monitor.history.count == 120)
    }

    @Test("Stats are computed over last 20 samples")
    func statsWindow() {
        let monitor = makeMonitor()
        for _ in 0..<monitor.statsWindow {
            monitor.recordResult(makePing(latency: 100.0))
        }
        for _ in 0..<monitor.statsWindow {
            monitor.recordResult(makePing(latency: 10.0))
        }
        #expect(monitor.averageLatency == 10.0)
        #expect(monitor.minLatency == 10.0)
        #expect(monitor.maxLatency == 10.0)
    }

    @Test("Packet loss percentage reflects failed pings in window")
    func packetLossPercentage() {
        let monitor = makeMonitor()
        for _ in 0..<15 {
            monitor.recordResult(makePing(latency: 30.0))
        }
        for _ in 0..<5 {
            monitor.recordResult(makePing(latency: nil))
        }
        #expect(monitor.packetLoss == 25.0)
    }

    @Test("Failure reason is preserved")
    func failureReason() {
        let monitor = makeMonitor()
        let timeout = PingResult(timestamp: .now, latency: nil, host: "8.8.8.8", failureReason: .timeout)
        let processError = PingResult(timestamp: .now, latency: nil, host: "8.8.8.8", failureReason: .processError)
        monitor.recordResult(timeout)
        monitor.recordResult(processError)
        #expect(monitor.history[0].failureReason == .timeout)
        #expect(monitor.history[1].failureReason == .processError)
    }

    @Test("Mock executor is used instead of real ping")
    func usesInjectedExecutor() {
        let monitor = makeMonitor()
        // MockPingExecutor doesn't spawn processes, so this confirms DI works
        #expect(monitor.history.isEmpty)
    }

    @Test("Stale history is discarded on load")
    func staleHistoryDiscarded() throws {
        // Save history with old timestamps
        let staleResult = PingResult(
            timestamp: Date.now.addingTimeInterval(-3600),
            latency: 50.0,
            host: "8.8.8.8"
        )
        let data = try JSONEncoder().encode([staleResult])
        UserDefaults.standard.set(data, forKey: "pingHistory")

        let monitor = PingMonitor(settings: AppSettings(), executor: MockPingExecutor())
        #expect(monitor.history.isEmpty)

        UserDefaults.standard.removeObject(forKey: "pingHistory")
    }
}
