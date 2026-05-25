import Foundation

public struct Car: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let baseSpeed: Int      // 1 to 5 pips
    public let baseHandling: Int   // 1 to 5 pips
    public let baseBrake: Int      // 1 to 5 pips
    public let topSpeedKPH: Int    // Base top speed (e.g. 198)
    public let price: Int          // Cash required to unlock
    
    // Active upgrades (0 to 5 max)
    public var speedUpgrades: Int = 0
    public var handlingUpgrades: Int = 0
    public var brakeUpgrades: Int = 0
    
    // Customizations
    public var paintColorHex: String
    public var wheelStyle: String    // "standard", "sport", "deepdish"
    public var lightColorHex: String   // Cyan, Red, Green, Yellow, Blue, Pink (Underglow)
    public var plateText: String
    public var isUnlocked: Bool
    
    // Identifiable protocol support
    public var UUID: String { id }
    
    // Custom initializer
    public init(id: String, name: String, baseSpeed: Int, baseHandling: Int, baseBrake: Int, topSpeedKPH: Int, price: Int, paintColorHex: String = "#3A86FF", wheelStyle: String = "standard", lightColorHex: "#00FFFF", plateText: String = "RACER", isUnlocked: Bool = false) {
        self.id = id
        self.name = name
        self.baseSpeed = baseSpeed
        self.baseHandling = baseHandling
        self.baseBrake = baseBrake
        self.topSpeedKPH = topSpeedKPH
        self.price = price
        self.paintColorHex = paintColorHex
        self.wheelStyle = wheelStyle
        self.lightColorHex = lightColorHex
        self.plateText = plateText
        self.isUnlocked = isUnlocked
    }
    
    // Calculated statistics including upgrades
    public var speedStat: Int { min(5, baseSpeed + speedUpgrades) }
    public var handlingStat: Int { min(5, baseHandling + handlingUpgrades) }
    public var brakeStat: Int { min(5, baseBrake + brakeUpgrades) }
    
    public var maxSpeedKPH: Int {
        topSpeedKPH + (speedUpgrades * 15) // +15 KPH per upgrade pip
    }
    
    // Upgrade costs per pip: base price scales
    public func upgradeCost(for category: UpgradeCategory) -> Int {
        let currentPips: Int
        switch category {
        case .speed: currentPips = speedUpgrades
        case .handling: currentPips = handlingUpgrades
        case .brake: currentPips = brakeUpgrades
        }
        
        guard currentPips < 5 else { return 0 } // Maxed out
        
        // Cost starts at 5,000 cash and scales up steeply
        return 5000 + (currentPips * 7500)
    }
}

public enum UpgradeCategory: String, Codable {
    case speed
    case handling
    case brake
}
