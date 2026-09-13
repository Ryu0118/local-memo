import FileManagerProtocol
import Foundation
import Testing

@Suite(.buildBinary, .serialized)
struct ListCommandTests {
    let fileManager: any FileManagerProtocol = FileManager.default

    @Test("--json lists saved keys")
    func jsonListsKeys() async throws {
        try await withHome { env in
            let runner = try await CLIRunner()
            _ = try await runner.run(arguments: ["set", "a", "1"], environment: env)
            _ = try await runner.run(arguments: ["set", "b", "2"], environment: env)

            let result = try await runner.run(arguments: ["list", "--json"], environment: env)
            #expect(result.succeeded, "\(result.stderr)")
            #expect(result.stdout.contains("\"key\" : \"a\""))
            #expect(result.stdout.contains("\"key\" : \"b\""))
        }
    }

    @Test("empty project reports no memos")
    func emptyProjectReportsNoMemos() async throws {
        try await withHome { env in
            let runner = try await CLIRunner()
            let result = try await runner.run(arguments: ["list"], environment: env)
            #expect(result.succeeded)
            #expect(result.stdout.contains("no memos"))
        }
    }

    private func withHome(_ body: ([String: String]) async throws -> Void) async throws {
        let tempDir = try fileManager.makeTemporaryDirectory(prefix: "local-memo-e2e-list")
        defer { try? fileManager.removeItem(at: tempDir) }
        let home = tempDir.appending(path: "home")
        try fileManager.createDirectory(at: home, withIntermediateDirectories: true)
        try await body(["HOME": home.path(percentEncoded: false)])
    }
}
