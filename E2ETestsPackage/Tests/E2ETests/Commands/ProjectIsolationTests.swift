import FileManagerProtocol
import Foundation
import Testing

@Suite(.buildBinary, .serialized)
struct ProjectIsolationTests {
    let fileManager: any FileManagerProtocol = FileManager.default

    @Test("memos set in one project directory are invisible from another")
    func differentProjectsDoNotShareMemos() async throws {
        let tempDir = try fileManager.makeTemporaryDirectory(prefix: "local-memo-e2e-isolation")
        defer { try? fileManager.removeItem(at: tempDir) }

        let home = tempDir.appending(path: "home")
        let projectA = tempDir.appending(path: "project-a")
        let projectB = tempDir.appending(path: "project-b")
        try fileManager.createDirectory(at: home, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: projectA, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: projectB, withIntermediateDirectories: true)
        let env = ["HOME": home.path(percentEncoded: false)]

        let runner = try await CLIRunner()
        let setResult = try await runner.run(
            arguments: ["set", "todo", "only in A", "--project", projectA.path(percentEncoded: false)],
            environment: env,
        )
        #expect(setResult.succeeded, "\(setResult.stderr)")

        let getFromA = try await runner.run(
            arguments: ["get", "todo", "--project", projectA.path(percentEncoded: false)],
            environment: env,
        )
        #expect(getFromA.succeeded)
        #expect(getFromA.stdout == "only in A")

        let getFromB = try await runner.run(
            arguments: ["get", "todo", "--project", projectB.path(percentEncoded: false)],
            environment: env,
        )
        #expect(getFromB.exitCode == 4)
    }

    @Test("/tmp and /private/tmp resolve to the same project hash")
    func tmpSymlinkResolvesToSamePathHash() async throws {
        // On macOS, /tmp is a symlink to /private/tmp; ProjectPathResolver must resolve both
        // to the same normalized path so a project's memos stay reachable regardless of which
        // spelling a caller passes.
        let home = try fileManager.makeTemporaryDirectory(prefix: "local-memo-e2e-tmp-home")
        defer { try? fileManager.removeItem(at: home) }
        let env = ["HOME": home.path(percentEncoded: false)]

        let runner = try await CLIRunner()
        let setResult = try await runner.run(
            arguments: ["set", "todo", "via /tmp", "--project", "/tmp"],
            environment: env,
        )
        #expect(setResult.succeeded, "\(setResult.stderr)")

        let getResult = try await runner.run(
            arguments: ["get", "todo", "--project", "/private/tmp"],
            environment: env,
        )
        #expect(getResult.succeeded, "\(getResult.stderr)")
        #expect(getResult.stdout == "via /tmp")
    }
}
