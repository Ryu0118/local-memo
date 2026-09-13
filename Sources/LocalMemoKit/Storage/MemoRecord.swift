import Foundation

/// An in-memory view of a memo: its key, body, and metadata.
public struct MemoRecord: Equatable, Sendable {
    /// The memo's key.
    public let key: MemoKey
    /// The memo's body text.
    public let value: String
    /// The memo's TTL and timestamp metadata.
    public let metadata: MemoMetadata

    public init(key: MemoKey, value: String, metadata: MemoMetadata) {
        self.key = key
        self.value = value
        self.metadata = metadata
    }
}
