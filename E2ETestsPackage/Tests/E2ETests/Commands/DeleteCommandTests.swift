import FileManagerProtocol
import Foundation
import Testing

@Suite(.buildBinary, .serialized)
struct DeleteCommandTests {
    let fileManager: any FileManagerProtocol = FileManager.default

    @Test("delete removes a specific key")
    func deleteSpecificKey() async throws {
        try await withHome { env in
            let runner = try await CLIRunner()
            _ = try await runner.run(arguments: ["set", "todo", "value"], environment: env)

            let deleteResult = try await runner.run(arguments: ["delete", "todo"], environment: env)
            #expect(deleteResult.succeeded, "\(deleteResult.stderr)")

            let getResult = try await runner.run(arguments: ["get", "todo"], environment: env)
            #expect(getResult.exitCode == 4)
        }
    }

    @Test("delete --all --force removes every memo without prompting")
    func deleteAllForce() async throws {
        try await withHome { env in
            let runner = try await CLIRunner()
            _ = try await runner.run(arguments: ["set", "a", "1"], environment: env)
            _ = try await runner.run(arguments: ["set", "b", "2"], environment: env)

            let deleteResult = try await runner.run(arguments: ["delete", "--all", "--force"], environment: env)
            #expect(deleteResult.succeeded, "\(deleteResult.stderr)")

            let listResult = try await runner.run(arguments: ["list"], environment: env)
            #expect(listResult.stdout.contains("no memos"))
        }
    }

    private func withHome(_ body: ([String: String]) async throws -> Void) async throws {
        let tempDir = try fileManager.makeTemporaryDirectory(prefix: "local-memo-e2e-delete")
        defer { try? fileManager.removeItem(at: tempDir) }
        let home = tempDir.appending(path: "home")
        try fileManager.createDirectory(at: home, withIntermediateDirectories: true)
        try await body(["HOME": home.path(percentEncoded: false)])
    }
}
