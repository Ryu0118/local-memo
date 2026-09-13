/// The policy applied to memos whose TTL has expired.
public enum ExpiredPolicy: String, Codable, Sendable {
    /// Keep the files; `get`/`list` treat an expired memo as invisible unless asked otherwise.
    case hide
    /// Physically delete an expired memo's files the moment a command touches it.
    case lazyDelete = "lazy_delete"
    /// Never treat a memo as expired; `expires_at` is informational only.
    case keep
}
