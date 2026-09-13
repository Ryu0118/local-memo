import ArgumentParser
import Foundation
import LocalMemoKit

package extension LocalMemoCommand {
    struct ConfigCommand: AsyncParsableCommand {
        package static let configuration = CommandConfiguration(
            commandName: "config",
            abstract: "Manage ~/.localmemo/config.json.",
            subcommands: [
                InitCommand.self,
                ShowCommand.self,
                SetCommand.self,
                PathCommand.self,
            ],
        )

        package init() {}
    }
}

package extension LocalMemoCommand.ConfigCommand {
    struct InitCommand: AsyncParsableCommand {
        @OptionGroup package var common: CommonOptions

        @Flag(name: .long, help: "Overwrite an existing config.json.")
        package var force = false

        package static let configuration = CommandConfiguration(commandName: "init", abstract: "Create config.json with default values.")

        package init() {}

        package func run() async throws {
            let store = MemoStore(projectPath: common.project.map {
                CLIPath.resolve($0, relativeToDirectory: FileManager.default.currentDirectoryPath).path(percentEncoded: false)
            })
            do {
                let config = try store.initConfig(force: force)
                if StoreFactory.wantsJSON(common, store: store) {
                    try CLIOutput.printJSON(config)
                } else {
                    print("created \(store.configPath)")
                }
            } catch {
                try MemoStoreErrorHandler.handle(error)
            }
        }
    }

    struct ShowCommand: AsyncParsableCommand {
        @OptionGroup package var common: CommonOptions

        package static let configuration = CommandConfiguration(commandName: "show", abstract: "Print the effective config.")

        package init() {}

        package func run() async throws {
            let store = MemoStore(projectPath: common.project.map {
                CLIPath.resolve($0, relativeToDirectory: FileManager.default.currentDirectoryPath).path(percentEncoded: false)
            })
            do {
                let config = try store.loadConfig()
                if StoreFactory.wantsJSON(common, store: store) {
                    try CLIOutput.printJSON(config)
                } else {
                    print("schema_version: \(config.schemaVersion)")
                    print("default_ttl: \(config.defaultTTL ?? "null")")
                    print("root_directory: \(config.rootDirectory ?? "null")")
                    print("expired_policy: \(config.expiredPolicy.rawValue)")
                    print("auto_cleanup: \(config.autoCleanup)")
                    print("hash_length: \(config.hashLength)")
                    print("max_value_bytes: \(config.maxValueBytes)")
                    print("default_output: \(config.defaultOutput.rawValue)")
                }
            } catch {
                try MemoStoreErrorHandler.handle(error)
            }
        }
    }

    struct SetCommand: AsyncParsableCommand {
        @OptionGroup package var common: CommonOptions

        @Argument(help: "Config key to set, e.g. default_ttl.")
        package var key: String

        @Argument(help: "New value for the key.")
        package var value: String

        package static let configuration = CommandConfiguration(commandName: "set", abstract: "Update a single config key.")

        package init() {}

        package func run() async throws {
            let store = MemoStore(projectPath: common.project.map {
                CLIPath.resolve($0, relativeToDirectory: FileManager.default.currentDirectoryPath).path(percentEncoded: false)
            })
            do {
                let config = try store.setConfigValue(key: key, rawValue: value)
                if StoreFactory.wantsJSON(common, store: store) {
                    try CLIOutput.printJSON(config)
                } else {
                    print("\(key) = \(value)")
                }
            } catch {
                try MemoStoreErrorHandler.handle(error)
            }
        }
    }

    struct PathCommand: AsyncParsableCommand {
        @OptionGroup package var common: CommonOptions

        package static let configuration = CommandConfiguration(commandName: "path", abstract: "Print the config.json path.")

        package init() {}

        package func run() async throws {
            let store = MemoStore(projectPath: common.project.map {
                CLIPath.resolve($0, relativeToDirectory: FileManager.default.currentDirectoryPath).path(percentEncoded: false)
            })
            print(store.configPath)
        }
    }
}
