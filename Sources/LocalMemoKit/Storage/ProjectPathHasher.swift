import CryptoKit
import Foundation

/// Derives the one-way, non-reversible directory hash used to scope memos to a project path.
package enum ProjectPathHasher {
    /// Number of leading hex characters kept from the SHA-256 digest.
    package static let defaultLength = 16

    /// Hashes an already-normalized absolute path string. The result cannot be reversed back
    /// to the original path: no mapping from hash to path is ever stored.
    package static func hash(normalizedPath: String, length: Int = defaultLength) -> String {
        let digest = SHA256.hash(data: Data(normalizedPath.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return String(hex.prefix(length))
    }
}
