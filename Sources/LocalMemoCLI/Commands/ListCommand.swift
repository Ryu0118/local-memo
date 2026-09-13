import ArgumentParser
import Foundation
import Interaction
import LocalMemoKit

package extension LocalMemoCommand {
    struct ListCommand: AsyncParsableCommand {
        @OptionGroup package var common: CommonOptions

        @Flag(name: .long, help: "Include expired memos in the listing.")
        package var showExpired = false

        @Flag(name: .long, help: "Show created/expires columns in addition to key.")
        package var long = false

        @Flag(name: .long, help: "Print only keys, one per line.")
        package var keysOnly = false

        package static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List memos for the current project.",
        )

        package init() {}

        package func run() async throws {
            let store = try StoreFactory.make(common)
            do {
                let entries = try store.list(showExpired: showExpired)
                if StoreFactory.wantsJSON(common, store: store) {
                    try CLIOutput.printJSON(entries)
                } else if keysOnly {
                    entries.forEach { print($0.key) }
                } else {
                    printTable(entries)
                }
            } catch {
                try MemoStoreErrorHandler.handle(error)
            }
        }

        private func printTable(_ entries: [MemoStore.MemoListEntry]) {
            guard !entries.isEmpty else {
                print("(no memos)")
                return
            }
            var headers = ["key", "expires"]
            if long { headers += ["created"] }
            var rows: [[String]] = []
            for entry in entries {
                var row = [entry.isExpired ? "\(entry.key) (expired)" : entry.key, formattedExpiry(entry)]
                if long { row.append(ISO8601DateFormatter().string(from: entry.createdAt)) }
                rows.append(row)
            }
            GuardedTerminal().writeTable(Table(headers: headers, rows: rows))
        }

        private func formattedExpiry(_ entry: MemoStore.MemoListEntry) -> String {
            guard let expiresAt = entry.expiresAt else { return "never" }
            return ISO8601DateFormatter().string(from: expiresAt)
        }
    }
}
