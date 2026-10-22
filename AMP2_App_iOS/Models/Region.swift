import Foundation

/// The three operating regions that govern RF channel availability.
enum Region: String, CaseIterable, Codable, Sendable {
    case northAmerica
    case latinAmerica
    case eurasia

    var displayName: String {
        switch self {
        case .northAmerica: return "North America"
        case .latinAmerica: return "Latin America"
        case .eurasia: return "Eurasia"
        }
    }

    /// 1–5 in every region, so teams move between regions unchanged.
    var availableChannels: ClosedRange<Int> {
        1...5
    }

    /// Accepts a raw value or display name, any case.
    init?(from string: String) {
        for region in Region.allCases {
            if region.rawValue.caseInsensitiveCompare(string) == .orderedSame
                || region.displayName.caseInsensitiveCompare(string) == .orderedSame {
                self = region
                return
            }
        }
        return nil
    }
}
