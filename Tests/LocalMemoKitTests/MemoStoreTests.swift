import FileManagerProtocol
import Foundation
@testable import LocalMemoKit
import Testing

struct MemoStoreTests {
    private func makeStore(root: URL, project: URL, clock: TestClock? = nil) -> MemoStore {
        MemoStore(rootDirectory: root, projectPath: project.path(percentEncoded: false), now: { clock?.now ?? Date() })
    }

    private func withTempDirectory(_ body: @Sendable (URL) async throws -> Void) async throws {
        let fileManager: any FileManagerProtocol = FileManager.default
        try await fileManager.runInTemporaryDirectory(prefix: "local-memo-store-test") { directory in
            try await body(directory)
        }
    }

    @Test("set then get round-trips the value")
    func setThenGet() async throws {
        try await withTempDirectory { temp in
            let store = makeStore(root: temp.appending(path: "root"), project: temp.appending(path: "project"))
            _ = try store.set(key: "todo", value: "buy milk", ttl: nil, allowOverwrite: true)
            let record = try store.get(key: "todo", includeExpired: false)
            #expect(record.value == "buy milk")
        }
    }

    @Test("set without --no-overwrite replaces an existing key")
    func overwriteAllowed() async throws {
        try await withTempDirectory { temp in
            let store = makeStore(root: temp.appending(path: "root"), project: temp.appending(path: "project"))
            _ = try store.set(key: "todo", value: "first", ttl: nil, allowOverwrite: true)
            let outcome = try store.set(key: "todo", value: "second", ttl: nil, allowOverwrite: true)
            #expect(outcome.overwritten)
            #expect(try store.get(key: "todo", includeExpired: false).value == "second")
        }
    }

    @Test("set with allowOverwrite false throws on an existing key")
    func overwriteRejected() async throws {
        try await withTempDirectory { temp in
            let store = makeStore(root: temp.appending(path: "root"), project: temp.appending(path: "project"))
            _ = try store.set(key: "todo", value: "first", ttl: nil, allowOverwrite: true)
            #expect(throws: MemoStoreError.self) {
                try store.set(key: "todo", value: "second", ttl: nil, allowOverwrite: false)
            }
        }
    }

    @Test("different project paths do not see each other's memos")
    func projectIsolation() async throws {
        try await withTempDirectory { temp in
            let root = temp.appending(path: "root")
            let storeA = makeStore(root: root, project: temp.appending(path: "project-a"))
            let storeB = makeStore(root: root, project: temp.appending(path: "project-b"))
            _ = try storeA.set(key: "todo", value: "a's memo", ttl: nil, allowOverwrite: true)
            #expect(throws: MemoStoreError.self) {
                try storeB.get(key: "todo", includeExpired: false)
            }
        }
    }

    @Test("lazy_delete removes an expired memo's files when get touches it")
    func lazyDeleteOnGet() async throws {
        try await withTempDirectory { temp in
            let root = temp.appending(path: "root")
            let clock = TestClock()
            let store = makeStore(root: root, project: temp.appending(path: "project"), clock: clock)
            _ = try store.set(key: "todo", value: "expires soon", ttl: "1s", allowOverwrite: true)

            clock.advance(by: 2)
            #expect(throws: MemoStoreError.self) {
                try store.get(key: "todo", includeExpired: false)
            }

            let layout = store.fileLayout(config: .default)
            #expect(!FileManager.default.fileExists(atPath: layout.bodyURL(for: MemoKey(rawValue: "todo")!).path(percentEncoded: false)))
        }
    }

    @Test("get --include-expired returns an expired value without deleting it")
    func includeExpiredSkipsDeletion() async throws {
        try await withTempDirectory { temp in
            let root = temp.appending(path: "root")
            let clock = TestClock()
            let store = makeStore(root: root, project: temp.appending(path: "project"), clock: clock)
            _ = try store.set(key: "todo", value: "expires soon", ttl: "1s", allowOverwrite: true)

            clock.advance(by: 2)
            let record = try store.get(key: "todo", includeExpired: true)
            #expect(record.value == "expires soon")
        }
    }

    @Test("delete removes only the requested keys")
    func deleteSpecificKeys() async throws {
        try await withTempDirectory { temp in
            let store = makeStore(root: temp.appending(path: "root"), project: temp.appending(path: "project"))
            _ = try store.set(key: "a", value: "1", ttl: nil, allowOverwrite: true)
            _ = try store.set(key: "b", value: "2", ttl: nil, allowOverwrite: true)
            let deleted = try store.delete(keys: ["a"])
            #expect(deleted == ["a"])
            #expect(try store.list(showExpired: false).map(\.key) == ["b"])
        }
    }

    @Test("cleanup removes expired memos and reports dry-run without deleting")
    func cleanupDryRunThenReal() async throws {
        try await withTempDirectory { temp in
            let root = temp.appending(path: "root")
            let clock = TestClock()
            let store = makeStore(root: root, project: temp.appending(path: "project"), clock: clock)
            _ = try store.set(key: "expiring", value: "gone soon", ttl: "1s", allowOverwrite: true)
            clock.advance(by: 2)

            let dryRun = try store.cleanup(allProjects: false, dryRun: true)
            #expect(dryRun.map(\.key) == ["expiring"])
            #expect(try store.list(showExpired: true).contains { $0.key == "expiring" })

            let real = try store.cleanup(allProjects: false, dryRun: false)
            #expect(real.map(\.key) == ["expiring"])
            #expect(try store.list(showExpired: true).isEmpty)
        }
    }

    @Test("set --no-overwrite treats an expired memo as absent, not a conflict")
    func noOverwriteAllowsReplacingExpired() async throws {
        try await withTempDirectory { temp in
            let root = temp.appending(path: "root")
            let clock = TestClock()
            let store = makeStore(root: root, project: temp.appending(path: "project"), clock: clock)
            _ = try store.set(key: "todo", value: "first", ttl: "1s", allowOverwrite: true)

            clock.advance(by: 2)
            let outcome = try store.set(key: "todo", value: "second", ttl: nil, allowOverwrite: false)
            #expect(!outcome.overwritten)
            #expect(try store.get(key: "todo", includeExpired: false).value == "second")
        }
    }
}
