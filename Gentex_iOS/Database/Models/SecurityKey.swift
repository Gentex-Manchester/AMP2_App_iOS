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

    var rawValue: String {
        switch self {
        case .MIKE:     return "MIKE"
        case .NOVEMBER: return "NOVEMBER"
        case .OSCAR:    return "OSCAR"
        case .PAPA:     return "PAPA"
        case .QUEBEC:   return "QUEBEC"
        case .ROMEO:    return "ROMEO"
        case .SIERRA:   return "SIERRA"
        case .TANGO:    return "TANGO"
        case .UNIFORM:  return "UNIFORM"
        case .VICTOR:   return "VICTOR"
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
