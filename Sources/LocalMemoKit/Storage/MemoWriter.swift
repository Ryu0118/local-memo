import FileManagerProtocol
import Foundation

/// Writes a memo body and its sidecar metadata atomically (temp file, then rename).
package struct MemoWriter {
    private let fileManager: any FileManagerProtocol

    package init(fileManager: any FileManagerProtocol) {
        self.fileManager = fileManager
    }

    /// Writes `value` to `bodyURL` and `metadata` to `metadataURL`, creating parent
    /// directories as needed. Body is written before metadata, so a crash between the two
    /// leaves an unexpired-looking memo (body present, metadata absent) rather than losing data.
    package func write(value: String, metadata: MemoMetadata, bodyURL: URL, metadataURL: URL) throws {
        try writeAtomically(data: Data(value.utf8), to: bodyURL)

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let metadataData = try encoder.encode(metadata)
        try writeAtomically(data: metadataData, to: metadataURL)
    }

    private func writeAtomically(data: Data, to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try fileManager.createDirectory(atPath: directory.path(percentEncoded: false), withIntermediateDirectories: true)

        let tempURL = directory.appending(path: ".\(UUID().uuidString).tmp")
        guard fileManager.createFile(atPath: tempURL.path(percentEncoded: false), contents: data, attributes: nil) else {
            throw MemoStoreError.io("failed to write \(url.path(percentEncoded: false))")
        }
        // FileManager.moveItem refuses to overwrite an existing destination, so the previous
        // file (if any) is removed first. This isn't a true atomic replace, but local-memo has
        // no concurrent writers to race against.
        try? fileManager.removeItem(atPath: url.path(percentEncoded: false))
        do {
            try fileManager.moveItem(atPath: tempURL.path(percentEncoded: false), toPath: url.path(percentEncoded: false))
        } catch {
            throw MemoStoreError.io("failed to move into place: \(url.path(percentEncoded: false))")
        }
    }
}
