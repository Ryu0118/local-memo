import FileManagerProtocol
import Foundation
import Testing

@Suite(.buildBinary, .serialized)
struct SetGetCommandTests {
    let fileManager: any FileManagerProtocol = FileManager.default

    @Test("--help shows set command help")
    func helpShowsSetCommandHelp() async throws {
        let runner = try await CLIRunner()
        let result = try await runner.run("set", "--help")

        #expect(result.succeeded)
        #expect(result.stdout.contains("--ttl"))
        #expect(result.stdout.contains("--no-overwrite"))
    }

    @Test("set then get round-trips a value")
    func setThenGet() async throws {
        try await withHome { _, env in
            let runner = try await CLIRunner()
            let setResult = try await runner.run(arguments: ["set", "todo", "buy milk"], environment: env)
            #expect(setResult.succeeded, "\(setResult.stderr)")

            let getResult = try await runner.run(arguments: ["get", "todo"], environment: env)
            #expect(getResult.succeeded, "\(getResult.stderr)")
            #expect(getResult.stdout == "buy milk")
        }
    }

    @Test("get on a missing key exits 4")
    func getMissingKeyExits4() async throws {
        try await withHome { _, env in
            let runner = try await CLIRunner()
            let result = try await runner.run(arguments: ["get", "missing"], environment: env)
            #expect(result.exitCode == 4)
        }
    }

    @Test("set --no-overwrite on an existing key exits 3")
    func noOverwriteExits3() async throws {
        try await withHome { _, env in
            let runner = try await CLIRunner()
            _ = try await runner.run(arguments: ["set", "todo", "first"], environment: env)
            let result = try await runner.run(arguments: ["set", "todo", "second", "--no-overwrite"], environment: env)
            #expect(result.exitCode == 3)
        }
    }

    @Test("expired memo returns exit code 5, then 4 once lazy_delete has removed it")
    func expiredMemoTransitionsFromExpiredToNotFound() async throws {
        try await withHome { _, env in
            let runner = try await CLIRunner()
            _ = try await runner.run(arguments: ["set", "todo", "gone soon", "--ttl", "1s"], environment: env)
            try await Task.sleep(for: .seconds(2))

            let firstGet = try await runner.run(arguments: ["get", "todo"], environment: env)
            #expect(firstGet.exitCode == 5)

            let secondGet = try await runner.run(arguments: ["get", "todo"], environment: env)
            #expect(secondGet.exitCode == 4)
        }
    }

    private func withHome(_ body: (URL, [String: String]) async throws -> Void) async throws {
        let tempDir = try fileManager.makeTemporaryDirectory(prefix: "local-memo-e2e-set-get")
        defer { try? fileManager.removeItem(at: tempDir) }
        let home = tempDir.appending(path: "home")
        try fileManager.createDirectory(at: home, withIntermediateDirectories: true)
        try await body(home, ["HOME": home.path(percentEncoded: false)])
    }
}
