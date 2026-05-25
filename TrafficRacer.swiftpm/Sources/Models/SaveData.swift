import Foundation

public struct SaveData: Codable {
    public var cash: Int = 20000          // Start with a generous starting bonus
    public var exp: Int = 0
    public var unlockedCarIds: [String] = ["mule"]
    public var selectedCarId: String = "mule"
    public var ownedCars: [Car] = []
    public var completedMissionIds: [String] = []
    public var missionHighScores: [String: Int] = [:]
    public var endlessHighScore: Int = 0
    public var lastDailyRewardClaimedDate: String? = nil
    public var dailyRewardStreak: Int = 0
    
    // Settings
    public var isSoundEnabled: Bool = true
    public var isVoiceEnabled: Bool = true
    public var musicVolume: Float = 0.8
    public var sfxVolume: Float = 0.8
    public var isAutoAcceleration: Bool = true
    public var isKMUnit: Bool = true
    public var controlType: String = "buttons" // "buttons" or "tilt"
    
    public init() {}
}
