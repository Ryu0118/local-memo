import FileManagerProtocol
import Foundation

public extension MemoStore {
    /// Deletes the memos for `keys`. Returns the keys that were actually deleted;
    /// keys not present on disk are silently skipped (callers report the gap themselves).
    func delete(keys rawKeys: [String]) throws -> [String] {
        let config = try loadConfig()
        let layout = fileLayout(config: config)
        var deleted: [String] = []
        for rawKey in rawKeys {
            let key = try MemoKeyValidator.validate(rawKey)
            let bodyURL = layout.bodyURL(for: key)
            guard fileManager.fileExists(atPath: bodyURL.path(percentEncoded: false)) else { continue }
            try fileManager.removeItem(atPath: bodyURL.path(percentEncoded: false))
            try? fileManager.removeItem(atPath: layout.metadataURL(for: key).path(percentEncoded: false))
            deleted.append(rawKey)
        }
        return deleted
    }

    /// Deletes every memo in the current project, returning the keys that were removed.
    func deleteAll() throws -> [String] {
        let config = try loadConfig()
        let layout = fileLayout(config: config)
        let keys = (try? listKeys(layout: layout)) ?? []
        return try delete(keys: keys)
    }
}
