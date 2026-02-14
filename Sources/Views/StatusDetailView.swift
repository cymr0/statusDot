import SwiftUI

struct StatusDetailView: View {
    @ObservedObject var monitor: PingMonitor
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showSettings {
                SettingsView(settings: monitor.settings, showSettings: $showSettings)
            } else {
                statusContent
            }
        }
        .padding(14)
        .frame(width: 320)
    }

    private var statusContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeaderView(status: monitor.status)

            Divider()

            StatsGridView(monitor: monitor)

            Divider()

            Text("Latency History (last 5 min)")
                .font(.caption)
                .foregroundColor(.secondary)

            LatencyGraphView(history: monitor.history)
                .frame(height: 90)

            Divider()

            RecentPingsView(history: monitor.history)

            Divider()

            FooterView(
                pingInterval: monitor.settings.pingInterval,
                showSettings: $showSettings
            )
        }
    }
}

private struct HeaderView: View {
    let status: ConnectionStatus

    var body: some View {
        HStack {
            Circle()
                .fill(Color(nsColor: status.color))
                .frame(width: 12, height: 12)
            Text(status.label)
                .font(.headline)
            Spacer()
            Text("StatusDot")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct StatsGridView: View {
    @ObservedObject var monitor: PingMonitor

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            StatCard(label: "Current", value: formatLatency(monitor.currentLatency))
            StatCard(label: "Average", value: formatLatency(monitor.averageLatency))
            StatCard(label: "Min", value: formatLatency(monitor.minLatency))
            StatCard(label: "Max", value: formatLatency(monitor.maxLatency))
            StatCard(label: "Packet Loss", value: String(format: "%.0f%%", monitor.packetLoss))
            StatCard(label: "Samples", value: "\(monitor.history.count)")
        }
    }

    private func formatLatency(_ latency: Double?) -> String {
        guard let latency else { return "—" }
        return String(format: "%.1f ms", latency)
    }
}

private struct RecentPingsView: View {
    let history: [PingResult]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent Pings")
                .font(.caption)
                .foregroundColor(.secondary)

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
            Text(result.timestamp, style: .time)
                .font(.system(size: 10, design: .monospaced))
            Text(result.host)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
            Spacer()
            if let latency = result.latency {
                Text(String(format: "%.1f ms", latency))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(latencyColor(latency))
            } else {
                Text("timeout")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.red)
            }
        }
    }

    private func latencyColor(_ latency: Double) -> Color {
        if latency < 50 { return .green }
        if latency < 100 { return .primary }
        if latency < 200 { return .yellow }
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
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .font(.caption)
            Spacer()
            Text("Every \(Int(pingInterval))s")
                .font(.caption2)
                .foregroundColor(.secondary)
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gear")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
    }
}
