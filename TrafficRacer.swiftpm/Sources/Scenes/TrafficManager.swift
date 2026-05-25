import Foundation
import SceneKit

public class TrafficManager {
    private let scene: SCNScene
    private var activeTraffic: [SCNNode] = []
    private var trafficPool: [SCNNode] = []
    
    // Lane coordinates: 4 lanes
    private let lanePositions: [Float] = [-5.25, -1.75, 1.75, 5.25]
    
    // Speed configs (m/s)
    // 70 KPH = 19.4m/s; 90 KPH = 25m/s; 120 KPH = 33.3m/s
    private var trafficSpeeds: [String: Float] = [
        "sedan": 25.0,
        "sports": 33.3,
        "pickup": 27.8,
        "truck": 20.8,
        "tanker": 19.4
    ]
    
    public init(scene: SCNScene) {
        self.scene = scene
    }
    
    // MARK: - Initial Spawn Setup
    
    public func resetTraffic() {
        for vehicle in activeTraffic {
            vehicle.removeFromParentNode()
        }
        activeTraffic.removeAll()
        trafficPool.removeAll()
    }
    
    // MARK: - Spawner Logic
    
    public func updateTraffic(playerPositionZ: Float, location: Location, densityScale: Float, deltaTime: Double) {
        // Recycle traffic that has fallen behind
        // Behind player means vehicle.position.z > playerPositionZ + 100m (since player drives down -Z)
        // Also, oncoming traffic might drive past the player in +Z direction, so if vehicle.z > playerPositionZ + 100m, recycle!
        
        var indicesToRemove: [Int] = []
        
        for idx in 0..<activeTraffic.count {
            let vehicle = activeTraffic[idx]
            
            // Check if vehicle has gone behind the player
            if vehicle.position.z > playerPositionZ + 100.0 {
                indicesToRemove.append(idx)
            }
        }
        
        // Remove recycled from active
        for idx in indicesToRemove.reversed() {
            let vehicle = activeTraffic[idx]
            vehicle.removeFromParentNode()
            activeTraffic.remove(at: idx)
        }
        
        // Dynamic target count based on location & density scale
        // Density scales with speed and mode (challenge vs endless)
        let baseCount = location.isTwoWay ? 6 : 8
        let targetCount = Int(Float(baseCount) * densityScale)
        
        // Spawn new traffic if below threshold
        if activeTraffic.count < targetCount {
            spawnSingleTraffic(playerPositionZ: playerPositionZ, location: location)
        }
        
        // Move active traffic
        for vehicle in activeTraffic {
            let type = vehicle.value(forKey: "vehicleType") as? String ?? "sedan"
            let laneIndex = vehicle.value(forKey: "laneIndex") as? Int ?? 2
            let baseSpeed = trafficSpeeds[type] ?? 25.0
            
            // In Two-Way modes: Left 2 lanes (0 and 1) drive TOWARDS player (+Z direction!)
            // Right 2 lanes (2 and 3) drive FORWARD (-Z direction, same as player)
            let isOncoming = location.isTwoWay && laneIndex < 2
            
            let moveAmount = baseSpeed * Float(deltaTime)
            if isOncoming {
                // Moving down the POSITIVE Z axis (oncoming traffic!)
                vehicle.position.z += moveAmount
                
                // Keep headlights facing towards player!
                vehicle.rotation = SCNVector4(0, 1, 0, Float.pi)
            } else {
                // Moving down the NEGATIVE Z axis (same direction as player!)
                vehicle.position.z -= moveAmount
                
                // Headlights face forward
                vehicle.rotation = SCNVector4(0, 1, 0, 0)
            }
        }
    }
    
    private func spawnSingleTraffic(playerPositionZ: Float, location: Location) {
        // Randomize traffic type: sedan, sports, pickup, truck, tanker
        let types = ["sedan", "sports", "pickup", "truck", "tanker"]
        let type = types.randomElement() ?? "sedan"
        
        let vehicleNode = VehicleNodeFactory.createTrafficVehicle(type: type)
        vehicleNode.name = "traffic_car"
        
        // Store attributes dynamically on SCNNode using KVC values
        vehicleNode.setValue(type, forKey: "vehicleType")
        
        // Choose random lane
        let laneIndex = Int.random(in: 0..<4)
        vehicleNode.setValue(laneIndex, forKey: "laneIndex")
        
        let laneX = lanePositions[laneIndex]
        
        // Spawn ahead of player
        // Random distance between 150m and 280m ahead of player
        let spawnDistance = Float.random(in: 150.0...280.0)
        let spawnZ = playerPositionZ - spawnDistance // -Z is forward
        
        vehicleNode.position = SCNVector3(laneX, 0, spawnZ)
        
        // Set up SceneKit Physics for contact checking
        // Kinematic rigid body (doesn't react to forces, moves strictly by transform)
        // Standard shape box matches average vehicle volume
        let physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        physicsBody.categoryBitMask = PhysicsCategory.traffic
        physicsBody.contactTestBitMask = PhysicsCategory.player
        physicsBody.collisionBitMask = PhysicsCategory.none
        vehicleNode.physicsBody = physicsBody
        
        scene.rootNode.addChildNode(vehicleNode)
        activeTraffic.append(vehicleNode)
    }
    
    // MARK: - Near-Miss Sensor Checks
    
    public struct PassResult {
        public let isNearMiss: Bool
        public let isOvertake: Bool
    }
    
    public func checkOvertakes(playerZ: Float, playerX: Float, playerWidth: Float) -> PassResult {
        // Loop active vehicles. If player has JUST passed them in -Z direction
        // (meaning playerZ is further negative than vehicleZ, i.e. playerZ < vehicleZ),
        // and they haven't been scored yet:
        
        var nearMissTriggered = false
        var overtakeTriggered = false
        
        for vehicle in activeTraffic {
            let scored = vehicle.value(forKey: "isScored") as? Bool ?? false
            if scored { continue }
            
            let vehicleZ = vehicle.position.z
            let vehicleX = vehicle.position.x
            
            // Check if player's rear has passed the vehicle's front
            // driving down -Z: playerZ < vehicleZ (since player is further ahead in -Z)
            if playerZ < vehicleZ - 2.0 {
                // Player passed this vehicle! Mark it scored
                vehicle.setValue(true, forKey: "isScored")
                
                // Calculate lateral distance
                let dx = abs(playerX - vehicleX)
                
                if dx < 2.0 {
                    // Extremely close pass: Near-Miss!
                    nearMissTriggered = true
                } else if dx <= 4.0 {
                    // Regular clean pass: Overtake!
                    overtakeTriggered = true
                }
            }
        }
        
        return PassResult(isNearMiss: nearMissTriggered, isOvertake: overtakeTriggered)
    }
}
