import Foundation

/// The persisted shape of `~/.localmemo/config.json`.
public struct LocalMemoConfig: Codable, Equatable, Sendable {
    /// Schema version; bumped when new keys are added, for forward-compat migrations.
    public var schemaVersion: Int
    /// TTL applied to `set` when `--ttl` is omitted, e.g. `"7d"` or `nil` for no expiry.
    public var defaultTTL: String?
    /// Directory memo bodies are stored under; `nil` means ``rootDirectory``.
    public var rootDirectory: String?
    /// How expired memos are treated by `get`/`list`. See ``ExpiredPolicy``.
    public var expiredPolicy: ExpiredPolicy
    /// Whether every command sweeps the current project's expired memos before running.
    public var autoCleanup: Bool
    /// Number of leading hex characters of the project path hash used as its directory name.
    public var hashLength: Int
    /// Maximum accepted size, in UTF-8 bytes, for a memo's value.
    public var maxValueBytes: Int
    /// Output format used when a command's `--json` flag is omitted. See ``DefaultOutput``.
    public var defaultOutput: DefaultOutput

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case defaultTTL = "default_ttl"
        case rootDirectory = "root_directory"
        case expiredPolicy = "expired_policy"
        case autoCleanup = "auto_cleanup"
        case hashLength = "hash_length"
        case maxValueBytes = "max_value_bytes"
        case defaultOutput = "default_output"
    }

    /// The built-in defaults used when `config.json` is missing or a key is absent.
    public static let `default` = LocalMemoConfig(
        schemaVersion: 1,
        defaultTTL: nil,
        rootDirectory: nil,
        expiredPolicy: .lazyDelete,
        autoCleanup: false,
        hashLength: ProjectPathHasher.defaultLength,
        maxValueBytes: 1_048_576,
        defaultOutput: .text,
    )

    public init(
        schemaVersion: Int,
        defaultTTL: String?,
        rootDirectory: String?,
        expiredPolicy: ExpiredPolicy,
        autoCleanup: Bool,
        hashLength: Int,
        maxValueBytes: Int,
        defaultOutput: DefaultOutput,
    ) {
        self.schemaVersion = schemaVersion
        self.defaultTTL = defaultTTL
        self.rootDirectory = rootDirectory
        self.expiredPolicy = expiredPolicy
        self.autoCleanup = autoCleanup
        self.hashLength = hashLength
        self.maxValueBytes = maxValueBytes
        self.defaultOutput = defaultOutput
    }
}
