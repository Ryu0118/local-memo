import FileManagerProtocol
import Foundation

/// Loads `~/.localmemo/config.json`, falling back to built-in defaults for a missing file
/// or absent keys.
package struct ConfigLoader {
    private let fileManager: any FileManagerProtocol

    package init(fileManager: any FileManagerProtocol) {
        self.fileManager = fileManager
    }

    /// Loads the config at `configURL`, or returns ``LocalMemoConfig/default`` when the
    /// file does not exist.
    package func load(from configURL: URL) throws -> LocalMemoConfig {
        let path = configURL.path(percentEncoded: false)
        guard fileManager.fileExists(atPath: path) else {
            return .default
        }
        guard let data = fileManager.contents(atPath: path) else {
            throw MemoStoreError.io("failed to read config at \(path)")
        }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(LocalMemoConfig.self, from: data)
        } catch {
            throw MemoStoreError.invalidInput("invalid config.json: \(error.localizedDescription)")
        }
    }
}
