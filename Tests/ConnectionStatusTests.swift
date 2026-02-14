import Testing
import SwiftUI
@testable import StatusDot

@Suite("ConnectionStatus")
struct ConnectionStatusTests {
    @Test("All cases have a non-empty label", arguments: [
        ConnectionStatus.excellent,
        ConnectionStatus.good,
        ConnectionStatus.degraded,
        ConnectionStatus.poor,
        ConnectionStatus.down,
    ])
    func labelsExist(status: ConnectionStatus) {
        #expect(!status.label.isEmpty)
    }

    @Test("Threshold constants are ordered correctly")
    func thresholdsOrdered() {
        #expect(ConnectionStatus.excellentThreshold < ConnectionStatus.goodThreshold)
        #expect(ConnectionStatus.goodThreshold < ConnectionStatus.degradedThreshold)
        #expect(ConnectionStatus.degradedLossThreshold < ConnectionStatus.poorLossThreshold)
    }

    @Test("Loss thresholds are between 0 and 1")
    func lossThresholdRange() {
        #expect(ConnectionStatus.degradedLossThreshold > 0)
        #expect(ConnectionStatus.degradedLossThreshold < 1)
        #expect(ConnectionStatus.poorLossThreshold > 0)
        #expect(ConnectionStatus.poorLossThreshold < 1)
    }
}
