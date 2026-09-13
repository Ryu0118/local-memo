import FileManagerProtocol
import Foundation

public extension MemoStore {
    /// Reads the memo at `key`. When the memo is expired under `.lazy_delete`, its files are
    /// deleted first and ``MemoStoreError/expired(key:)`` is thrown; under `.hide` the same
    /// error is thrown without deleting (unless `includeExpired` is set); under `.keep` the
    /// value is returned regardless of expiration.
    func get(key rawKey: String, includeExpired: Bool) throws -> MemoRecord {
        let key = try MemoKeyValidator.validate(rawKey)
        let config = try loadConfig()
        let layout = fileLayout(config: config)
        let bodyURL = layout.bodyURL(for: key)
        let metadataURL = layout.metadataURL(for: key)
        let reader = MemoReader(fileManager: fileManager)

        guard let value = reader.readBody(at: bodyURL) else {
            throw MemoStoreError.notFound(key: rawKey)
        }
        guard let metadata = try reader.readMetadata(at: metadataURL) else {
            return MemoRecord(key: key, value: value, metadata: MemoMetadata(createdAt: now(), updatedAt: now(), expiresAt: nil))
        }

        if includeExpired {
            return MemoRecord(key: key, value: value, metadata: metadata)
        }

        switch ExpirationPolicy.check(metadata: metadata, policy: config.expiredPolicy, now: now()) {
        case .alive:
            return MemoRecord(key: key, value: value, metadata: metadata)
        case .hiddenExpired:
            throw MemoStoreError.expired(key: rawKey)
        case .deleteNow:
            try? fileManager.removeItem(atPath: bodyURL.path(percentEncoded: false))
            try? fileManager.removeItem(atPath: metadataURL.path(percentEncoded: false))
            throw MemoStoreError.expired(key: rawKey)
        }
    }
}
