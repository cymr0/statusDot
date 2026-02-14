import SwiftUI

struct LatencyGraphView: View {
    let history: [PingResult]

    var body: some View {
        GeometryReader { _ in
            let data = Array(history.suffix(60))
            let latencies = data.compactMap(\.latency)
            let maxVal = max((latencies.max() ?? 100) * 1.2, 50)

            Canvas { context, size in
                let barWidth = max((size.width - 30) / CGFloat(max(data.count, 1)), 2)
                let layout = ChartLayout(chartLeft: 28, barWidth: barWidth, maxVal: maxVal)

                drawGridLines(context: context, size: size, layout: layout)
                drawBars(context: context, size: size, data: data, layout: layout)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        .cornerRadius(6)
    }

    private struct ChartLayout {
        let chartLeft: CGFloat
        let barWidth: CGFloat
        let maxVal: Double
    }

    private func drawGridLines(
        context: GraphicsContext,
        size: CGSize,
        layout: ChartLayout
    ) {
        for row in 0...3 {
            let yPos = size.height - (size.height * CGFloat(row) / 3.0)
            let val = layout.maxVal * Double(row) / 3.0

            var linePath = Path()
            linePath.move(to: CGPoint(x: layout.chartLeft, y: yPos))
            linePath.addLine(to: CGPoint(x: size.width, y: yPos))
            context.stroke(linePath, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)

            let label = Text(String(format: "%.0f", val))
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(.secondary)
            context.draw(label, at: CGPoint(x: 14, y: yPos), anchor: .trailing)
        }
    }

    private func drawBars(
        context: GraphicsContext,
        size: CGSize,
        data: [PingResult],
        layout: ChartLayout
    ) {
        for (index, result) in data.enumerated() {
            let xPos = layout.chartLeft + CGFloat(index) * layout.barWidth
            if let latency = result.latency {
                let barHeight = max(CGFloat(latency / layout.maxVal) * size.height, 2)
                let rect = CGRect(
                    x: xPos,
                    y: size.height - barHeight,
                    width: max(layout.barWidth - 1, 1),
                    height: barHeight
                )
                let color: Color = latency < 50 ? .green :
                                   latency < 100 ? .green.opacity(0.7) :
                                   latency < 200 ? .yellow : .orange
                context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(color))
            } else {
                let rect = CGRect(
                    x: xPos,
                    y: 0,
                    width: max(layout.barWidth - 1, 1),
                    height: size.height
                )
                context.fill(
                    Path(roundedRect: rect, cornerRadius: 1),
                    with: .color(.red.opacity(0.3))
                )
            }
        }
    }
}
