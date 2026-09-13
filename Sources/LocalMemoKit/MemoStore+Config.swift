import FileManagerProtocol
import Foundation

public extension MemoStore {
    /// Writes ``LocalMemoConfig/default`` to `config.json`. Throws
    /// ``MemoStoreError/alreadyExists(key:)`` when a file is already there and `force` is false.
    func initConfig(force: Bool) throws -> LocalMemoConfig {
        if !force, fileManager.fileExists(atPath: configURL.path(percentEncoded: false)) {
            throw MemoStoreError.alreadyExists(key: "config.json")
        }
        try ConfigWriter(fileManager: fileManager).write(.default, to: configURL)
        return .default
    }

    /// Updates a single config key from its raw string form and persists the result. Throws
    /// ``MemoStoreError/invalidInput(_:)`` when changing `hash_length` while memos already
    /// exist under the current hash (that would orphan them).
    func setConfigValue(key: String, rawValue: String) throws -> LocalMemoConfig {
        var config = try loadConfig()
        if key == "hash_length" {
            let currentLayout = fileLayout(config: config)
            let hasMemos = !((try? listKeys(layout: currentLayout)) ?? []).isEmpty
            guard !hasMemos else {
                throw MemoStoreError.invalidInput("cannot change hash_length while memos exist for the current project")
            }
        }
        try ConfigValueApplier.apply(key: key, rawValue: rawValue, to: &config)
        try ConfigWriter(fileManager: fileManager).write(config, to: configURL)
        return config
    }

    /// The absolute path to `config.json`.
    var configPath: String {
        configURL.path(percentEncoded: false)
    }
}
