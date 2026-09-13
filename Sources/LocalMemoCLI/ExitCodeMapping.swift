import ArgumentParser
import Foundation
import LocalMemoKit

extension MemoStoreError {
    /// Maps a domain error to the CLI exit code documented for `local-memo`.
    var exitCode: ExitCode {
        switch self {
        case .invalidInput: ExitCode(2)
        case .alreadyExists: ExitCode(3)
        case .notFound: ExitCode(4)
        case .expired: ExitCode(5)
        case .io: ExitCode(6)
        }
    }
}

/// Namespace for translating a thrown ``MemoStoreError`` into process exit behavior.
package enum MemoStoreErrorHandler {
    /// Prints `error`'s message to stderr and throws its mapped ``ExitCode``, or rethrows an
    /// unrecognized error so ArgumentParser reports it as an unexpected failure (exit 1).
    package static func handle(_ error: Error) throws {
        guard let storeError = error as? MemoStoreError else {
            throw error
        }
        FileHandle.standardError.write(Data("Error: \(storeError.localizedDescription)\n".utf8))
        throw storeError.exitCode
    }
}
