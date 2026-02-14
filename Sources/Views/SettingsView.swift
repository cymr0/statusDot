import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @Binding var showSettings: Bool
    @State private var newHost = ""

    private let intervalOptions: [(String, TimeInterval)] = [
        ("2s", 2), ("5s", 5), ("10s", 10), ("30s", 30), ("60s", 60)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button {
                    showSettings = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                Text("Settings")
                    .font(.headline)
                Spacer()
            }

            Divider()

            Text("Ping Targets")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(Array(settings.hosts.enumerated()), id: \.offset) { index, host in
                HStack {
                    Text(host)
                        .font(.system(size: 12, design: .monospaced))
                    Spacer()
                    Button {
                        settings.hosts.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red.opacity(0.7))
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }

            HStack {
                TextField("Add host or IP...", text: $newHost)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                    .onSubmit { addHost() }
                Button {
                    addHost()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green.opacity(0.7))
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .disabled(newHost.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Divider()

            Text("Ping Interval")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                ForEach(intervalOptions, id: \.1) { label, value in
                    Button(label) {
                        settings.pingInterval = value
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: settings.pingInterval == value ? .bold : .regular))
                    .foregroundColor(settings.pingInterval == value ? .accentColor : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(settings.pingInterval == value
                                  ? Color.accentColor.opacity(0.15)
                                  : Color.clear)
                    )
                }
            }

            Spacer()
        }
    }

    private func addHost() {
        let host = newHost.trimmingCharacters(in: .whitespaces)
        guard !host.isEmpty, !settings.hosts.contains(host) else { return }
        settings.hosts.append(host)
        newHost = ""
    }
}
