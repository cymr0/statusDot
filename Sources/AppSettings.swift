import Foundation
import Observation

@Observable
@MainActor
class AppSettings {
    private static let hostsKey = "pingHosts"
    private static let intervalKey = "pingInterval"

    var hosts: [String] {
        didSet { UserDefaults.standard.set(hosts, forKey: Self.hostsKey) }
    }
    var pingInterval: TimeInterval {
        didSet { UserDefaults.standard.set(pingInterval, forKey: Self.intervalKey) }
    }

    private nonisolated static let allowedHostCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-:%"))

    nonisolated static func isValidHost(_ host: String) -> Bool {
        !host.isEmpty
        && host.count <= 253
        && !host.hasPrefix("-")
        && host.unicodeScalars.allSatisfy { allowedHostCharacters.contains($0) }
    }

    init() {
        if let saved = UserDefaults.standard.stringArray(forKey: Self.hostsKey)?.filter(Self.isValidHost), !saved.isEmpty {
            self.hosts = saved
        } else {
            self.hosts = ["8.8.8.8", "1.1.1.1"]
        }
        let savedInterval = UserDefaults.standard.double(forKey: Self.intervalKey)
        self.pingInterval = savedInterval > 0 ? savedInterval : 5.0
    }
}
