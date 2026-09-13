import Foundation

/// A validated memo key, safe to use as a single path component.
public struct MemoKey: Equatable, Sendable, RawRepresentable {
    /// The validated key string.
    public let rawValue: String

    /// Validates `rawValue` against the key rules: 1-128 characters, only
    /// `[A-Za-z0-9._-]`, and no leading dot (reserved for the `.meta` directory).
    public init?(rawValue: String) {
        guard (1 ... 128).contains(rawValue.count) else { return nil }
        guard !rawValue.hasPrefix(".") else { return nil }
        let isValid = rawValue.allSatisfy {
            $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "." || $0 == "_" || $0 == "-")
        }
        guard isValid else { return nil }
        self.rawValue = rawValue
    }
}
