import ArgumentParser
import Foundation
import Interaction
import LocalMemoKit

package extension LocalMemoCommand {
    struct DeleteCommand: AsyncParsableCommand {
        @OptionGroup package var common: CommonOptions

        @Argument(help: "Memo keys to delete.")
        package var keys: [String] = []

        @Flag(name: .long, help: "Delete every memo in the current project.")
        package var all = false

        @Flag(name: .long, help: "Skip the confirmation prompt for --all.")
        package var force = false

        package static let configuration = CommandConfiguration(
            commandName: "delete",
            abstract: "Delete one or more memos.",
            aliases: ["rm"],
        )

        package init() {}

        package func run() async throws {
            guard all || !keys.isEmpty else {
                throw ArgumentParser.ValidationError("specify one or more keys, or pass --all")
            }

            let store = try StoreFactory.make(common)
            do {
                let deleted: [String] = if all {
                    try confirmedDeleteAll(store)
                } else {
                    try store.delete(keys: keys)
                }
                if StoreFactory.wantsJSON(common, store: store) {
                    try CLIOutput.printJSON(DeleteResult(deleted: deleted))
                } else if deleted.isEmpty {
                    print("nothing to delete")
                } else {
                    deleted.forEach { print("deleted '\($0)'") }
                }
                let missing = Set(all ? [] : keys).subtracting(deleted)
                if !missing.isEmpty {
                    throw MemoStoreError.notFound(key: missing.sorted().joined(separator: ", "))
                }
            } catch {
                try MemoStoreErrorHandler.handle(error)
            }
        }

        private func confirmedDeleteAll(_ store: MemoStore) throws -> [String] {
            if !force {
                let confirmed = GuardedTerminal().confirm(ConfirmationPrompt(question: "Delete all memos for this project?"))
                guard confirmed else { return [] }
            }
            return try store.deleteAll()
        }
    }
}

/// The `--json` shape of a `delete` result.
package struct DeleteResult: Codable {
    package let deleted: [String]
}
