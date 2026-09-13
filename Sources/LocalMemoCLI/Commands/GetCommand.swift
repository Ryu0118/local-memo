import ArgumentParser
import Foundation
import LocalMemoKit

package extension LocalMemoCommand {
    struct GetCommand: AsyncParsableCommand {
        @OptionGroup package var common: CommonOptions

        @Argument(help: "The memo key.")
        package var key: String

        @Flag(name: .long, help: "Return the value even if it has expired.")
        package var includeExpired = false

        package static let configuration = CommandConfiguration(
            commandName: "get",
            abstract: "Print a memo's value.",
        )

        package init() {}

        package func run() async throws {
            let store = try StoreFactory.make(common)
            do {
                let record = try store.get(key: key, includeExpired: includeExpired)
                if StoreFactory.wantsJSON(common, store: store) {
                    try CLIOutput.printJSON(GetResult(key: record.key.rawValue, value: record.value, expiresAt: record.metadata.expiresAt))
                } else {
                    print(record.value, terminator: "")
                }
            } catch {
                try MemoStoreErrorHandler.handle(error)
            }
        }
    }
}

/// The `--json` shape of a `get` result.
package struct GetResult: Codable {
    package let key: String
    package let value: String
    package let expiresAt: Date?
}
