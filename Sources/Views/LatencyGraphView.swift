import SwiftUI
import Charts

struct LatencyGraphView: View {
    let history: [PingResult]
    private let slotCount = 60

    var body: some View {
        let recent = Array(history.suffix(slotCount))
        let latencies = recent.compactMap(\.latency)
        let maxVal = max((latencies.max() ?? 100) * 1.2, 50)
        let padCount = slotCount - recent.count
        let slots: [PingResult?] = Array(repeating: nil, count: padCount) + recent

        Chart(Array(slots.enumerated()), id: \.offset) { index, result in
            if let result {
                if let latency = result.latency {
                    BarMark(
                        x: .value("Index", String(index)),
                        y: .value("Latency", latency)
                    )
                    .foregroundStyle(barColor(for: latency))
                } else {
                    BarMark(
                        x: .value("Index", String(index)),
                        y: .value("Latency", maxVal)
                    )
                    .foregroundStyle(.red.opacity(0.3))
                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.2))
                AxisValueLabel()
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .chartYScale(domain: 0...maxVal)
        .background(.secondary.opacity(0.1))
        .clipShape(.rect(cornerRadius: 6))
        .accessibilityElement()
        .accessibilityLabel(chartAccessibilityLabel)
    }

    private func barColor(for latency: Double) -> Color {
        if latency < ConnectionStatus.excellentThreshold { return .green }
        if latency < ConnectionStatus.goodThreshold { return .green.opacity(0.7) }
        if latency < ConnectionStatus.degradedThreshold { return .yellow }
        return .orange
    }

    private var chartAccessibilityLabel: String {
        let data = Array(history.suffix(slotCount))
        let latencies = data.compactMap(\.latency)
        guard !latencies.isEmpty else {
            return "Latency history chart, no data"
        }
        let avg = latencies.reduce(0, +) / Double(latencies.count)
        let failures = data.count - latencies.count
        var label = "Latency history chart, \(data.count) samples, average \(avg.formatted(.number.precision(.fractionLength(0)))) ms"
        if failures > 0 {
            label += ", \(failures) failed"
        }
        return label
    }
}
