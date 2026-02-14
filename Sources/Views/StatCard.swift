import SwiftUI

struct StatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote.monospaced())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(.secondary.opacity(0.15))
        .clipShape(.rect(cornerRadius: 4))
        .accessibilityElement(children: .combine)
    }
}
