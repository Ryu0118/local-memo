import Foundation

/// A parsed TTL expression such as `30m`, `2h`, `7d`, or `never`.
package enum TTLDuration: Equatable {
    case never
    case seconds(Int)

    static let unitSeconds: [Character: Int] = [
        "s": 1,
        "m": 60,
        "h": 3600,
        "d": 86400,
        "w": 604_800,
    ]

    /// Computes the expiration date from `now`, or `nil` when the TTL is `never`.
    package func expirationDate(from now: Date) -> Date? {
        switch self {
        case .never:
            nil
        case let .seconds(value):
            now.addingTimeInterval(TimeInterval(value))
        }
    }
}
