import Foundation

/// The outcome of checking a memo against its expiration policy.
package enum ExpirationCheck: Equatable {
    /// Not expired, or `.keep` policy is in effect.
    case alive
    /// Expired under `.hide`: keep the files, but treat as invisible/not-found by default.
    case hiddenExpired
    /// Expired under `.lazy_delete`: the caller must physically delete the memo now.
    case deleteNow
}

/// Decides how an expired memo should be treated based on ``ExpiredPolicy``.
package enum ExpirationPolicy {
    /// Evaluates `metadata` against `policy` as of `now`.
    package static func check(metadata: MemoMetadata, policy: ExpiredPolicy, now: Date) -> ExpirationCheck {
        guard metadata.isExpired(asOf: now) else { return .alive }
        return switch policy {
        case .keep:.alive
        case .hide:.hiddenExpired
        case .lazyDelete:.deleteNow
        }
    }
}
