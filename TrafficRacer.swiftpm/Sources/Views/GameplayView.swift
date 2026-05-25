import SwiftUI
import SceneKit
import CoreMotion

// MARK: - GameViewController (Bridges SceneKit SCNView & Keyboard inputs)
class GameViewController: UIViewController, SCNSceneRendererDelegate {
    var gameState: GameState!
    var raceScene: RaceScene!
    var scnView: SCNView!
    var lastUpdateTime: TimeInterval = 0.0
    
    // CoreMotion support
    let motionManager = MotionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Initialize SCNView
        scnView = SCNView(frame: self.view.bounds)
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scnView.backgroundColor = UIColor.clear
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = false
        scnView.showsStatistics = false // set true for diagnostics if needed
        
        // 2. Setup active race scene graph
        raceScene = RaceScene()
        raceScene.setupWorld(gameState: gameState)
        
        scnView.scene = raceScene
        scnView.delegate = self
        scnView.isPlaying = true
        
        self.view.addSubview(scnView)
        
        // 3. Start CoreMotion if tilt mode is selected
        if gameState.save.controlType == "tilt" {
            motionManager.startUpdates()
        }
        
        // 4. Keyboard focus
        self.becomeFirstResponder()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // MARK: - Frame Render Update Callback
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if lastUpdateTime == 0.0 {
            lastUpdateTime = time
            return
        }
        
        let deltaTime = time - lastUpdateTime
        lastUpdateTime = time
        
        // Safety cap deltaTime to avoid large physics jumps during lag
        let cappedDelta = min(0.033, deltaTime)
        
        // Capture tilt inputs if tilt steering is enabled
        if gameState.save.controlType == "tilt" {
            // Apply CoreMotion steer angle
            raceScene.steerInput = Float(motionManager.tiltSteerValue)
        }
        
        // Update 3D simulation frames
        raceScene.updateFrame(deltaTime: cappedDelta)
    }
    
    // MARK: - Simulator Keyboard controls overrides
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            
            switch key.keyCode {
            case .keyboardW, .keyboardUpArrow:
                raceScene.isAccelerating = true
            case .keyboardS, .keyboardDownArrow:
                raceScene.isBraking = true
            case .keyboardA, .keyboardLeftArrow:
                if gameState.save.controlType == "buttons" {
                    raceScene.steerInput = -1.0
                }
            case .keyboardD, .keyboardRightArrow:
                if gameState.save.controlType == "buttons" {
                    raceScene.steerInput = 1.0
                }
            case .keyboardH:
                triggerHorn()
            case .keyboardC:
                raceScene.cycleCamera()
            case .keyboardEscape, .keyboardSpacebar:
                // Post pause trigger
                NotificationCenter.default.post(name: NSNotification.Name("GAME_TOGGLE_PAUSE_NOTIFICATION"), object: nil)
            default:
                super.pressesBegan(presses, with: event)
            }
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            
            switch key.keyCode {
            case .keyboardW, .keyboardUpArrow:
                raceScene.isAccelerating = false
            case .keyboardS, .keyboardDownArrow:
                raceScene.isBraking = false
            case .keyboardA, .keyboardLeftArrow, .keyboardD, .keyboardRightArrow:
                if gameState.save.controlType == "buttons" {
                    raceScene.steerInput = 0.0
                }
            default:
                super.pressesEnded(presses, with: event)
            }
        }
    }
    
    func triggerHorn() {
        gameState.audioController?.playSFX("horn_alert")
    }
    
    func stopAllUpdates() {
        motionManager.stopUpdates()
        scnView.isPlaying = false
        scnView.delegate = nil
    }
    
    deinit {
        stopAllUpdates()
    }
}

// UIViewControllerRepresentable bridging
struct GameViewControllerRepresentable: UIViewControllerRepresentable {
    @ObservedObject var gameState: GameState
    @Binding var controllerRef: GameViewController?
    
    func makeUIViewController(context: Context) -> GameViewController {
        let vc = GameViewController()
        vc.gameState = gameState
        DispatchQueue.main.async {
            self.controllerRef = vc
        }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {
        // Handle changes if needed
    }
}

// MARK: - GameplayView SwiftUI Layout
public struct GameplayView: View {
    @ObservedObject var gameState: GameState
    @State private var vcRef: GameViewController? = nil
    
    // Screen overlays navigation state
    @State private var isPaused = false
    @State private var countdownValue = 3
    @State private var isCountingDown = true
    
    // Results metrics
    @State private var showResults = false
    @State private var resultsVictory = false
    @State private var resultsScore = 0
    @State private var resultsDistance = 0
    @State private var resultsOvertakes = 0
    @State private var resultsNearMisses = 0
    
    // Countdown timer publisher
    private let countdownTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public init(gameState: GameState) {
        self.gameState = gameState
    }
    
    public var body: some View {
        ZStack {
            // SceneKit 3D Render base
            GameViewControllerRepresentable(gameState: gameState, controllerRef: $vcRef)
                .ignoresSafeArea()
            
            // HUD SwiftUI dashboard overlay
            if let vc = vcRef, let scene = vc.raceScene {
                HUDView(
                    gameState: gameState,
                    raceScene: scene,
                    onPause: {
                        togglePause()
                    },
                    onSteer: { steerVal in
                        scene.steerInput = steerVal
                    },
                    onAccelerate: { accVal in
                        scene.isAccelerating = accVal
                    },
                    onBrake: { brakeVal in
                        scene.isBraking = brakeVal
                    },
                    onCameraToggle: {
                        scene.cycleCamera()
                    },
                    onHorn: {
                        vc.triggerHorn()
                    }
                )
                .disabled(isCountingDown || isPaused || showResults)
            }
            
            // Start Countdown Overlay (3 · 2 · 1 · GO!)
            if isCountingDown {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    
                    Text(countdownValue == 0 ? "GO!" : "\(countdownValue)")
                        .font(.system(size: 96, weight: .black, design: .rounded))
                        .foregroundColor(countdownValue == 0 ? GameTheme.successGreen : GameTheme.neonPink)
                        .modifier(GlowModifier(color: countdownValue == 0 ? GameTheme.successGreen : GameTheme.neonPink, radius: 15))
                        .scaleEffect(countdownValue == 0 ? 1.2 : 1.0)
                        .transition(.scale)
                }
            }
            
            // Pause Overlay View
            if isPaused {
                PauseView(
                    gameState: gameState,
                    onResume: {
                        togglePause()
                    },
                    onRestart: {
                        restartGame()
                    },
                    onCameraToggle: {
                        vcRef?.raceScene.cycleCamera()
                    },
                    onQuit: {
                        exitGame()
                    }
                )
            }
            
            // Results Recap Overlay View
            if showResults {
                ResultsView(
                    gameState: gameState,
                    victory: resultsVictory,
                    score: resultsScore,
                    distance: resultsDistance,
                    overtakes: resultsOvertakes,
                    nearMisses: resultsNearMisses,
                    onRetry: {
                        restartGame()
                    },
                    onQuit: {
                        exitGame()
                    }
                )
            }
        }
        .onAppear {
            setupNotificationObservers()
        }
        .onDisappear {
            removeNotificationObservers()
            vcRef?.stopAllUpdates()
        }
        .onReceive(countdownTimer) { _ in
            guard isCountingDown else { return }
            
            if countdownValue > 1 {
                gameState.audioController?.playSFX("gear_click")
                countdownValue -= 1
            } else if countdownValue == 1 {
                // Ticks down to 0 ("GO!")
                gameState.audioController?.playSFX("race_start_chirp")
                countdownValue = 0
            } else {
                // Done counting! Boot actual updates
                isCountingDown = false
                countdownTimer.upstream.connect().cancel()
                
                // Set initial speed threshold to trigger updates
                vcRef?.scnView.isPlaying = true
            }
        }
    }
    
    // MARK: - Game Control Toggles
    
    private func togglePause() {
        isPaused.toggle()
        
        if let scn = vcRef?.scnView {
            scn.isPlaying = !isPaused
            
            if isPaused {
                gameState.audioController?.stopEngineSound()
            } else {
                gameState.audioController?.startEngineSound()
            }
        }
    }
    
    private func restartGame() {
        vcRef?.stopAllUpdates()
        vcRef = nil
        
        isPaused = false
        showResults = false
        countdownValue = 3
        isCountingDown = true
        
        gameState.audioController?.startEngineSound()
    }
    
    private func exitGame() {
        vcRef?.stopAllUpdates()
        vcRef = nil
        
        gameState.audioController?.stopEngineSound()
        gameState.audioController?.playMusic()
        
        withAnimation {
            gameState.currentScreen = .mainMenu
        }
    }
    
    // MARK: - NSNotification Bridges
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("GAME_RACE_OVER_NOTIFICATION"), object: nil, queue: .main) { [self] notification in
            guard let userInfo = notification.userInfo else { return }
            
            resultsVictory = userInfo["victory"] as? Bool ?? false
            resultsScore = userInfo["score"] as? Int ?? 0
            resultsDistance = userInfo["distance"] as? Int ?? 0
            resultsOvertakes = userInfo["overtakes"] as? Int ?? 0
            resultsNearMisses = userInfo["nearMisses"] as? Int ?? 0
            
            withAnimation(.spring()) {
                showResults = true
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("GAME_TOGGLE_PAUSE_NOTIFICATION"), object: nil, queue: .main) { _ in
            togglePause()
        }
    }
    
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("GAME_RACE_OVER_NOTIFICATION"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("GAME_TOGGLE_PAUSE_NOTIFICATION"), object: nil)
    }
}
