@testable import LocalMemoKit
import Testing

struct MemoKeyValidatorTests {
    @Test(
        "accepts valid keys",
        arguments: ["todo", "api-note", "my.key_1", "a", String(repeating: "a", count: 128)],
    )
    func acceptsValid(_ raw: String) throws {
        let key = try MemoKeyValidator.validate(raw)
        #expect(key.rawValue == raw)
    }

    @Test(
        "rejects invalid keys",
        arguments: ["", ".hidden", "a/b", "a b", "..", String(repeating: "a", count: 129), "a\0b"],
    )
    func rejectsInvalid(_ raw: String) {
        #expect(throws: MemoStoreError.self) {
            try MemoKeyValidator.validate(raw)
        }
    }
}
