import Foundation
import SceneKit
import Combine

public class RaceScene: SCNScene, SCNPhysicsContactDelegate {
    
    // Core Managers
    public var roadManager: RoadManager!
    public var trafficManager: TrafficManager!
    
    // Nodes
    public var playerNode: SCNNode!
    public var rivalNode: SCNNode?
    public var cameraNode: SCNNode!
    
    // Parent references & data bridges
    private weak var gameState: GameState?
    
    // Controls States (Hooked from HUD inputs)
    public var steerInput: Float = 0.0      // -1.0 (Full Left) to +1.0 (Full Right)
    public var isAccelerating: Bool = false
    public var isBraking: Bool = false
    
    // Physics Simulation Variables
    public var currentSpeedKPH: Float = 0.0
    public var targetSpeedKPH: Float = 0.0
    public var currentGear: Int = 1
    public var totalDistanceMeters: Double = 0.0
    
    // Game Rules
    public var activeScore: Int = 0
    public var activeOvertakes: Int = 0
    public var activeNearMisses: Int = 0
    public var comboMultiplier: Int = 1
    public var comboTimer: Double = 0.0
    
    // Challenge Timer
    public var timeRemaining: Double = 60.0
    public var elapsedRunTime: Double = 0.0
    public var highSpeedDurationTimer: Double = 0.0 // Challenge 5
    
    // Gameplay Status
    public var isCrashed: Bool = false
    public var isFinished: Bool = false
    public var activeCameraMode: Int = 0    // 0 = Chase, 1 = Cockpit, 2 = TopDown
    
    // Career Rival specific
    private let finishLineDistance: Double = 1500.0 // 1.5km finish line
    
    // Snow physics slip vector
    private var lateralVelocity: Float = 0.0
    
    // MARK: - Initializer
    
    public func setupWorld(gameState: GameState) {
        self.gameState = gameState
        self.physicsWorld.contactDelegate = self
        
        // 1. Environmental Lights
        setupLights(location: gameState.activeLocation)
        
        // 2. Build endless road pool
        roadManager = RoadManager(scene: self)
        roadManager.buildInitialRoad(location: gameState.activeLocation)
        
        // 3. Setup Traffic Pool
        trafficManager = TrafficManager(scene: self)
        trafficManager.resetTraffic()
        
        // 4. Spawn Player Car Node
        playerNode = VehicleNodeFactory.createPlayerVehicle(car: gameState.currentCar)
        playerNode.position = SCNVector3(1.75, 0, 0) // start in right-inner lane
        
        // Configure player physics body for contact
        let playerBox = SCNPhysicsBody(type: .kinematic, shape: nil)
        playerBox.categoryBitMask = PhysicsCategory.player
        playerBox.contactTestBitMask = PhysicsCategory.traffic | PhysicsCategory.rival
        playerBox.collisionBitMask = PhysicsCategory.none
        playerNode.physicsBody = playerBox
        
        self.rootNode.addChildNode(playerNode)
        
        // 5. Spawn Career AI Rival (if career mode is active)
        if gameState.selectedMode == .career {
            spawnCareerRival()
        }
        
        // 6. Camera Setup
        setupCamera()
        
        // Initialize Mode-specific states
        resetStats(mode: gameState.selectedMode)
    }
    
    private func setupLights(location: Location) {
        // Ambient illumination
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(hex: location.ambientLightColorHex)
        ambientLight.intensity = location.isNight ? 400 : 800
        let ambient = SCNNode()
        ambient.light = ambientLight
        self.rootNode.addChildNode(ambient)
        
        // Directional Sun/Moon light
        let directional = SCNLight()
        directional.type = .directional
        directional.color = UIColor(hex: location.directionalLightColorHex)
        directional.intensity = location.isNight ? 500 : 1600
        directional.castsShadow = !location.isNight // shadows look premium on daytime farmland
        directional.shadowRadius = 8.0
        directional.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        
        let sun = SCNNode()
        sun.light = directional
        sun.position = SCNVector3(10, 25, 10)
        sun.look(at: SCNVector3(0, 0, 0))
        self.rootNode.addChildNode(sun)
        
        // If Mountain-Night, add subtle colorful spot lights representing background fireworks
        if location.hasFireworks {
            let fireworkColors = [UIColor.magenta, UIColor.cyan, UIColor.yellow, UIColor.orange]
            for i in 0..<3 {
                let fNode = SCNNode()
                let light = SCNLight()
                light.type = .omni
                light.color = fireworkColors.randomElement()!
                light.intensity = 1500
                light.attenuationStartDistance = 10
                light.attenuationEndDistance = 150
                fNode.light = light
                fNode.position = SCNVector3(Float.random(in: -100...100), Float.random(in: 40...80), Float.random(in: -300...(-100 * Float(i))))
                self.rootNode.addChildNode(fNode)
            }
        }
    }
    
    private func setupCamera() {
        let camera = SCNCamera()
        camera.zNear = 0.1
        camera.zFar = 600
        
        cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.name = "race_camera"
        self.rootNode.addChildNode(cameraNode)
        
        updateCameraTransform(animated: false)
    }
    
    private func spawnCareerRival() {
        guard let gameState = gameState else { return }
        
        // Spawn Comet or Blaze as rival
        let rivalProfile = Car(id: "rival_blaze", name: "AI Rival", baseSpeed: 3, baseHandling: 3, baseBrake: 3, topSpeedKPH: 260, price: 0, paintColorHex: "#FF0000", wheelStyle: "sport", lightColorHex: "#FF0000", plateText: "LEGEND-1", isUnlocked: true)
        
        let node = VehicleNodeFactory.createPlayerVehicle(car: rivalProfile)
        node.name = "career_rival"
        node.position = SCNVector3(-1.75, 0, -20.0) // starts slightly ahead in left-inner lane
        
        let rivalBox = SCNPhysicsBody(type: .kinematic, shape: nil)
        rivalBox.categoryBitMask = PhysicsCategory.rival
        rivalBox.contactTestBitMask = PhysicsCategory.player
        rivalBox.collisionBitMask = PhysicsCategory.none
        node.physicsBody = rivalBox
        
        self.rootNode.addChildNode(node)
        self.rivalNode = node
    }
    
    private func resetStats(mode: GameMode) {
        currentSpeedKPH = 0.0
        totalDistanceMeters = 0.0
        activeScore = 0
        activeOvertakes = 0
        activeNearMisses = 0
        comboMultiplier = 1
        comboTimer = 0.0
        elapsedRunTime = 0.0
        highSpeedDurationTimer = 0.0
        isCrashed = false
        isFinished = false
        
        // Setup countdown timer targets
        if let mission = gameState?.activeMission {
            timeRemaining = mission.targetTimeLimit
        } else if mode == .timeTrial {
            timeRemaining = 30.0 // Survive 30 seconds initially
        } else {
            timeRemaining = 0.0
        }
    }
    
    // MARK: - Frame Render Update Loop
    
    public func updateFrame(deltaTime: Double) {
        guard !isCrashed && !isFinished else {
            // Slow motion tumble crash simulation if crashed
            if isCrashed {
                simulateCrashTumble(deltaTime: deltaTime)
            }
            return
        }
        
        guard let gameState = gameState else { return }
        
        elapsedRunTime += deltaTime
        
        // 1. Mode Specific Timer countdown
        if gameState.selectedMode == .challenge || gameState.selectedMode == .timeTrial {
            timeRemaining -= deltaTime
            if timeRemaining <= 0 {
                timeRemaining = 0
                // Time's up! Fail state
                triggerGameOver(victory: false)
                return
            }
        }
        
        // 2. Physics Movement (Speed + Gear + Transmission calculations)
        calculatePhysics(deltaTime: deltaTime)
        
        // 3. Environment & Highway Segment Recycling
        roadManager.updateRecycling(playerPositionZ: playerNode.position.z, location: gameState.activeLocation)
        
        // 4. AI Traffic Updates
        // Spawning density scales with vehicle velocity
        let speedFactor = max(0.5, currentSpeedKPH / 200.0)
        trafficManager.updateTraffic(playerPositionZ: playerNode.position.z, location: gameState.activeLocation, densityScale: speedFactor, deltaTime: deltaTime)
        
        // 5. Overtakes and Near-Miss Contact sensor checks
        // No near-miss points in Career Mode (pure position race!)
        if gameState.selectedMode != .career {
            let passRes = trafficManager.checkOvertakes(playerZ: playerNode.position.z, playerX: playerNode.position.x, playerWidth: 1.8)
            
            if passRes.isNearMiss {
                triggerNearMiss()
            } else if passRes.isOvertake {
                triggerOvertake()
            }
        }
        
        // 6. Career Rival AI logic (Rubber-banding)
        if gameState.selectedMode == .career {
            updateCareerRivalAI(deltaTime: deltaTime)
        }
        
        // 7. Check Objective Target Win Triggers
        checkMissionObjectives(deltaTime: deltaTime)
        
        // 8. Combo Decay Timer
        if comboMultiplier > 1 {
            comboTimer -= deltaTime
            if comboTimer <= 0 {
                comboMultiplier = 1
                comboTimer = 0.0
            }
        }
        
        // 9. Camera Follow Transformation
        updateCameraTransform(animated: true)
    }
    
    // MARK: - Velocity Physics Mechanics
    
    private func calculatePhysics(deltaTime: Double) {
        guard let gameState = gameState else { return }
        let car = gameState.currentCar
        let loc = gameState.activeLocation
        
        // Acceleration automatic or manual hold
        let isGassing = gameState.save.isAutoAcceleration ? true : isAccelerating
        
        // Constants
        let maxKPH = Float(car.maxSpeedKPH)
        let accelRate: Float = 25.0 + (Float(car.speedStat) * 6.0) // Stat scales acceleration
        let brakeRate: Float = 60.0 + (Float(car.brakeStat) * 10.0) // Brakes decel
        let dragForce: Float = 8.0 // Drag coefficient
        
        // Apply acceleration or coasting drag
        if isGassing && !isBraking {
            currentSpeedKPH += accelRate * Float(deltaTime)
            if currentSpeedKPH > maxKPH {
                currentSpeedKPH = maxKPH
            }
        } else if isBraking {
            currentSpeedKPH -= brakeRate * Float(deltaTime)
            if currentSpeedKPH < 0 {
                currentSpeedKPH = 0
            }
        } else {
            // Drag coasting
            currentSpeedKPH -= dragForce * Float(deltaTime)
            if currentSpeedKPH < 0 {
                currentSpeedKPH = 0
            }
        }
        
        // Steering & Slip mechanics
        let baseHandling = 1.8 + (Float(car.handlingStat) * 0.4) // Handling responsiveness
        let lateralSpeed = baseHandling * (currentSpeedKPH / 80.0) // Steer response scales with speed
        
        // Friction coefficient impact on Snow stage
        let grip = loc.frictionMultiplier
        
        if grip < 1.0 {
            // Snow low-grip DRIFT slip
            let targetLateralVelocity = steerInput * lateralSpeed
            // Lateral inertia delay representing sliding
            lateralVelocity += (targetLateralVelocity - lateralVelocity) * 3.5 * Float(deltaTime)
            playerNode.position.x += lateralVelocity * Float(deltaTime)
            
            // Visual Drift rotation pitch angle yaw
            let driftAngle = (targetLateralVelocity - lateralVelocity) * 0.15
            playerNode.rotation = SCNVector4(0, 1, 0, driftAngle)
        } else {
            // Standard snappy high grip
            playerNode.position.x += steerInput * lateralSpeed * Float(deltaTime)
            // standard minor body roll rotation yaw
            playerNode.rotation = SCNVector4(0, 1, 0, steerInput * 0.08)
        }
        
        // Clamp steer boundaries inside concrete rails (X = -7.3 to 7.3)
        if playerNode.position.x < -7.3 {
            playerNode.position.x = -7.3
        } else if playerNode.position.x > 7.3 {
            playerNode.position.x = 7.3
        }
        
        // Convert KPH to Z forward displacement meters per second (driving down negative Z)
        let speedMPS = currentSpeedKPH * 0.2778
        let forwardMovement = speedMPS * Float(deltaTime)
        playerNode.position.z -= forwardMovement
        totalDistanceMeters += Double(forwardMovement)
        
        // Accumulate Endless Survival base points based on velocity
        if gameState.selectedMode == .endless && currentSpeedKPH > 80.0 {
            // Earn points continuously when moving fast
            let pts = Int(currentSpeedKPH * 0.1 * Float(deltaTime))
            activeScore += pts * comboMultiplier
        }
        
        // Transmission Gear Calculations
        calculateTransmission(speedKPH: currentSpeedKPH)
    }
    
    private func calculateTransmission(speedKPH: Float) {
        let oldGear = currentGear
        
        if speedKPH < 50.0 {
            currentGear = 1
        } else if speedKPH < 90.0 {
            currentGear = 2
        } else if speedKPH < 130.0 {
            currentGear = 3
        } else if speedKPH < 180.0 {
            currentGear = 4
        } else if speedKPH < 240.0 {
            currentGear = 5
        } else {
            currentGear = 6
        }
        
        // Audio pitch clank clank feedback on shift
        if oldGear != currentGear {
            gameState?.audioController?.playSFX("gear_click")
        }
        
        // Send RPM ratio to Audio Engine Varispeed node
        if let maxKPH = gameState?.currentCar.maxSpeedKPH {
            let speedRatio = speedKPH / Float(maxKPH)
            gameState?.audioController?.updateEngineRPM(speedRatio: speedRatio, gear: currentGear)
        }
    }
    
    // MARK: - Camera Follow Transforms
    
    public func cycleCamera() {
        gameState?.audioController?.playSFX("ui_click")
        activeCameraMode = (activeCameraMode + 1) % 3
        updateCameraTransform(animated: true)
    }
    
    private func updateCameraTransform(animated: Bool) {
        guard playerNode != nil && cameraNode != nil else { return }
        
        let targetCamPos: SCNVector3
        let targetLookAt = SCNVector3(playerNode.position.x, playerNode.position.y + 0.4, playerNode.position.z - 2.0)
        
        switch activeCameraMode {
        case 1:
            // First-Person Cockpit view (great in City night!)
            targetCamPos = SCNVector3(playerNode.position.x, playerNode.position.y + 1.15, playerNode.position.z - 0.45)
            cameraNode.camera?.fieldOfView = 85
        case 2:
            // Top-Down Aerial view
            targetCamPos = SCNVector3(playerNode.position.x, playerNode.position.y + 18.0, playerNode.position.z + 12.0)
            cameraNode.camera?.fieldOfView = 50
        default:
            // Third-Person Chase Cam (default)
            // Behind and slightly above player car
            targetCamPos = SCNVector3(playerNode.position.x * 0.85, playerNode.position.y + 2.3, playerNode.position.z + 5.5)
            cameraNode.camera?.fieldOfView = 65
        }
        
        if animated {
            // Smooth lerp camera movement
            let lerpFactor: Float = 0.12
            let currentPos = cameraNode.position
            let newX = currentPos.x + (targetCamPos.x - currentPos.x) * lerpFactor
            let newY = currentPos.y + (targetCamPos.y - currentPos.y) * lerpFactor
            let newZ = currentPos.z + (targetCamPos.z - currentPos.z) * lerpFactor
            
            cameraNode.position = SCNVector3(newX, newY, newZ)
        } else {
            cameraNode.position = targetCamPos
        }
        
        cameraNode.look(at: targetLookAt)
    }
    
    // MARK: - Near-Miss & Overtake scoring
    
    private func triggerOvertake() {
        activeOvertakes += 1
        
        // Multiplier combos reset countdown
        if comboMultiplier < 10 {
            comboMultiplier += 1
        }
        comboTimer = 3.0 // 3 seconds decay window
        
        let pts = 500 * comboMultiplier
        activeScore += pts
        
        gameState?.audioController?.playSFX("whoosh_nearmiss")
    }
    
    private func triggerNearMiss() {
        activeNearMisses += 1
        activeOvertakes += 1 // near misses double up as standard overtakes
        
        // Huge combo multiplier gains
        if comboMultiplier < 10 {
            comboMultiplier = min(10, comboMultiplier + 2)
        }
        comboTimer = 3.0
        
        let pts = 1500 * comboMultiplier
        activeScore += pts
        
        // In Time Trial, near misses refund +2 seconds to the timer!
        if gameState?.selectedMode == .timeTrial {
            timeRemaining += 2.0
            gameState?.audioController?.playSFX("time_bonus")
        }
        
        // Sound whoosh engine click
        gameState?.audioController?.playSFX("whoosh_nearmiss")
    }
    
    // MARK: - Career Rival AI Simulation
    
    private func updateCareerRivalAI(deltaTime: Double) {
        guard let rival = rivalNode else { return }
        
        // Get target stats
        let rivalTopSpeedKPH: Float = 240.0
        let rivalMPS = rivalTopSpeedKPH * 0.2778
        
        // AI simple rubber-banding to keep race competitive!
        // If rival is too far ahead, slow down. If too far behind, catch up!
        let playerZ = playerNode.position.z
        let rivalZ = rival.position.z
        let distanceDelta = playerZ - rivalZ // negative means rival is ahead
        
        var speedMod: Float = 1.0
        if distanceDelta < -80.0 {
            // Rival too far ahead: slow down
            speedMod = 0.75
        } else if distanceDelta > 80.0 {
            // Rival too far behind: hyper-speed catch up!
            speedMod = 1.25
        }
        
        let activeSpeed = rivalMPS * speedMod
        let moveDist = activeSpeed * Float(deltaTime)
        
        // AI drives straight forward
        rival.position.z -= moveDist
        
        // AI periodically changes lanes (X coordinates) randomly to look human
        if elapsedRunTime.truncatingRemainder(dividingBy: 5.0) < 0.05 {
            let targetLaneX = lanePositions.randomElement() ?? -1.75
            let action = SCNAction.moveTo(SCNVector3(targetLaneX, rival.position.y, rival.position.z), duration: 1.2)
            rival.runAction(action)
        }
    }
    
    // MARK: - Collision Physics Contacts Delegate
    
    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard !isCrashed && !isFinished else { return }
        
        // Check if collision involves the Player
        let maskA = contact.nodeA.physicsBody?.categoryBitMask ?? 0
        let maskB = contact.nodeB.physicsBody?.categoryBitMask ?? 0
        
        if maskA == PhysicsCategory.player || maskB == PhysicsCategory.player {
            // Collision! Player Crashed!
            triggerCrashState()
        }
    }
    
    private func triggerCrashState() {
        // Free ride practice mode has no fail state/crashes!
        guard gameState?.selectedMode != .freeRide else { return }
        
        isCrashed = true
        currentSpeedKPH = 0.0
        gameState?.audioController?.stopEngineSound()
        gameState?.audioController?.playSFX("explosion_crash")
        
        // Exploding particle shock geometry
        let particleNode = SCNNode()
        let particles = SCNParticleSystem()
        particles.birthRate = 200
        particles.particleLifeSpan = 0.8
        particles.particleColor = UIColor.orange
        particles.emitterShape = SCNSphere(radius: 0.5)
        particles.particleSize = 0.15
        particles.speedFactor = 1.5
        particleNode.addParticleSystem(particles)
        particleNode.position = playerNode.position
        self.rootNode.addChildNode(particleNode)
        
        // Cinematic Screen Shake action on Camera
        let shakeLeft = SCNAction.moveBy(x: -0.4, y: 0.2, z: 0, duration: 0.05)
        let shakeRight = SCNAction.moveBy(x: 0.4, y: -0.2, z: 0, duration: 0.05)
        let shakeSeq = SCNAction.sequence([shakeLeft, shakeRight, shakeLeft, shakeRight, SCNAction.moveBy(x: 0, y: 0, z: 0, duration: 0.05)])
        cameraNode.runAction(shakeSeq)
        
        // Trigger results transition with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.triggerGameOver(victory: false)
        }
    }
    
    private func simulateCrashTumble(deltaTime: Double) {
        // Car flips slowly in slow motion!
        playerNode.rotation = SCNVector4(0.2, 0.4, 0.8, elapsedRunTime * 1.5)
        playerNode.position.y += 0.8 * Float(deltaTime)
    }
    
    // MARK: - Challenge Missions Objective Checkers
    
    private func checkMissionObjectives(deltaTime: Double) {
        guard let gameState = gameState else { return }
        
        if gameState.selectedMode == .career {
            // Win when crossing 1,500m finish line ahead of AI
            let playerProgress = -playerNode.position.z
            let rivalProgress = rivalNode != nil ? -rivalNode!.position.z : 0.0
            
            if Double(playerProgress) >= finishLineDistance {
                isFinished = true
                let playerWins = playerProgress >= rivalProgress
                triggerGameOver(victory: playerWins)
            }
            return
        }
        
        guard let mission = gameState.activeMission else {
            // Endless survival win checker: Survive as long as possible
            return
        }
        
        switch mission.targetType {
        case .reachFinishLine:
            // Reach target Z distance (e.g. 1500m) before timer runs out
            if totalDistanceMeters >= mission.targetValue {
                triggerGameOver(victory: true)
            }
            
        case .reachSpeedLimit:
            // Hit target KPH speed threshold in time
            if Double(currentSpeedKPH) >= mission.targetValue {
                triggerGameOver(victory: true)
            }
            
        case .performNearMisses:
            // Complete target count of near misses
            if Double(activeNearMisses) >= mission.targetValue {
                triggerGameOver(victory: true)
            }
            
        case .accumulateDistance:
            // Survive and cover X distance in time
            if totalDistanceMeters >= mission.targetValue {
                triggerGameOver(victory: true)
            }
            
        case .holdSpeedDuration:
            // Hold speed above 150 km/h for 15s (Challenge 5)
            if currentSpeedKPH >= 150.0 {
                highSpeedDurationTimer += deltaTime
                if highSpeedDurationTimer >= mission.targetValue {
                    triggerGameOver(victory: true)
                }
            } else {
                // Reset timer if they drop below speed
                highSpeedDurationTimer = 0.0
            }
            
        default:
            break
        }
    }
    
    private func triggerGameOver(victory: Bool) {
        isFinished = true
        gameState?.audioController?.stopEngineSound()
        
        // Notify game view coordinator to display Results View overlay
        // Trigger SwiftUI callback!
        NotificationCenter.default.post(name: NSNotification.Name("GAME_RACE_OVER_NOTIFICATION"), object: nil, userInfo: [
            "victory": victory,
            "score": activeScore,
            "distance": Int(totalDistanceMeters),
            "overtakes": activeOvertakes,
            "nearMisses": activeNearMisses
        ])
    }
}
