import Foundation

package extension TTLDuration {
    /// Parses a TTL string. Accepts `never`, `0`, or one or more `<int><unit>` segments
    /// concatenated with no separator (e.g. `1d12h`). Units: `s m h d w`.
    static func parse(_ raw: String) -> TTLDuration? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if trimmed == "never" || trimmed == "0" {
            return .never
        }

        var total = 0
        var digits = ""
        var matchedAnySegment = false

        for character in trimmed {
            if character.isNumber {
                digits.append(character)
                continue
            }
            guard let unitValue = unitSeconds[character], !digits.isEmpty, let amount = Int(digits) else {
                return nil
            }
            total += amount * unitValue
            digits = ""
            matchedAnySegment = true
        }

        guard digits.isEmpty, matchedAnySegment, total > 0 else {
            return nil
        }
        return .seconds(total)
    }
}
