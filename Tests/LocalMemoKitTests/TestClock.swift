import Foundation

/// A mutable clock for tests that need to advance time deterministically (e.g. TTL expiry).
/// Tests run serially within a suite, so unsynchronized mutation is safe here.
final class TestClock: @unchecked Sendable {
    var now: Date

    init(now: Date = Date(timeIntervalSince1970: 0)) {
        self.now = now
    }

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}
