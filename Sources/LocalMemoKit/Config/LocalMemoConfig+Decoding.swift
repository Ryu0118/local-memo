import Foundation

public extension LocalMemoConfig {
    /// Decodes a partial `config.json`: any key absent from the document falls back to the
    /// matching field on ``LocalMemoConfig/default``, so old configs stay valid after new
    /// keys are added.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = LocalMemoConfig.default
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? fallback.schemaVersion
        defaultTTL = try container.decodeIfPresent(String.self, forKey: .defaultTTL) ?? fallback.defaultTTL
        rootDirectory = try container.decodeIfPresent(String.self, forKey: .rootDirectory) ?? fallback.rootDirectory
        expiredPolicy = try container.decodeIfPresent(ExpiredPolicy.self, forKey: .expiredPolicy) ?? fallback.expiredPolicy
        autoCleanup = try container.decodeIfPresent(Bool.self, forKey: .autoCleanup) ?? fallback.autoCleanup
        hashLength = try container.decodeIfPresent(Int.self, forKey: .hashLength) ?? fallback.hashLength
        maxValueBytes = try container.decodeIfPresent(Int.self, forKey: .maxValueBytes) ?? fallback.maxValueBytes
        defaultOutput = try container.decodeIfPresent(DefaultOutput.self, forKey: .defaultOutput) ?? fallback.defaultOutput
    }
}
