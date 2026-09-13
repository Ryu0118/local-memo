import ArgumentParser
import Foundation
import LocalMemoKit

package extension LocalMemoCommand {
    struct PathCommand: AsyncParsableCommand {
        @OptionGroup package var common: CommonOptions

        @Flag(name: .long, help: "Print the ~/.localmemo root directory instead of the current project's directory.")
        package var root = false

        package static let configuration = CommandConfiguration(
            commandName: "path",
            abstract: "Print the current project's memo directory.",
        )

        package init() {}

        package func run() async throws {
            let store = MemoStore(projectPath: common.project.map {
                CLIPath.resolve($0, relativeToDirectory: FileManager.default.currentDirectoryPath).path(percentEncoded: false)
            })
            if root {
                print(store.rootDirectory.path(percentEncoded: false))
                return
            }
            do {
                let config = try store.loadConfig()
                let layout = store.fileLayout(config: config)
                print(layout.projectDirectory.path(percentEncoded: false))
            } catch {
                try MemoStoreErrorHandler.handle(error)
            }
        }
    }
}
