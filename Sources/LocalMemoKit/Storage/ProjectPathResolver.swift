import FileManagerProtocol
import Foundation

/// Resolves the current project directory to a normalized, symlink-free absolute path string
/// suitable for hashing.
package struct ProjectPathResolver {
    private let fileManager: any FileManagerProtocol

    package init(fileManager: any FileManagerProtocol) {
        self.fileManager = fileManager
    }

    /// Normalizes `path` (or the current working directory when `path` is nil) by
    /// standardizing it and resolving symlinks, so `/tmp` and `/private/tmp` hash identically.
    package func normalizedPath(overriding path: String? = nil) -> String {
        let rawPath = path ?? fileManager.currentDirectoryPath
        let resolved = URL(filePath: rawPath)
            .standardizedFileURL
            .resolvingSymlinksInPath()
        var normalized = resolved.path(percentEncoded: false)
        if normalized.count > 1, normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        return normalized
    }
}
