import FileManagerProtocol
import Foundation
import Testing

@Suite(.buildBinary, .serialized)
struct ConfigCommandTests {
    let fileManager: any FileManagerProtocol = FileManager.default

    @Test("config init creates config.json with defaults")
    func initCreatesDefaults() async throws {
        try await withHome { home, env in
            let runner = try await CLIRunner()
            let result = try await runner.run(arguments: ["config", "init"], environment: env)
            #expect(result.succeeded, "\(result.stderr)")

            let configPath = home.appending(path: ".localmemo/config.json").path(percentEncoded: false)
            #expect(fileManager.fileExists(atPath: configPath))
        }
    }

    @Test("config init without --force fails on an existing file")
    func initFailsWithoutForce() async throws {
        try await withHome { _, env in
            let runner = try await CLIRunner()
            _ = try await runner.run(arguments: ["config", "init"], environment: env)
            let second = try await runner.run(arguments: ["config", "init"], environment: env)
            #expect(second.exitCode == 3)
        }
    }

    @Test("config set default_ttl persists and applies to subsequent set")
    func setDefaultTTLApplies() async throws {
        try await withHome { _, env in
            let runner = try await CLIRunner()
            _ = try await runner.run(arguments: ["config", "set", "default_ttl", "1s"], environment: env)

            let setResult = try await runner.run(arguments: ["set", "todo", "value"], environment: env)
            #expect(setResult.succeeded, "\(setResult.stderr)")

            try await Task.sleep(for: .seconds(2))
            let getResult = try await runner.run(arguments: ["get", "todo"], environment: env)
            #expect(getResult.exitCode == 5)
        }
    }

    private func withHome(_ body: (URL, [String: String]) async throws -> Void) async throws {
        let tempDir = try fileManager.makeTemporaryDirectory(prefix: "local-memo-e2e-config")
        defer { try? fileManager.removeItem(at: tempDir) }
        let home = tempDir.appending(path: "home")
        try fileManager.createDirectory(at: home, withIntermediateDirectories: true)
        try await body(home, ["HOME": home.path(percentEncoded: false)])
    }
}
