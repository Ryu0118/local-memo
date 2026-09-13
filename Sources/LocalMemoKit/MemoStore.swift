import FileManagerProtocol
import Foundation

/// The application-service facade for reading, writing, and expiring memos.
///
/// Both the CLI's runners and tests go through this type; it resolves the project hash,
/// loads config, and applies TTL policy so no other layer duplicates that logic.
public struct MemoStore: Sendable {
    /// `~/.localmemo` (or `$LOCALMEMO_HOME`), resolved once at init.
    public let rootDirectory: URL
    /// The file system abstraction used for all I/O, injectable for tests.
    package let fileManager: any FileManagerProtocol
    /// The clock used for TTL calculations, injectable for tests.
    package let now: @Sendable () -> Date
    /// The directory to scope memos to, or `nil` to use the current working directory.
    package let projectPath: String?

    public init(
        fileManager: any FileManagerProtocol = FileManager.default,
        rootDirectory: URL? = nil,
        projectPath: String? = nil,
        now: @escaping @Sendable () -> Date = { Date() },
    ) {
        self.fileManager = fileManager
        self.rootDirectory = rootDirectory ?? Self.resolveRootDirectory(fileManager: fileManager)
        self.projectPath = projectPath
        self.now = now
    }

    /// The home directory, respecting the `HOME` environment variable (tests may override it).
    package static func resolveHomeDirectory() -> URL {
        if let homePath = ProcessInfo.processInfo.environment["HOME"] {
            return URL(filePath: homePath)
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }

    /// `~/.localmemo`, or `$LOCALMEMO_HOME` when set.
    package static func resolveRootDirectory(fileManager: any FileManagerProtocol) -> URL {
        if let override = ProcessInfo.processInfo.environment["LOCALMEMO_HOME"] {
            return URL(filePath: override)
        }
        return resolveHomeDirectory().appending(path: ".localmemo", directoryHint: .isDirectory)
    }

    /// The absolute path to `config.json`, always under ``rootDirectory``.
    package var configURL: URL {
        rootDirectory.appending(path: "config.json")
    }

    /// Loads the effective config (file contents merged over defaults).
    public func loadConfig() throws -> LocalMemoConfig {
        try ConfigLoader(fileManager: fileManager).load(from: configURL)
    }

    /// Computes this run's project hash and file layout from `projectPath` (or cwd).
    ///
    /// Memo bodies live under `config.rootDirectory` when set (letting the store point
    /// elsewhere than `~/.localmemo`), while `config.json` itself always stays at
    /// ``rootDirectory`` so a moved memo root doesn't strand the config that describes it.
    public func fileLayout(config: LocalMemoConfig) -> MemoFileLayout {
        let resolver = ProjectPathResolver(fileManager: fileManager)
        let normalized = resolver.normalizedPath(overriding: projectPath)
        let hash = ProjectPathHasher.hash(normalizedPath: normalized, length: config.hashLength)
        let memoRoot = config.rootDirectory.map { URL(filePath: $0) } ?? rootDirectory
        return MemoFileLayout(rootDirectory: memoRoot, projectHash: hash)
    }
}
