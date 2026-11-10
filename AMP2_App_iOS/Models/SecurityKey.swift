import Foundation

/// The 10 predefined keys. Uppercase raw values go in the QR payload; lookups
/// are case-insensitive.
enum SecurityKey: CaseIterable, Codable, Sendable {
    case MIKE
    case NOVEMBER
    case OSCAR
    case PAPA
    case QUEBEC
    case ROMEO
    case SIERRA
    case TANGO
    case UNIFORM
    case VICTOR
    case CUSTOM

    var rawValue: String {
        switch self {
        case .MIKE:     return String(localized: "Mike")
        case .NOVEMBER: return String(localized: "November")
        case .OSCAR:    return String(localized: "Oscar")
        case .PAPA:     return String(localized: "Papa")
        case .QUEBEC:   return String(localized: "Quebec")
        case .ROMEO:    return String(localized: "Romeo")
        case .SIERRA:   return String(localized: "Sierra")
        case .TANGO:    return String(localized: "Tango")
        case .UNIFORM:  return String(localized: "Uniform")
        case .VICTOR:   return String(localized: "Victor")
        case .CUSTOM:   return String(localized: "Custom")
        }
    }

    static var all: [SecurityKey] {
        Self.allCases
    }

    /// Case-insensitive. Rejects "Victory" (migration v2 fixes stored rows) and
    /// untrimmed input; callers trim.
    init?(rawValue: String) {
        guard let match = Self.allCases.first(where: {
            $0.rawValue.caseInsensitiveCompare(rawValue) == .orderedSame
        }) else {
            return nil
        }
        self = match
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let key = SecurityKey(rawValue: string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown security key: \"\(string)\""
            )
        }
        self = key
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
