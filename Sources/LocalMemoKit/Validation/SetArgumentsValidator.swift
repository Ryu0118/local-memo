import Foundation

/// Validates the arguments to `set` before ``MemoStore`` touches the filesystem.
package enum SetArgumentsValidator {
    /// Parses a raw `--ttl` string (or `nil`, falling back to `fallback`) into a ``TTLDuration``.
    package static func resolveTTL(raw: String?, fallback: String?) throws -> TTLDuration {
        guard let source = raw ?? fallback else {
            return .never
        }
        guard let ttl = TTLDuration.parse(source) else {
            throw MemoStoreError.invalidInput("invalid TTL '\(source)': expected forms like 30m, 2h, 7d, or never")
        }
        return ttl
    }

    /// Ensures `value` doesn't exceed the configured byte limit.
    package static func validateSize(_ value: String, maxBytes: Int) throws {
        guard value.utf8.count <= maxBytes else {
            throw MemoStoreError.invalidInput("value exceeds max_value_bytes (\(maxBytes))")
        }
    }
}
