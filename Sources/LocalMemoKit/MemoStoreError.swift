import Foundation

/// Domain errors surfaced by ``MemoStore`` and its runners.
public enum MemoStoreError: Error, LocalizedError, Equatable {
    case invalidInput(String)
    case alreadyExists(key: String)
    case notFound(key: String)
    case expired(key: String)
    case io(String)

    public var errorDescription: String? {
        switch self {
        case let .invalidInput(message):
            message
        case let .alreadyExists(key):
            "memo '\(key)' already exists"
        case let .notFound(key):
            "memo '\(key)' not found"
        case let .expired(key):
            "memo '\(key)' has expired"
        case let .io(message):
            message
        }
    }
}
