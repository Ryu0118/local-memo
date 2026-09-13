import ArgumentParser
import Foundation
import LocalMemoKit

package extension LocalMemoCommand {
    struct CleanupCommand: AsyncParsableCommand {
        @OptionGroup package var common: CommonOptions

        @Flag(name: .long, help: "Scan every project's memos, not just the current one.")
        package var allProjects = false

        @Flag(name: .long, help: "Report what would be deleted without deleting anything.")
        package var dryRun = false

        package static let configuration = CommandConfiguration(
            commandName: "cleanup",
            abstract: "Delete expired memos.",
        )

        package init() {}

        package func run() async throws {
            // cleanup IS the auto-cleanup operation; StoreFactory.make would run it twice.
            let store = MemoStore(projectPath: common.project.map {
                CLIPath.resolve($0, relativeToDirectory: FileManager.default.currentDirectoryPath).path(percentEncoded: false)
            })
            do {
                let removed = try store.cleanup(allProjects: allProjects, dryRun: dryRun)
                if StoreFactory.wantsJSON(common, store: store) {
                    try CLIOutput.printJSON(removed)
                } else if removed.isEmpty {
                    print("no expired memos")
                } else {
                    removed.forEach { print("\(dryRun ? "would delete" : "deleted") '\($0.key)' (\($0.projectHash))") }
                }
            } catch {
                try MemoStoreErrorHandler.handle(error)
            }
        }
    }
}
