import ArgumentParser
import Foundation
import LocalMemoKit

package extension LocalMemoCommand {
    struct SetCommand: AsyncParsableCommand {
        @OptionGroup package var common: CommonOptions

        @Argument(help: "The memo key.")
        package var key: String

        @Argument(help: "The memo value. Omit (or pass '-') to read from stdin.")
        package var value: String?

        @Option(name: .long, help: "TTL for this memo, e.g. 30m, 2h, 7d, or never. Defaults to config's default_ttl.")
        package var ttl: String?

        @Flag(name: .long, help: "Fail instead of overwriting an existing key.")
        package var noOverwrite = false

        package static let configuration = CommandConfiguration(
            commandName: "set",
            abstract: "Save a memo for the current project.",
        )

        package init() {}

        package func run() async throws {
            let resolvedValue = try resolveValue()
            let store = try StoreFactory.make(common)
            do {
                let outcome = try store.set(key: key, value: resolvedValue, ttl: ttl, allowOverwrite: !noOverwrite)
                if StoreFactory.wantsJSON(common, store: store) {
                    try CLIOutput.printJSON(outcome)
                } else {
                    print("saved '\(outcome.key)' -> \(outcome.bodyPath)")
                }
            } catch {
                try MemoStoreErrorHandler.handle(error)
            }
        }

        private func resolveValue() throws -> String {
            guard let value, value != "-" else {
                let data = FileHandle.standardInput.readDataToEndOfFile()
                return String(data: data, encoding: .utf8) ?? ""
            }
            return value
        }
    }
}
