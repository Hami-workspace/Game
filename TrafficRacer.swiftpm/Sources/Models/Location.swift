import Foundation

public struct Location: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let skyboxColorHex: String
    public let ambientLightColorHex: String
    public let directionalLightColorHex: String
    public let isTwoWay: Bool
    public let frictionMultiplier: Float
    public let groundSceneryType: String // "farmland", "city", "mountain", "snow"
    public let isNight: Bool
    public let hasFireworks: Bool
    public let unlockRequiredLevel: Int
    
    public var UUID: String { id }
}
