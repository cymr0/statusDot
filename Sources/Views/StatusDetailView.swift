import SwiftUI

struct StatusDetailView: View {
    var monitor: PingMonitor
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showSettings {
                SettingsView(settings: monitor.settings, showSettings: $showSettings)
                    .transition(.push(from: .leading))
            } else {
                StatusContentView(monitor: monitor, showSettings: $showSettings)
                    .transition(.push(from: .trailing))
            }
        }
        .animation(.default, value: showSettings)
        .padding(14)
        .frame(width: 320)
    }
}

private struct StatusContentView: View {
    var monitor: PingMonitor
    @Binding var showSettings: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeaderView(status: monitor.status)

            Divider()

            if monitor.history.isEmpty {
                WaitingView()
            } else {
                StatsGridView(monitor: monitor)

                Divider()

                Text(chartLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LatencyGraphView(history: monitor.history)
                    .frame(height: 90)

                Divider()

                RecentPingsView(history: monitor.history)
            }

            Divider()

            FooterView(
                pingInterval: monitor.settings.pingInterval,
                showSettings: $showSettings
            )
        }
    }

    private var chartLabel: String {
        let totalSeconds = Int(monitor.settings.pingInterval) * 60
        if totalSeconds >= 3600 {
            return "Latency History (last \(totalSeconds / 3600) hr)"
        } else {
            return "Latency History (last \(totalSeconds / 60) min)"
        }
    }
}

private struct WaitingView: View {
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Waiting for first ping...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

private struct HeaderView: View {
    let status: ConnectionStatus

    var body: some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
            Text(status.label)
                .font(.headline)
            Spacer()
            Text("StatusDot")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct StatsGridView: View {
    var monitor: PingMonitor

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            StatCard(label: "Current", value: formatLatency(monitor.currentLatency))
            StatCard(label: "Average", value: formatLatency(monitor.averageLatency))
            StatCard(label: "Min", value: formatLatency(monitor.minLatency))
            StatCard(label: "Max", value: formatLatency(monitor.maxLatency))
            StatCard(label: "Packet Loss", value: "\(monitor.packetLoss.formatted(.number.precision(.fractionLength(0))))%")
            StatCard(label: "Samples", value: "\(monitor.history.count)")
        }
    }

    private func formatLatency(_ latency: Double?) -> String {
        guard let latency else { return "—" }
        return "\(latency.formatted(.number.precision(.fractionLength(1)))) ms"
    }
}

private struct RecentPingsView: View {
    let history: [PingResult]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent Pings")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(history.suffix(10).reversed()) { result in
                        PingRowView(result: result)
                    }
                }
            }
            .frame(maxHeight: 100)
        }
    }
}

private struct PingRowView: View {
    let result: PingResult

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(result.isSuccess ? Color.green : Color.red)
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)
            Text(result.timestamp, style: .time)
                .font(.caption2.monospaced())
            Text(result.host)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
            Spacer()
            if let latency = result.latency {
                Text("\(latency.formatted(.number.precision(.fractionLength(1)))) ms")
                    .font(.caption2.monospaced())
                    .foregroundStyle(latencyColor(latency))
            } else {
                Text(result.failureLabel)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.red)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func latencyColor(_ latency: Double) -> Color {
        if latency < ConnectionStatus.excellentThreshold { return .green }
        if latency < ConnectionStatus.goodThreshold { return .primary }
        if latency < ConnectionStatus.degradedThreshold { return .yellow }
        return .red
    }
}

private struct FooterView: View {
    let pingInterval: TimeInterval
    @Binding var showSettings: Bool

    var body: some View {
        HStack {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.caption)
            Spacer()
            Text("Every \(Int(pingInterval))s")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Ping interval: every \(Int(pingInterval)) seconds")
            Button("Settings", systemImage: "gear") {
                showSettings = true
            }
            .keyboardShortcut(",", modifiers: .command)
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.caption)
        }
    }
}
