import Foundation

public struct Mission: Codable, Identifiable, Equatable {
    public let id: String
    public let challengeNumber: Int
    public let objectiveText: String
    public let targetType: TargetType
    public let targetValue: Double    // Distance to reach (m), Speed to hit (KPH), Time to hold speed (s), Near-misses count
    public let targetTimeLimit: Double // Time limit (0 if none)
    public let cashReward: Int
    public var isCompleted: Bool
    public var highHighScore: Int
    
    public var UUID: String { id }
    
    public enum TargetType: String, Codable {
        case reachFinishLine      // Finish a fixed Z distance in time
        case reachSpeedLimit      // Hit a speed threshold in time
        case holdSpeedDuration    // Stay above speed target for duration in time limit
        case performNearMisses    // Complete X near misses in time
        case accumulateDistance   // Survive for X distance in time
        case careerPosition       // Finish 1st vs Rival
    }
}
