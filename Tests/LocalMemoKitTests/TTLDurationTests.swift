import Foundation
@testable import LocalMemoKit
import Testing

struct TTLDurationTests {
    @Test("never and 0 parse to .never")
    func neverForms() {
        #expect(TTLDuration.parse("never") == .never)
        #expect(TTLDuration.parse("0") == .never)
    }

    @Test(
        "parses single-unit durations to seconds",
        arguments: [("30s", 30), ("30m", 1800), ("2h", 7200), ("7d", 604_800), ("1w", 604_800)],
    )
    func singleUnit(_ input: String, _ expectedSeconds: Int) {
        #expect(TTLDuration.parse(input) == .seconds(expectedSeconds))
    }

    @Test("parses concatenated multi-unit durations")
    func multiUnit() {
        #expect(TTLDuration.parse("1d12h") == .seconds(86400 + 12 * 3600))
    }

    @Test(
        "rejects malformed input",
        arguments: ["", "abc", "-5m", "5", "5x", "5m5", "m5"],
    )
    func rejectsMalformed(_ input: String) {
        #expect(TTLDuration.parse(input) == nil)
    }

    @Test("expirationDate is nil for .never")
    func neverHasNoExpiration() {
        #expect(TTLDuration.never.expirationDate(from: Date()) == nil)
    }

    @Test("expirationDate adds seconds to now")
    func expirationDateAddsSeconds() {
        let now = Date(timeIntervalSince1970: 1000)
        let expiration = TTLDuration.seconds(60).expirationDate(from: now)
        #expect(expiration == Date(timeIntervalSince1970: 1060))
    }
}
