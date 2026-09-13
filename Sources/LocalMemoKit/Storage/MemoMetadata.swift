import Foundation

/// Sidecar metadata stored alongside a memo's `.txt` body under `.meta/<key>.json`.
public struct MemoMetadata: Codable, Equatable, Sendable {
    /// When the memo was first saved.
    public let createdAt: Date
    /// When the memo was last written (created or overwritten).
    public var updatedAt: Date
    /// When the memo expires, or `nil` for no expiry.
    public var expiresAt: Date?

    public init(createdAt: Date, updatedAt: Date, expiresAt: Date?) {
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.expiresAt = expiresAt
    }

    /// Whether this metadata is expired as of `now`.
    public func isExpired(asOf now: Date) -> Bool {
        guard let expiresAt else { return false }
        return expiresAt <= now
    }
}
