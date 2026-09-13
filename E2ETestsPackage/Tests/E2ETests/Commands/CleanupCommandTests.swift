import FileManagerProtocol
import Foundation
import Testing

@Suite(.buildBinary, .serialized)
struct CleanupCommandTests {
    let fileManager: any FileManagerProtocol = FileManager.default

    @Test("cleanup --dry-run reports without deleting; cleanup deletes for real")
    func dryRunThenReal() async throws {
        let tempDir = try fileManager.makeTemporaryDirectory(prefix: "local-memo-e2e-cleanup")
        defer { try? fileManager.removeItem(at: tempDir) }
        let home = tempDir.appending(path: "home")
        try fileManager.createDirectory(at: home, withIntermediateDirectories: true)
        let env = ["HOME": home.path(percentEncoded: false)]

        let runner = try await CLIRunner()
        _ = try await runner.run(arguments: ["set", "expiring", "gone soon", "--ttl", "1s"], environment: env)
        try await Task.sleep(for: .seconds(2))

        let dryRun = try await runner.run(arguments: ["cleanup", "--dry-run"], environment: env)
        #expect(dryRun.succeeded)
        #expect(dryRun.stdout.contains("would delete 'expiring'"))

        let listAfterDryRun = try await runner.run(arguments: ["list", "--show-expired"], environment: env)
        #expect(listAfterDryRun.stdout.contains("expiring"))

        let real = try await runner.run(arguments: ["cleanup"], environment: env)
        #expect(real.succeeded)
        #expect(real.stdout.contains("deleted 'expiring'"))

        let listAfterReal = try await runner.run(arguments: ["list", "--show-expired"], environment: env)
        #expect(!listAfterReal.stdout.contains("expiring"))
    }
}
