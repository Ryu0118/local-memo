import Foundation
import LocalMemoKit

/// Builds the ``MemoStore`` for a command's ``CommonOptions``, applying `auto_cleanup` first
/// so every subcommand sees a project's expired memos already swept when the config asks for it.
package enum StoreFactory {
    package static func make(_ common: CommonOptions) throws -> MemoStore {
        let store = MemoStore(projectPath: common.project.map {
            CLIPath.resolve($0, relativeToDirectory: FileManager.default.currentDirectoryPath).path(percentEncoded: false)
        })
        let config = try store.loadConfig()
        if config.autoCleanup {
            _ = try? store.cleanup(allProjects: false, dryRun: false)
        }
        return store
    }

    /// Whether output should be JSON: an explicit `--json` wins, otherwise config's
    /// `default_output` decides.
    package static func wantsJSON(_ common: CommonOptions, store: MemoStore) -> Bool {
        if common.json { return true }
        return (try? store.loadConfig().defaultOutput) == .json
    }
}
