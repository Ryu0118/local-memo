import Foundation

/// Computes on-disk paths for a memo under `~/.localmemo/<hash>/`.
public struct MemoFileLayout: Sendable {
    /// The directory memo bodies are stored under (`~/.localmemo` or `config.root_directory`).
    public let rootDirectory: URL
    /// The one-way project path hash naming this project's memo directory.
    public let projectHash: String

    public init(rootDirectory: URL, projectHash: String) {
        self.rootDirectory = rootDirectory
        self.projectHash = projectHash
    }

    /// The `<hash>/` directory holding this project's memos.
    public var projectDirectory: URL {
        rootDirectory.appending(path: projectHash, directoryHint: .isDirectory)
    }

    /// The `<hash>/.meta/` directory holding sidecar metadata.
    public var metadataDirectory: URL {
        projectDirectory.appending(path: ".meta", directoryHint: .isDirectory)
    }

    /// The `<hash>/<key>.txt` body path.
    public func bodyURL(for key: MemoKey) -> URL {
        projectDirectory.appending(path: "\(key.rawValue).txt")
    }

    /// The `<hash>/.meta/<key>.json` metadata path.
    public func metadataURL(for key: MemoKey) -> URL {
        metadataDirectory.appending(path: "\(key.rawValue).json")
    }
}
