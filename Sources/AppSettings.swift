import Foundation

@MainActor
class AppSettings: ObservableObject {
    private static let hostsKey = "pingHosts"
    private static let intervalKey = "pingInterval"

    @Published var hosts: [String] {
        didSet { UserDefaults.standard.set(hosts, forKey: Self.hostsKey) }
    }
    @Published var pingInterval: TimeInterval {
        didSet { UserDefaults.standard.set(pingInterval, forKey: Self.intervalKey) }
    }

    init() {
        if let saved = UserDefaults.standard.stringArray(forKey: Self.hostsKey), !saved.isEmpty {
            self.hosts = saved
        } else {
            self.hosts = ["8.8.8.8", "1.1.1.1"]
        }
        let savedInterval = UserDefaults.standard.double(forKey: Self.intervalKey)
        self.pingInterval = savedInterval > 0 ? savedInterval : 5.0
    }
}
