import FileManagerProtocol
import Foundation

public extension MemoStore {
    /// One row in a `list` result.
    struct MemoListEntry: Sendable, Codable {
        /// The memo's key.
        public let key: String
        /// When the memo was first saved.
        public let createdAt: Date
        /// When the memo expires, or `nil` for no expiry.
        public let expiresAt: Date?
        /// Whether this entry is past its `expiresAt` (only ever true when `showExpired` was set).
        public let isExpired: Bool
    }

    /// Lists memos in the current project. Under `.lazy_delete`, expired entries encountered
    /// during listing are deleted from disk as a side effect (mirrors `get`'s behavior) unless
    /// `showExpired` is set, in which case they are reported instead of deleted.
    func list(showExpired: Bool) throws -> [MemoListEntry] {
        let config = try loadConfig()
        let layout = fileLayout(config: config)
        let reader = MemoReader(fileManager: fileManager)
        var entries: [MemoListEntry] = []

        for rawKey in try listKeys(layout: layout) {
            guard let key = MemoKey(rawValue: rawKey) else { continue }
            let bodyURL = layout.bodyURL(for: key)
            let metadataURL = layout.metadataURL(for: key)
            guard let metadata = try reader.readMetadata(at: metadataURL) else {
                entries.append(MemoListEntry(key: rawKey, createdAt: now(), expiresAt: nil, isExpired: false))
                continue
            }

            let check = ExpirationPolicy.check(metadata: metadata, policy: config.expiredPolicy, now: now())
            switch check {
            case .alive:
                entries.append(MemoListEntry(key: rawKey, createdAt: metadata.createdAt, expiresAt: metadata.expiresAt, isExpired: false))
            case .hiddenExpired:
                if showExpired {
                    entries.append(MemoListEntry(key: rawKey, createdAt: metadata.createdAt, expiresAt: metadata.expiresAt, isExpired: true))
                }
            case .deleteNow:
                if showExpired {
                    entries.append(MemoListEntry(key: rawKey, createdAt: metadata.createdAt, expiresAt: metadata.expiresAt, isExpired: true))
                } else {
                    try? fileManager.removeItem(atPath: bodyURL.path(percentEncoded: false))
                    try? fileManager.removeItem(atPath: metadataURL.path(percentEncoded: false))
                }
            }
        }
        return entries.sorted { $0.key < $1.key }
    }
}

package extension MemoStore {
    /// The raw keys present in a project's directory (`.txt` files only).
    func listKeys(layout: MemoFileLayout) throws -> [String] {
        let directoryPath = layout.projectDirectory.path(percentEncoded: false)
        guard fileManager.fileExists(atPath: directoryPath) else { return [] }
        return try fileManager.contentsOfDirectory(atPath: directoryPath)
            .filter { $0.hasSuffix(".txt") }
            .map { String($0.dropLast(4)) }
    }
}
