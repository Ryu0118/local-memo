import FileManagerProtocol
import Foundation

public extension MemoStore {
    /// A memo identified as expired during `cleanup`, before (`dryRun`) or after deletion.
    struct CleanupEntry: Sendable, Codable {
        /// The project hash the memo belonged to.
        public let projectHash: String
        /// The memo's key.
        public let key: String
    }

    /// Deletes every expired memo. Scoped to the current project unless `allProjects` is set,
    /// in which case every `<hash>/` directory under the root is scanned. `dryRun` reports
    /// what would be deleted without touching the filesystem.
    func cleanup(allProjects: Bool, dryRun: Bool) throws -> [CleanupEntry] {
        let config = try loadConfig()
        let reader = MemoReader(fileManager: fileManager)
        let memoRoot = config.rootDirectory.map { URL(filePath: $0) } ?? rootDirectory
        let hashes = allProjects ? try projectHashes(memoRoot: memoRoot) : [fileLayout(config: config).projectHash]

        var removed: [CleanupEntry] = []
        for hash in hashes {
            let layout = MemoFileLayout(rootDirectory: memoRoot, projectHash: hash)
            for rawKey in try listKeys(layout: layout) {
                guard let key = MemoKey(rawValue: rawKey) else { continue }
                let metadataURL = layout.metadataURL(for: key)
                guard let metadata = try reader.readMetadata(at: metadataURL), metadata.isExpired(asOf: now()) else { continue }

                if !dryRun {
                    try? fileManager.removeItem(atPath: layout.bodyURL(for: key).path(percentEncoded: false))
                    try? fileManager.removeItem(atPath: metadataURL.path(percentEncoded: false))
                }
                removed.append(CleanupEntry(projectHash: hash, key: rawKey))
            }
        }
        return removed
    }

    private func projectHashes(memoRoot: URL) throws -> [String] {
        let rootPath = memoRoot.path(percentEncoded: false)
        guard fileManager.fileExists(atPath: rootPath) else { return [] }
        return try fileManager.contentsOfDirectory(atPath: rootPath).filter { entry in
            var isDirectory: ObjCBool = false
            let entryPath = memoRoot.appending(path: entry).path(percentEncoded: false)
            return fileManager.fileExists(atPath: entryPath, isDirectory: &isDirectory) && isDirectory.boolValue
        }
    }
}
