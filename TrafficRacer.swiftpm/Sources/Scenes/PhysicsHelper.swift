import Foundation

public struct PhysicsCategory {
    public static let none: Int      = 0
    public static let player: Int    = 1 << 0  // 1
    public static let traffic: Int   = 1 << 1  // 2
    public static let rival: Int     = 1 << 2  // 4
    public static let road: Int      = 1 << 3  // 8
}
