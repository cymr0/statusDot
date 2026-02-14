import Testing
@testable import StatusDot

@Suite("Ping output parsing")
struct PingParsingTests {
    @Test("Parses standard ping latency")
    func standardLatency() {
        let output = """
        PING 8.8.8.8 (8.8.8.8): 56 data bytes
        64 bytes from 8.8.8.8: icmp_seq=0 ttl=117 time=12.345 ms
        """
        let latency = PingMonitor.parsePingLatency(from: output)
        #expect(latency == 12.345)
    }

    @Test("Parses integer latency without decimal")
    func integerLatency() {
        let output = "64 bytes from 1.1.1.1: icmp_seq=0 ttl=55 time=8 ms"
        let latency = PingMonitor.parsePingLatency(from: output)
        #expect(latency == 8)
    }

    @Test("Returns nil for timeout output")
    func timeout() {
        let output = """
        PING 10.0.0.1 (10.0.0.1): 56 data bytes
        Request timeout for icmp_seq 0
        """
        let latency = PingMonitor.parsePingLatency(from: output)
        #expect(latency == nil)
    }

    @Test("Returns nil for empty string")
    func emptyString() {
        let latency = PingMonitor.parsePingLatency(from: "")
        #expect(latency == nil)
    }
}
