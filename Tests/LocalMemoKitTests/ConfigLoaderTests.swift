import FileManagerProtocol
import Foundation
@testable import LocalMemoKit
import Testing

struct ConfigLoaderTests {
    @Test("returns the built-in default when config.json is missing")
    func missingFileReturnsDefault() async throws {
        let fileManager: any FileManagerProtocol = FileManager.default
        try await fileManager.runInTemporaryDirectory(prefix: "config-loader-test") { directory in
            let config = try ConfigLoader(fileManager: fileManager).load(from: directory.appending(path: "config.json"))
            #expect(config == .default)
        }
    }

    @Test("round-trips through ConfigWriter")
    func roundTrips() async throws {
        let fileManager: any FileManagerProtocol = FileManager.default
        try await fileManager.runInTemporaryDirectory(prefix: "config-loader-test") { directory in
            let configURL = directory.appending(path: "config.json")
            var config = LocalMemoConfig.default
            config.defaultTTL = "7d"
            config.autoCleanup = true
            config.expiredPolicy = .hide

            try ConfigWriter(fileManager: fileManager).write(config, to: configURL)
            let loaded = try ConfigLoader(fileManager: fileManager).load(from: configURL)
            #expect(loaded == config)
        }
    }

    @Test("unknown keys in config.json are ignored")
    func ignoresUnknownKeys() async throws {
        let fileManager: any FileManagerProtocol = FileManager.default
        try await fileManager.runInTemporaryDirectory(prefix: "config-loader-test") { directory in
            let configURL = directory.appending(path: "config.json")
            let json = """
            {"schema_version": 1, "expired_policy": "hide", "some_future_key": "value"}
            """
            try Data(json.utf8).write(to: configURL)
            let config = try ConfigLoader(fileManager: fileManager).load(from: configURL)
            #expect(config.expiredPolicy == .hide)
        }
    }
}
