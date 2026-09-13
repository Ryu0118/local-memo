import Foundation

/// Parses a raw `config set <key> <value>` argument pair and applies it to a config in place.
package enum ConfigValueApplier {
    /// Applies `rawValue` to the field named `key` on `config`. Throws
    /// ``MemoStoreError/invalidInput(_:)`` for an unknown key or a value that doesn't parse.
    package static func apply(key: String, rawValue: String, to config: inout LocalMemoConfig) throws {
        switch key {
        case "default_ttl":
            config.defaultTTL = (rawValue == "never" || rawValue.isEmpty) ? nil : try requireTTL(rawValue)
        case "root_directory":
            config.rootDirectory = rawValue.isEmpty ? nil : rawValue
        case "expired_policy":
            config.expiredPolicy = try requireEnum(ExpiredPolicy.self, rawValue, key: key)
        case "auto_cleanup":
            config.autoCleanup = try requireBool(rawValue, key: key)
        case "hash_length":
            config.hashLength = try requireInt(rawValue, key: key, range: 4 ... 64)
        case "max_value_bytes":
            config.maxValueBytes = try requireInt(rawValue, key: key, range: 1...)
        case "default_output":
            config.defaultOutput = try requireEnum(DefaultOutput.self, rawValue, key: key)
        default:
            throw MemoStoreError.invalidInput("unknown config key '\(key)'")
        }
    }

    private static func requireTTL(_ raw: String) throws -> String {
        guard TTLDuration.parse(raw) != nil else {
            throw MemoStoreError.invalidInput("invalid default_ttl '\(raw)'")
        }
        return raw
    }

    private static func requireBool(_ raw: String, key: String) throws -> Bool {
        switch raw {
        case "true": true
        case "false": false
        default: throw MemoStoreError.invalidInput("invalid boolean for '\(key)': \(raw)")
        }
    }

    private static func requireInt(_ raw: String, key: String, range: PartialRangeFrom<Int>) throws -> Int {
        guard let value = Int(raw), range.contains(value) else {
            throw MemoStoreError.invalidInput("invalid integer for '\(key)': \(raw)")
        }
        return value
    }

    private static func requireInt(_ raw: String, key: String, range: ClosedRange<Int>) throws -> Int {
        guard let value = Int(raw), range.contains(value) else {
            throw MemoStoreError.invalidInput("invalid integer for '\(key)': \(raw)")
        }
        return value
    }

    private static func requireEnum<T: RawRepresentable>(_ type: T.Type, _ raw: String, key: String) throws -> T where T.RawValue == String {
        guard let value = type.init(rawValue: raw) else {
            throw MemoStoreError.invalidInput("invalid value for '\(key)': \(raw)")
        }
        return value
    }
}
