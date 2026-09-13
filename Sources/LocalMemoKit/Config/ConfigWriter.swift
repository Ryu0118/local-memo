import FileManagerProtocol
import Foundation

/// Writes `~/.localmemo/config.json` atomically (write to a temp file, then rename).
package struct ConfigWriter {
    private let fileManager: any FileManagerProtocol

    package init(fileManager: any FileManagerProtocol) {
        self.fileManager = fileManager
    }

    /// Serializes `config` and atomically replaces the file at `configURL`.
    package func write(_ config: LocalMemoConfig, to configURL: URL) throws {
        let directory = configURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            atPath: directory.path(percentEncoded: false),
            withIntermediateDirectories: true,
            attributes: nil,
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)

        let tempURL = directory.appending(path: ".config.json.tmp-\(UUID().uuidString)")
        guard fileManager.createFile(atPath: tempURL.path(percentEncoded: false), contents: data, attributes: nil) else {
            throw MemoStoreError.io("failed to write config to \(tempURL.path(percentEncoded: false))")
        }
        // FileManager.moveItem refuses to overwrite an existing destination.
        try? fileManager.removeItem(atPath: configURL.path(percentEncoded: false))
        do {
            try fileManager.moveItem(atPath: tempURL.path(percentEncoded: false), toPath: configURL.path(percentEncoded: false))
        } catch {
            throw MemoStoreError.io("failed to move config into place: \(error.localizedDescription)")
        }
    }
}
