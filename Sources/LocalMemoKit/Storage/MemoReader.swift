import FileManagerProtocol
import Foundation

/// Reads a memo body and its sidecar metadata.
package struct MemoReader {
    private let fileManager: any FileManagerProtocol

    package init(fileManager: any FileManagerProtocol) {
        self.fileManager = fileManager
    }

    /// Reads the raw body bytes at `bodyURL`, or `nil` when it doesn't exist.
    package func readBody(at bodyURL: URL) -> String? {
        guard let data = fileManager.contents(atPath: bodyURL.path(percentEncoded: false)) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Reads and decodes metadata at `metadataURL`. Returns `nil` when the file is absent
    /// (a body with no metadata is treated as an un-expiring memo by callers).
    package func readMetadata(at metadataURL: URL) throws -> MemoMetadata? {
        guard let data = fileManager.contents(atPath: metadataURL.path(percentEncoded: false)) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MemoMetadata.self, from: data)
    }
}
