import Foundation
import Combine
import SwiftUI

public enum ActiveScreen {
    case launch
    case welcome
    case mainMenu
    case modeSelect
    case levelSelect
    case garage
    case gameplay
}

public enum GameMode: String, CaseIterable, Identifiable, Codable {
    case challenge = "challenge"
    case career = "career"
    case endless = "endless"
    case freeRide = "freeRide"
    case timeTrial = "timeTrial"
    case chase = "chase"
    
    public var id: String { self.rawValue }
    
    public var displayName: String {
        switch self {
        case .challenge: return "Challenge"
        case .career: return "Career Race"
        case .endless: return "Endless"
        case .freeRide: return "Free Ride"
        case .timeTrial: return "Time Trial"
        case .chase: return "Highway Chase"
        }
    }
    
    public var unlockCost: Int {
        switch self {
        case .chase: return 99000
        default: return 0
        }
    }
}

public class GameState: ObservableObject {
    // Navigational states
    @Published public var currentScreen: ActiveScreen = .launch
    @Published public var selectedMode: GameMode = .endless
    @Published public var selectedLocationId: String = "farmland"
    @Published public var activeMissionId: String? = nil
    
    // Loaded Catalogues (Static Data)
    @Published public var cars: [Car] = []
    @Published public var locations: [Location] = []
    @Published public var missions: [Mission] = []
    
    // User Session Profile (Persisted Data)
    @Published public var save: SaveData = SaveData()
    
    // Active Car calculated shortcuts
    public var currentCar: Car {
        cars.first(where: { $0.id == save.selectedCarId }) ?? cars.first ?? fallbackCar()
    }
    
    public var activeLocation: Location {
        locations.first(where: { $0.id == selectedLocationId }) ?? locations.first ?? fallbackLocation()
    }
    
    public var activeMission: Mission? {
        missions.first(where: { $0.id == activeMissionId })
    }
    
    // Audio controller reference
    public var audioController: AudioController?
    
    // App constants
    private let saveKey = "TRAFFIC_RACER_SAVE_STATE"
    
    public init() {
        loadCatalogues()
        loadProgress()
        
        // Setup initial default selected car customization values if needed
        syncOwnedCars()
    }
    
    // MARK: - Save and Load Persistence
    
    public func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            do {
                let decoded = try JSONDecoder().decode(SaveData.self, at: data)
                self.save = decoded
                
                // Merge owned cars loaded from persistence back into catalog
                for savedCar in save.ownedCars {
                    if let index = cars.firstIndex(where: { $0.id == savedCar.id }) {
                        cars[index] = savedCar
                    }
                }
                
                // Sync unlocks
                for id in save.unlockedCarIds {
                    if let index = cars.firstIndex(where: { $0.id == id }) {
                        cars[index].isUnlocked = true
                    }
                }
                
                // Sync missions completion states
                for missionId in save.completedMissionIds {
                    if let index = missions.firstIndex(where: { $0.id == missionId }) {
                        missions[index].isCompleted = true
                    }
                }
                
                // Sync mission high scores
                for (mId, score) in save.missionHighScores {
                    if let index = missions.firstIndex(where: { $0.id == mId }) {
                        missions[index].highHighScore = score
                    }
                }
                
            } catch {
                print("Failed to decode save data: \(error)")
                createNewSave()
            }
        } else {
            createNewSave()
        }
    }
    
    private func createNewSave() {
        self.save = SaveData()
        // Mule is free and unlocked initially
        if let index = cars.firstIndex(where: { $0.id == "mule" }) {
            cars[index].isUnlocked = true
        }
        save.ownedCars = cars.filter { $0.isUnlocked }
        saveProgress()
    }
    
    public func saveProgress() {
        // Prepare owned cars list
        save.ownedCars = cars.filter { $0.isUnlocked }
        save.unlockedCarIds = cars.filter { $0.isUnlocked }.map { $0.id }
        
        do {
            let encoded = try JSONEncoder().encode(save)
            UserDefaults.standard.set(encoded, forKey: saveKey)
        } catch {
            print("Failed to encode save data: \(error)")
        }
    }
    
    private func syncOwnedCars() {
        for index in 0..<cars.count {
            if save.unlockedCarIds.contains(cars[index].id) {
                cars[index].isUnlocked = true
            }
        }
        
        // Make sure selectedCarId exists
        if !save.unlockedCarIds.contains(save.selectedCarId) {
            save.selectedCarId = "mule"
        }
    }
    
    // MARK: - Level & Progression Helpers
    
    public var currentLevel: Int {
        // 10,000 EXP per level
        return (save.exp / 10000) + 1
    }
    
    public var expProgressFraction: Double {
        let currentExpRemainder = save.exp % 10000
        return Double(currentExpRemainder) / 10000.0
    }
    
    public func addRewards(cashReward: Int, expReward: Int) {
        save.cash += cashReward
        save.exp += expReward
        saveProgress()
    }
    
    // MARK: - Daily Rewards
    
    public func isDailyRewardAvailable() -> Bool {
        guard let lastClaimStr = save.lastDailyRewardClaimedDate else {
            return true // Never claimed
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let lastClaimDate = formatter.date(from: lastClaimStr) else {
            return true
        }
        
        // Check if calendar day is greater
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(lastClaimDate)
        return !isToday
    }
    
    public func claimDailyReward() -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        
        // Calculate Streak reward
        // Escalating: Day 1: 500, Day 2: 1000, Day 3: 1500 ... Day 7: 5000
        var streak = save.dailyRewardStreak
        
        if let lastClaimStr = save.lastDailyRewardClaimedDate,
           let lastClaimDate = formatter.date(from: lastClaimStr) {
            let calendar = Calendar.current
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()),
               calendar.isDate(lastClaimDate, inSameDayAs: yesterday) {
                // Consecutive day
                streak = (streak % 7) + 1
            } else if calendar.isDateInToday(lastClaimDate) {
                // Already claimed today
                return 0
            } else {
                // Broke streak, reset
                streak = 1
            }
        } else {
            // First time ever
            streak = 1
        }
        
        let rewards = [500, 1000, 1500, 2000, 2800, 3800, 5000]
        let amount = rewards[min(streak - 1, rewards.count - 1)]
        
        save.cash += amount
        save.dailyRewardStreak = streak
        save.lastDailyRewardClaimedDate = todayStr
        saveProgress()
        
        return amount
    }
    
    // MARK: - Garage Actions
    
    public func selectCar(id: String) {
        guard let car = cars.first(where: { $0.id == id }), car.isUnlocked else { return }
        save.selectedCarId = id
        saveProgress()
    }
    
    public func purchaseCar(id: String) -> Bool {
        guard let index = cars.firstIndex(where: { $0.id == id }), !cars[index].isUnlocked else { return false }
        let cost = cars[index].price
        
        if save.cash >= cost {
            save.cash -= cost
            cars[index].isUnlocked = true
            save.selectedCarId = id
            saveProgress()
            return true
        }
        return false
    }
    
    public func unlockCarViaAd(id: String) {
        guard let index = cars.firstIndex(where: { $0.id == id }), !cars[index].isUnlocked else { return }
        // Watch ad - stub reward
        cars[index].isUnlocked = true
        save.selectedCarId = id
        saveProgress()
    }
    
    public func upgradeCar(id: String, category: UpgradeCategory) -> Bool {
        guard let index = cars.firstIndex(where: { $0.id == id }), cars[index].isUnlocked else { return false }
        let car = cars[index]
        let cost = car.upgradeCost(for: category)
        
        guard cost > 0 && save.cash >= cost else { return false }
        
        save.cash -= cost
        switch category {
        case .speed:
            if cars[index].speedUpgrades < 5 {
                cars[index].speedUpgrades += 1
            }
        case .handling:
            if cars[index].handlingUpgrades < 5 {
                cars[index].handlingUpgrades += 1
            }
        case .brake:
            if cars[index].brakeUpgrades < 5 {
                cars[index].brakeUpgrades += 1
            }
        }
        saveProgress()
        return true
    }
    
    public func customizeCar(id: String, paintColorHex: String, wheelStyle: String, lightColorHex: String, plateText: String) {
        guard let index = cars.firstIndex(where: { $0.id == id }), cars[index].isUnlocked else { return }
        cars[index].paintColorHex = paintColorHex
        cars[index].wheelStyle = wheelStyle
        cars[index].lightColorHex = lightColorHex
        
        let cleanedPlate = String(plateText.prefix(8)).uppercased()
        cars[index].plateText = cleanedPlate.isEmpty ? "RACER" : cleanedPlate
        
        saveProgress()
    }
    
    // MARK: - Ad Stubs
    
    public func watchAdForCash() {
        // Grants starting/ad reward (+500 cash)
        save.cash += 500
        saveProgress()
    }
    
    public func claimAdDoubleRewards(baseCash: Int, baseExp: Int) {
        // Grants another full round of cash/EXP
        save.cash += baseCash
        save.exp += baseExp
        saveProgress()
    }
    
    // MARK: - Mode Locks
    
    public func isModeUnlocked(_ mode: GameMode) -> Bool {
        if mode == .chase {
            return save.unlockedCarIds.contains("chase_unlocked") || save.cash >= mode.unlockCost || save.completedMissionIds.count >= 10
        }
        return true
    }
    
    public func buyMode(_ mode: GameMode) -> Bool {
        guard mode == .chase else { return true }
        if save.cash >= mode.unlockCost {
            save.cash -= mode.unlockCost
            save.unlockedCarIds.append("chase_unlocked")
            saveProgress()
            return true
        }
        return false
    }
    
    // MARK: - Mission Logic
    
    public func completeMission(id: String, score: Int) {
        guard let index = missions.firstIndex(where: { $0.id == id }) else { return }
        let mission = missions[index]
        
        if !save.completedMissionIds.contains(id) {
            save.completedMissionIds.append(id)
            missions[index].isCompleted = true
            // Grant mission rewards
            save.cash += mission.cashReward
            save.exp += 2500 // Generous mission completion EXP
        }
        
        let currentHighScore = save.missionHighScores[id] ?? 0
        if score > currentHighScore {
            save.missionHighScores[id] = score
            missions[index].highHighScore = score
        }
        
        saveProgress()
    }
    
    // MARK: - Endless Score Persistence
    
    public func updateEndlessScore(_ score: Int) -> Bool {
        if score > save.endlessHighScore {
            save.endlessHighScore = score
            saveProgress()
            return true // New high score
        }
        return false
    }
    
    // MARK: - JSON Catalogue Loading
    
    private func loadCatalogues() {
        // Load cars
        if let carsUrl = Bundle.main.url(forResource: "cars", withExtension: "json") ?? Bundle.main.url(forResource: "Resources/cars", withExtension: "json") {
            do {
                let data = try Data(contentsOf: carsUrl)
                self.cars = try JSONDecoder().decode([Car].self, from: data)
            } catch {
                print("Failed to load cars.json from Bundle, falling back: \(error)")
                self.cars = loadFallbackCars()
            }
        } else {
            self.cars = loadFallbackCars()
        }
        
        // Load locations
        if let locUrl = Bundle.main.url(forResource: "locations", withExtension: "json") ?? Bundle.main.url(forResource: "Resources/locations", withExtension: "json") {
            do {
                let data = try Data(contentsOf: locUrl)
                self.locations = try JSONDecoder().decode([Location].self, from: data)
            } catch {
                print("Failed to load locations.json from Bundle: \(error)")
                self.locations = loadFallbackLocations()
            }
        } else {
            self.locations = loadFallbackLocations()
        }
        
        // Load missions
        if let missUrl = Bundle.main.url(forResource: "missions", withExtension: "json") ?? Bundle.main.url(forResource: "Resources/missions", withExtension: "json") {
            do {
                let data = try Data(contentsOf: missUrl)
                self.missions = try JSONDecoder().decode([Mission].self, from: data)
            } catch {
                print("Failed to load missions.json from Bundle: \(error)")
                self.missions = loadFallbackMissions()
            }
        } else {
            self.missions = loadFallbackMissions()
        }
    }
    
    // MARK: - Fallback Data (Guarantees app never crashes)
    
    private func fallbackCar() -> Car {
        return Car(id: "mule", name: "Mule", baseSpeed: 1, baseHandling: 1, baseBrake: 1, topSpeedKPH: 198, price: 0, paintColorHex: "#3A86FF", wheelStyle: "standard", lightColorHex: "#00FFFF", plateText: "MULE-01", isUnlocked: true)
    }
    
    private func fallbackLocation() -> Location {
        return Location(id: "farmland", name: "Farmland", skyboxColorHex: "#75D5FD", ambientLightColorHex: "#3F3E3F", directionalLightColorHex: "#FFFCE5", isTwoWay: false, frictionMultiplier: 1.0, groundSceneryType: "farmland", isNight: false, hasFireworks: false, unlockRequiredLevel: 1)
    }
    
    private func loadFallbackCars() -> [Car] {
        return [
            Car(id: "mule", name: "Mule", baseSpeed: 1, baseHandling: 1, baseBrake: 1, topSpeedKPH: 198, price: 0, paintColorHex: "#3A86FF", wheelStyle: "standard", lightColorHex: "#00FFFF", plateText: "MULE-01", isUnlocked: true),
            Car(id: "volt", name: "Volt", baseSpeed: 2, baseHandling: 1, baseBrake: 1, topSpeedKPH: 211, price: 15000, paintColorHex: "#FFBE0B", wheelStyle: "standard", lightColorHex: "#00FFFF", plateText: "VOLT-02", isUnlocked: false),
            Car(id: "apex", name: "Apex", baseSpeed: 2, baseHandling: 2, baseBrake: 2, topSpeedKPH: 229, price: 30000, paintColorHex: "#FF006E", wheelStyle: "sport", lightColorHex: "#FF00FF", plateText: "APEX-03", isUnlocked: false),
            Car(id: "comet", name: "Comet", baseSpeed: 3, baseHandling: 2, baseBrake: 2, topSpeedKPH: 251, price: 50000, paintColorHex: "#FB5607", wheelStyle: "deepdish", lightColorHex: "#FF9F1C", plateText: "CMT-04", isUnlocked: false),
            Car(id: "hunter", name: "Hunter", baseSpeed: 2, baseHandling: 2, baseBrake: 3, topSpeedKPH: 218, price: 75000, paintColorHex: "#38B000", wheelStyle: "standard", lightColorHex: "#00FF00", plateText: "HNTR-05", isUnlocked: false),
            Car(id: "neon", name: "Neon", baseSpeed: 3, baseHandling: 3, baseBrake: 2, topSpeedKPH: 242, price: 100000, paintColorHex: "#8338EC", wheelStyle: "sport", lightColorHex: "#9D4EDD", plateText: "NEON-06", isUnlocked: false),
            Car(id: "blaze", name: "Blaze", baseSpeed: 3, baseHandling: 3, baseBrake: 2, topSpeedKPH: 264, price: 150000, paintColorHex: "#E63946", wheelStyle: "sport", lightColorHex: "#E63946", plateText: "BLZ-07", isUnlocked: false),
            Car(id: "venom", name: "Venom", baseSpeed: 4, baseHandling: 3, baseBrake: 3, topSpeedKPH: 285, price: 220000, paintColorHex: "#1D3557", wheelStyle: "sport", lightColorHex: "#A8DADC", plateText: "VNM-08", isUnlocked: false),
            Car(id: "raptor", name: "Raptor", baseSpeed: 3, baseHandling: 3, baseBrake: 4, topSpeedKPH: 248, price: 310000, paintColorHex: "#4A4E69", wheelStyle: "deepdish", lightColorHex: "#F2E9E1", plateText: "RPTR-09", isUnlocked: false),
            Car(id: "drake", name: "Drake", baseSpeed: 3, baseHandling: 3, baseBrake: 3, topSpeedKPH: 295, price: 420000, paintColorHex: "#2A9D8F", wheelStyle: "sport", lightColorHex: "#E9C46A", plateText: "DRK-10", isUnlocked: false),
            Car(id: "valkyrie", name: "Valkyrie", baseSpeed: 4, baseHandling: 4, baseBrake: 3, topSpeedKPH: 331, price: 580000, paintColorHex: "#D62828", wheelStyle: "sport", lightColorHex: "#F77F00", plateText: "VLK-11", isUnlocked: false),
            Car(id: "titan", name: "Titan", baseSpeed: 3, baseHandling: 4, baseBrake: 5, topSpeedKPH: 272, price: 800000, paintColorHex: "#003049", wheelStyle: "deepdish", lightColorHex: "#FCBF49", plateText: "TTN-12", isUnlocked: false),
            Car(id: "carbon", name: "Carbon", baseSpeed: 5, baseHandling: 4, baseBrake: 4, topSpeedKPH: 376, price: 1200000, paintColorHex: "#212529", wheelStyle: "sport", lightColorHex: "#E0E1DD", plateText: "CRBN-13", isUnlocked: false),
            Car(id: "sovereign", name: "Sovereign", baseSpeed: 4, baseHandling: 5, baseBrake: 5, topSpeedKPH: 348, price: 2500000, paintColorHex: "#7209B7", wheelStyle: "deepdish", lightColorHex: "#4CC9F0", plateText: "SVRN-14", isUnlocked: false),
            Car(id: "phantom", name: "Phantom", baseSpeed: 5, baseHandling: 5, baseBrake: 5, topSpeedKPH: 431, price: 5000000, paintColorHex: "#000000", wheelStyle: "sport", lightColorHex: "#00FFFF", plateText: "PHTM-15", isUnlocked: false)
        ]
    }
    
    private func loadFallbackLocations() -> [Location] {
        return [
            Location(id: "farmland", name: "Farmland", skyboxColorHex: "#75D5FD", ambientLightColorHex: "#3F3E3F", directionalLightColorHex: "#FFFCE5", isTwoWay: false, frictionMultiplier: 1.0, groundSceneryType: "farmland", isNight: false, hasFireworks: false, unlockRequiredLevel: 1),
            Location(id: "city", name: "Neon City", skyboxColorHex: "#05020C", ambientLightColorHex: "#1A1A2F", directionalLightColorHex: "#4A0E4E", isTwoWay: false, frictionMultiplier: 1.0, groundSceneryType: "city", isNight: true, hasFireworks: false, unlockRequiredLevel: 2),
            Location(id: "mountain_day", name: "Mountain (Day)", skyboxColorHex: "#A2D2FF", ambientLightColorHex: "#4A4D4A", directionalLightColorHex: "#FFEAA7", isTwoWay: true, frictionMultiplier: 1.0, groundSceneryType: "mountain", isNight: false, hasFireworks: false, unlockRequiredLevel: 3),
            Location(id: "mountain_night", name: "Mountain (Night)", skyboxColorHex: "#0A0D1A", ambientLightColorHex: "#1E1E2F", directionalLightColorHex: "#2D305A", isTwoWay: true, frictionMultiplier: 1.0, groundSceneryType: "mountain", isNight: true, hasFireworks: true, unlockRequiredLevel: 4),
            Location(id: "snow", name: "Frost Snow", skyboxColorHex: "#E8F1F5", ambientLightColorHex: "#5A5D66", directionalLightColorHex: "#EAF4F7", isTwoWay: false, frictionMultiplier: 0.4, groundSceneryType: "snow", isNight: false, hasFireworks: false, unlockRequiredLevel: 5)
        ]
    }
    
    private func loadFallbackMissions() -> [Mission] {
        return [
            Mission(id: "challenge_1", challengeNumber: 1, objectiveText: "Reach the finish line before time runs out!", targetType: .reachFinishLine, targetValue: 1500, targetTimeLimit: 45, cashReward: 2000, isCompleted: false, highHighScore: 0),
            Mission(id: "challenge_2", challengeNumber: 2, objectiveText: "Reach a top speed of 180 km/h!", targetType: .reachSpeedLimit, targetValue: 180, targetTimeLimit: 30, cashReward: 3000, isCompleted: false, highHighScore: 0),
            Mission(id: "challenge_3", challengeNumber: 3, objectiveText: "Perform 5 near-misses in under 60 seconds!", targetType: .performNearMisses, targetValue: 5, targetTimeLimit: 60, cashReward: 4000, isCompleted: false, highHighScore: 0),
            Mission(id: "challenge_4", challengeNumber: 4, objectiveText: "Accumulate 3,000 meters of total distance!", targetType: .accumulateDistance, targetValue: 3000, targetTimeLimit: 90, cashReward: 5000, isCompleted: false, highHighScore: 0),
            Mission(id: "challenge_5", challengeNumber: 5, objectiveText: "Hold a high speed of 150 km/h for 15 seconds!", targetType: .holdSpeedDuration, targetValue: 15, targetTimeLimit: 45, cashReward: 6000, isCompleted: false, highHighScore: 0)
        ]
    }
}
