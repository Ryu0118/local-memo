import Foundation

/// Validates a raw CLI key argument into a ``MemoKey``.
package enum MemoKeyValidator {
    /// Parses `raw` into a ``MemoKey``, throwing ``MemoStoreError/invalidInput(_:)`` when it
    /// violates the key rules (length, allowed characters, no leading dot).
    package static func validate(_ raw: String) throws -> MemoKey {
        guard let key = MemoKey(rawValue: raw) else {
            throw MemoStoreError.invalidInput(
                "invalid key '\(raw)': keys must be 1-128 characters of [A-Za-z0-9._-] and cannot start with '.'",
            )
        }
        return key
    }
}
