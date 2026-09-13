import FileManagerProtocol
import Foundation

public extension MemoStore {
    /// The outcome of a `set` operation.
    struct SetOutcome: Sendable, Codable {
        /// The memo's key.
        public let key: String
        /// Absolute path to the written `.txt` body.
        public let bodyPath: String
        /// When the memo expires, or `nil` for no expiry.
        public let expiresAt: Date?
        /// Whether this call replaced a live (non-expired) existing memo.
        public let overwritten: Bool
    }

    /// Writes `value` under `key`, applying `ttl` (or the config default when `ttl` is nil).
    /// Throws ``MemoStoreError/alreadyExists(key:)`` when `allowOverwrite` is false and the
    /// key already holds a live memo.
    func set(key rawKey: String, value: String, ttl rawTTL: String?, allowOverwrite: Bool) throws -> SetOutcome {
        let key = try MemoKeyValidator.validate(rawKey)
        let config = try loadConfig()
        try SetArgumentsValidator.validateSize(value, maxBytes: config.maxValueBytes)
        let ttl = try SetArgumentsValidator.resolveTTL(raw: rawTTL, fallback: config.defaultTTL)

        let layout = fileLayout(config: config)
        let bodyURL = layout.bodyURL(for: key)
        let metadataURL = layout.metadataURL(for: key)
        let reader = MemoReader(fileManager: fileManager)

        let currentTime = now()
        let existingBody = reader.readBody(at: bodyURL)
        let existingMetadata = (try? reader.readMetadata(at: metadataURL)) ?? nil
        // A memo the configured policy would already treat as gone (hiddenExpired/deleteNow)
        // is treated as absent here too: it neither blocks --no-overwrite nor carries its
        // createdAt forward, since a fresh `set` after expiry is conceptually a new memo.
        let existingIsLive: Bool = if existingBody != nil, let existingMetadata {
            ExpirationPolicy.check(metadata: existingMetadata, policy: config.expiredPolicy, now: currentTime) == .alive
        } else {
            existingBody != nil
        }

        if existingIsLive, !allowOverwrite {
            throw MemoStoreError.alreadyExists(key: rawKey)
        }

        let createdAt = existingIsLive ? (existingMetadata?.createdAt ?? currentTime) : currentTime
        let metadata = MemoMetadata(createdAt: createdAt, updatedAt: currentTime, expiresAt: ttl.expirationDate(from: currentTime))

        try MemoWriter(fileManager: fileManager).write(value: value, metadata: metadata, bodyURL: bodyURL, metadataURL: metadataURL)

        return SetOutcome(
            key: rawKey,
            bodyPath: bodyURL.path(percentEncoded: false),
            expiresAt: metadata.expiresAt,
            overwritten: existingIsLive,
        )
    }
}
