/// The default output format for commands that don't pass `--json` explicitly.
public enum DefaultOutput: String, Codable, Sendable {
    /// Human-readable text (tables, plain lines).
    case text
    /// Machine-readable JSON on stdout.
    case json
}
