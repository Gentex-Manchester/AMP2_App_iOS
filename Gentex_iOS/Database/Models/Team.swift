import Foundation

/// Custom team. Fields mirror the Android entity.
struct Team: Identifiable, Codable, Equatable, Hashable, Sendable {
    var id: Int64
    var region: String
    var rfChannel: Int
    var securityKey: String
    var customSecurityKey: String?
    var networkId: Int
    var name: String
    var isFavorited: Bool
    var isLocked: Bool

    init(
        id: Int64 = 0,
        region: String,
        rfChannel: Int,
        securityKey: String,
        customSecurityKey: String? = nil,
        networkId: Int,
        name: String,
        isFavorited: Bool = false,
        isLocked: Bool = false
    ) {
        self.id = id
        self.region = region
        self.rfChannel = rfChannel
        self.securityKey = securityKey
        self.customSecurityKey = customSecurityKey
        self.networkId = networkId
        self.name = name
        self.isFavorited = isFavorited
        self.isLocked = isLocked
    }

    /// Compares settings only, ignoring `id`, `isFavorited`, and `isLocked`.
    func isDuplicate(of other: Team) -> Bool {
        self.region == other.region
            && self.rfChannel == other.rfChannel
            && self.securityKey == other.securityKey
            && self.networkId == other.networkId
            && self.name == other.name
    }
}
