import ArgumentParser

/// Root command for the local-memo CLI.
public struct LocalMemoCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "local-memo",
        abstract: "Save plain-text memos scoped to the current working directory.",
        version: LocalMemoVersion.current,
        subcommands: [
            SetCommand.self,
            GetCommand.self,
            ListCommand.self,
            DeleteCommand.self,
            CleanupCommand.self,
            PathCommand.self,
            ConfigCommand.self,
        ],
    )

    public init() {}
}
