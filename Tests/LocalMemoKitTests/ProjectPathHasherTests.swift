@testable import LocalMemoKit
import Testing

struct ProjectPathHasherTests {
    @Test("same path always produces the same hash")
    func stableForSamePath() {
        let first = ProjectPathHasher.hash(normalizedPath: "/Users/test/project")
        let second = ProjectPathHasher.hash(normalizedPath: "/Users/test/project")
        #expect(first == second)
    }

    @Test("different paths produce different hashes")
    func differsForDifferentPaths() {
        let first = ProjectPathHasher.hash(normalizedPath: "/Users/test/project-a")
        let second = ProjectPathHasher.hash(normalizedPath: "/Users/test/project-b")
        #expect(first != second)
    }

    @Test("hash length matches the requested prefix length")
    func respectsLength() {
        let hash = ProjectPathHasher.hash(normalizedPath: "/Users/test/project", length: 8)
        #expect(hash.count == 8)
    }

    @Test("hash is lowercase hex")
    func isLowercaseHex() {
        let hash = ProjectPathHasher.hash(normalizedPath: "/Users/test/project")
        let isHex = hash.allSatisfy { character in character.isHexDigit }
        #expect(isHex)
        #expect(hash == hash.lowercased())
    }
}
