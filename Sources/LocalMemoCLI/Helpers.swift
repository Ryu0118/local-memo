import Foundation
import LocalMemoKit

/// Helpers for resolving CLI path arguments.
package enum CLIPath {
    /// Resolves a possibly-relative CLI path argument against a base directory.
    package static func resolve(_ path: String, relativeToDirectory base: String) -> URL {
        URL(filePath: path, relativeTo: URL(filePath: base, directoryHint: .isDirectory)).standardizedFileURL
    }
}

/// Helpers for command output that should share a consistent style.
package enum CLIOutput {
    /// Prints a value as stable, pretty-printed JSON to stdout.
    package static func printJSON(_ value: some Encodable) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        if let string = String(data: data, encoding: .utf8) {
            print(string)
        }
    }
}
