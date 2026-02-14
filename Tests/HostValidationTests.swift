import Testing
@testable import StatusDot

@Suite("Host validation")
struct HostValidationTests {
    @Test("Valid hosts are accepted", arguments: [
        "8.8.8.8",
        "1.1.1.1",
        "google.com",
        "sub.domain.example.com",
        "::1",
        "2001:db8::1",
        "fe80::1%en0",
    ])
    func validHosts(host: String) {
        #expect(AppSettings.isValidHost(host))
    }

    @Test("Invalid hosts are rejected", arguments: [
        "",
        "-badhost",
        "--double-dash",
        "host with spaces",
        "host;injection",
        "host&injection",
        "host|pipe",
    ])
    func invalidHosts(host: String) {
        #expect(!AppSettings.isValidHost(host))
    }

    @Test("Host exceeding 253 characters is rejected")
    func tooLongHost() {
        let long = String(repeating: "a", count: 254)
        #expect(!AppSettings.isValidHost(long))
    }

    @Test("Host at exactly 253 characters is accepted")
    func maxLengthHost() {
        let host = String(repeating: "a", count: 253)
        #expect(AppSettings.isValidHost(host))
    }
}
