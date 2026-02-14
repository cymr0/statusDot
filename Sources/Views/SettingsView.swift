import SwiftUI

struct SettingsView: View {
    var settings: AppSettings
    @Binding var showSettings: Bool
    @State private var newHost = ""

    private let intervalOptions: [(String, TimeInterval)] = [
        ("2s", 2), ("5s", 5), ("10s", 10), ("30s", 30), ("60s", 60)
    ]

    private var validationMessage: String? {
        let trimmed = newHost.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if settings.hosts.contains(trimmed) { return "Host already added" }
        if trimmed.hasPrefix("-") { return "Host cannot start with a dash" }
        if trimmed.count > 253 { return "Host too long" }
        if !AppSettings.isValidHost(trimmed) { return "Invalid characters in host" }
        return nil
    }

    private var isAddDisabled: Bool {
        let trimmed = newHost.trimmingCharacters(in: .whitespaces)
        return !AppSettings.isValidHost(trimmed) || settings.hosts.contains(trimmed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button("Back", systemImage: "chevron.left") {
                    showSettings = false
                }
                .keyboardShortcut(",", modifiers: .command)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                Text("Settings")
                    .font(.headline)
                Spacer()
            }

            Divider()

            Text("Ping Targets")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(settings.hosts, id: \.self) { host in
                HStack {
                    Text(host)
                        .font(.caption.monospaced())
                    Spacer()
                    Button("Remove", systemImage: "minus.circle.fill") {
                        settings.hosts.removeAll { $0 == host }
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.red.opacity(0.7))
                    .font(.caption)
                    .accessibilityLabel("Remove \(host)")
                }
                .padding(.vertical, 2)
            }

            HStack {
                TextField("Add host or IP...", text: $newHost)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption.monospaced())
                    .onSubmit { addHost() }
                Button("Add", systemImage: "plus.circle.fill") {
                    addHost()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.green.opacity(0.7))
                .font(.caption)
                .disabled(isAddDisabled)
            }

            if let message = validationMessage {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }

            Divider()

            Text("Ping Interval")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(intervalOptions, id: \.1) { label, value in
                    Button(label) {
                        settings.pingInterval = value
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .bold(settings.pingInterval == value)
                    .foregroundStyle(settings.pingInterval == value ? Color.accentColor : .secondary)
                    .accessibilityAddTraits(settings.pingInterval == value ? .isSelected : [])
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        settings.pingInterval == value
                            ? Color.accentColor.opacity(0.15)
                            : Color.clear,
                        in: .rect(cornerRadius: 4)
                    )
                }
            }

            Spacer()
        }
    }

    private func addHost() {
        let host = newHost.trimmingCharacters(in: .whitespaces)
        guard AppSettings.isValidHost(host), !settings.hosts.contains(host) else { return }
        settings.hosts.append(host)
        newHost = ""
    }
}
