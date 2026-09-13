import ArgumentParser
@testable import LocalMemoCLI
import Testing

@Suite
struct CommandParsingTests {
    @Test("root command recognizes each subcommand's minimal valid arguments", arguments: [
        ["set", "dummy-key", "dummy-value"],
        ["get", "dummy-key"],
        ["list"],
        ["delete", "dummy-key"],
        ["rm", "dummy-key"],
        ["cleanup"],
        ["path"],
        ["config", "show"],
    ])
    func parsesEachSubcommand(_ arguments: [String]) throws {
        let command = try LocalMemoCommand.parseAsRoot(arguments)
        #expect(type(of: command) != LocalMemoCommand.self)
    }

    @Test("set requires a key argument")
    func setRequiresKey() throws {
        #expect(throws: (any Error).self) {
            _ = try LocalMemoCommand.parseAsRoot(["set"])
        }
    }
}
