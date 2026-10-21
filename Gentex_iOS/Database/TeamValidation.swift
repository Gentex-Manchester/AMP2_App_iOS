import Foundation

enum TeamValidationResult: Equatable, Sendable {
    case valid
    /// Carries a user-facing reason.
    case invalid(String)
    /// `customSecurityKey` is reserved.
    case customSecurityKeyNotSupported
}

enum TeamValidation {

    /// One byte on the headset (LTC setting `0x04`), so 0...255. Same as Android.
    static func validateNetworkId(_ networkId: Int) -> TeamValidationResult {
        guard (0...255).contains(networkId) else {
            return .invalid("Network ID must be between 0 and 255, got \(networkId).")
        }
        return .valid
    }

    static func validateRFChannel(_ channel: Int, in region: Region) -> TeamValidationResult {
        guard region.availableChannels.contains(channel) else {
            return .invalid(
                "RF channel \(channel) is not available in \(region.displayName). " +
                "Available: \(region.availableChannels.lowerBound)–\(region.availableChannels.upperBound)."
            )
        }
        return .valid
    }

    /// Title case; input of any casing is normalized before lookup.
    private static let validSecurityKeys: Set<String> = [
        "Mike", "November", "Oscar", "Papa", "Quebec",
        "Romeo", "Sierra", "Tango", "Uniform", "Victor"
    ]

    /// Title-case spelling, or `nil` if unknown. "Victory" is rejected on
    /// purpose; migration v2 rewrites it to "Victor".
    static func canonicalSecurityKey(_ key: String) -> String? {
        let normalized = key.trimmingCharacters(in: .whitespaces).capitalized
        return validSecurityKeys.contains(normalized) ? normalized : nil
    }

    /// Case-insensitive: "MIKE", "mike", and "Mike" all pass.
    static func validateSecurityKey(_ key: String) -> TeamValidationResult {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return .invalid("Security key cannot be empty.")
        }
        guard canonicalSecurityKey(trimmed) != nil else {
            return .invalid("\"\(key)\" is not a recognized security key.")
        }
        return .valid
    }

    /// Must be `nil`; the field is reserved.
    static func validateCustomSecurityKey(_ key: String?) -> TeamValidationResult {
        guard key == nil else {
            return .customSecurityKeyNotSupported
        }
        return .valid
    }

    static func validateTeamName(_ name: String) -> TeamValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return .invalid("Team name cannot be empty.")
        }
        return .valid
    }

    /// One result per field; check with `allPassed(_:)`.
    static func validateTeam(_ team: Team, in region: Region) -> [TeamValidationResult] {
        [
            validateNetworkId(team.networkId),
            validateRFChannel(team.rfChannel, in: region),
            validateSecurityKey(team.securityKey),
            validateCustomSecurityKey(team.customSecurityKey),
            validateTeamName(team.name)
        ]
    }

    static func allPassed(_ results: [TeamValidationResult]) -> Bool {
        results.allSatisfy { $0 == .valid }
    }
}
