import SwiftUI
import SceneKit

// MARK: - Bridged 3D Turntable SCNView
struct TurntableSCNView: UIViewRepresentable {
    @ObservedObject var gameState: GameState
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor.clear
        scnView.allowsCameraControl = false // Keep it static & cinematic
        scnView.autoenablesDefaultLighting = false
        
        // 1. Build Scene
        let scene = SCNScene()
        
        // 2. Add Ambient & Directional Lights
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(hex: "#1A1A2F")
        ambientLight.intensity = 600
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // Directional Sun Light (Highlighting car edges)
        let sunLight = SCNLight()
        sunLight.type = .directional
        sunLight.color = UIColor.white
        sunLight.intensity = 1500
        let sunNode = SCNNode()
        sunNode.light = sunLight
        sunNode.position = SCNVector3(5, 10, 5)
        sunNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(sunNode)
        
        // Soft neon top spot
        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.color = UIColor(hex: gameState.currentCar.lightColorHex)
        spotLight.intensity = 1000
        spotLight.spotOuterAngle = 80
        let spotNode = SCNNode()
        spotNode.light = spotLight
        spotNode.position = SCNVector3(0, 5, 0)
        spotNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(spotNode)
        
        // 3. Add Turntable Platform (Metallic base disk)
        let platformGeo = SCNCylinder(radius: 2.8, height: 0.1)
        let platformMat = SCNMaterial()
        platformMat.diffuse.contents = UIColor(white: 0.12, alpha: 1.0)
        platformMat.roughness.contents = 0.4
        platformMat.metalness.contents = 0.9
        platformGeo.materials = [platformMat]
        let platformNode = SCNNode(geometry: platformGeo)
        platformNode.position = SCNVector3(0, -0.05, 0)
        scene.rootNode.addChildNode(platformNode)
        
        // 4. Generate and place Player Car
        let carNode = VehicleNodeFactory.createPlayerVehicle(car: gameState.currentCar)
        carNode.name = "turntable_car"
        scene.rootNode.addChildNode(carNode)
        
        // Let it rotate slowly
        let rotationAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 12.0))
        carNode.runAction(rotationAction)
        
        // 5. Add Cinematic Camera Rig
        let camera = SCNCamera()
        camera.zNear = 0.1
        camera.zFar = 100
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 2.2, -5.5) // cinematic third person angle
        cameraNode.look(at: SCNVector3(0, 0.4, 0))
        scene.rootNode.addChildNode(cameraNode)
        
        scnView.scene = scene
        context.coordinator.scnView = scnView
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Redraw player car node when customizations update
        guard let scene = uiView.scene else { return }
        
        // Remove existing car
        scene.rootNode.childNode(withName: "turntable_car", recursively: true)?.removeFromParentNode()
        
        // Re-inject updated car
        let carNode = VehicleNodeFactory.createPlayerVehicle(car: gameState.currentCar)
        carNode.name = "turntable_car"
        scene.rootNode.addChildNode(carNode)
        
        // Resume rotation
        let rotationAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 12.0))
        carNode.runAction(rotationAction)
        
        // Update spot light color
        if let spotNode = scene.rootNode.childNodes.first(where: { $0.light?.type == .spot }) {
            spotNode.light?.color = UIColor(hex: gameState.currentCar.lightColorHex)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var scnView: SCNView?
    }
}

// MARK: - MainMenuView Implementation
public struct MainMenuView: View {
    @ObservedObject var gameState: GameState
    @State private var claimPop = false
    @State private var coinAnimation = false
    
    public init(gameState: GameState) {
        self.gameState = gameState
    }
    
    public var body: some View {
        ZStack {
            GameTheme.bgDark.ignoresSafeArea()
            
            // 3D Turntable Preview spanning back panel
            TurntableSCNView(gameState: gameState)
                .ignoresSafeArea()
            
            // Neon top-down vignetting overlay
            VStack {
                Rectangle()
                    .fill(LinearGradient(colors: [GameTheme.bgDark.opacity(0.85), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(height: 120)
                Spacer()
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, GameTheme.bgDark.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 140)
            }
            .ignoresSafeArea()
            
            VStack {
                // TOP HEADER BAR (Avatar, Coins, Level Info, Settings)
                HStack(spacing: 15) {
                    // Profile Avatar & Level
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill.badge.checkmark")
                            .resizable()
                            .frame(width: 42, height: 42)
                            .foregroundColor(GameTheme.neonCyan)
                            .modifier(GlowModifier(color: GameTheme.neonCyan, radius: 4))
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("RACER \(gameState.currentCar.plateText)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            
                            // EXP Level Indicator
                            HStack(spacing: 5) {
                                Text("Lvl \(gameState.currentLevel)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(GameTheme.neonPink)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(GameTheme.neonPink.opacity(0.2))
                                    .cornerRadius(4)
                                
                                // Micro EXP slider progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.15))
                                        Capsule()
                                            .fill(GameTheme.neonPink)
                                            .frame(width: CGFloat(gameState.expProgressFraction) * geo.size.width)
                                    }
                                }
                                .frame(width: 70, height: 5)
                            }
                        }
                    }
                    .padding(.leading, 15)
                    
                    Spacer()
                    
                    // Cash Wallet (with Amber-Gold Coins)
                    HStack(spacing: 8) {
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(GameTheme.amberGold)
                            .scaleEffect(coinAnimation ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: coinAnimation)
                        
                        Text("\(gameState.save.cash)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .modifier(GlowModifier(color: GameTheme.amberGold, radius: 4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.5)).overlay(Capsule().stroke(GameTheme.amberGold.opacity(0.4), lineWidth: 1.5)))
                    
                    // Settings Gear Button
                    Button(action: {
                        gameState.audioController?.playSFX("ui_click")
                        withAnimation {
                            gameState.currentScreen = .welcome // Shortcut for settings or let's navigate to settings!
                            // Wait, settings view is reached by swapping screen to a settings case!
                            // In our GameState.currentScreen: .welcome or we can route directly to SettingsView.
                            // Let's route directly to a settings screen in active container.
                            // In GameState, we have: `.launch`, `.welcome`, `.mainMenu`, `.modeSelect`, `.levelSelect`, `.garage`, `.gameplay`.
                            // To open Settings, let's represent Settings as a modal sheet or sheet view, or replace a screen route!
                            // Let's replace the route with a temporary active screen or welcome!
                            // Wait, even better, we can define a sheets view or let's create a dedicated settings case in ActiveScreen:
                            // Let's check what ActiveScreen has:
                            // public enum ActiveScreen { case launch, welcome, mainMenu, modeSelect, levelSelect, garage, gameplay }
                            // Wait, let's treat Settings as a modal sheet presented right on top of MainMenuView!
                            // That is incredibly elegant, clean, and avoids modifying GameState's enum unnecessarily!
                            // Yes, let's use a @State variable `showSettingsModal = true`!
                            // This is wonderful and extremely easy to manage.
                            showSettingsSheet()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        }
                        .padding(.trailing, 15)
                }
                .frame(height: 70)
                .background(Color.black.opacity(0.3))
                
                Spacer()
                
                // CENTER CAR DISPLAY NAME
                VStack(spacing: 4) {
                    Text("ACTIVE MACHINE")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(GameTheme.neonCyan)
                        .tracking(2)
                    
                    Text(gameState.currentCar.name.uppercased())
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .modifier(GlowModifier(color: UIColor(hex: gameState.currentCar.paintColorHex).toColor(), radius: 8))
                    
                    Text("Top Speed: \(gameState.currentCar.maxSpeedKPH) KPH")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 20)
                
                // BOTTOM ACTION HUB BAR
                HStack(spacing: 20) {
                    // Watch Ads Stub button
                    Button(action: {
                        triggerWatchAd()
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: "play.tv.fill")
                                .font(.system(size: 20))
                            Text("FREE +500")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                        }
                        .frame(width: 80, height: 60)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.6)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GameTheme.neonCyan.opacity(0.5), lineWidth: 1.5))
                        .foregroundColor(GameTheme.neonCyan)
                    }
                    
                    // Garage Button
                    Button(action: {
                        gameState.audioController?.playSFX("ui_click")
                        withAnimation {
                            gameState.currentScreen = .garage
                        }
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 20))
                            Text("GARAGE")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                        }
                        .frame(width: 80, height: 60)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.6)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GameTheme.neonPink.opacity(0.5), lineWidth: 1.5))
                        .foregroundColor(GameTheme.neonPink)
                    }
                    
                    // Primary PLAY / Tap car button
                    Button(action: {
                        gameState.audioController?.playSFX("race_start_chirp")
                        withAnimation(.spring()) {
                            gameState.currentScreen = .modeSelect
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text("DRIVE")
                            Image(systemName: "chevron.right.circle.fill")
                        }
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(
                            Capsule().fill(GameTheme.primaryGradient)
                        )
                        .modifier(GlowModifier(color: GameTheme.neonPink, radius: 10))
                    }
                    
                    // Daily Reward Button
                    Button(action: {
                        gameState.audioController?.playSFX("ui_click")
                        withAnimation {
                            gameState.currentScreen = .welcome
                        }
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 20))
                            Text("STREAK")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                        }
                        .frame(width: 80, height: 60)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.6)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GameTheme.amberGold.opacity(0.5), lineWidth: 1.5))
                        .foregroundColor(GameTheme.amberGold)
                    }
                }
                .padding(.bottom, 25)
            }
        }
        .onAppear {
            gameState.audioController?.playMusic()
        }
        .sheet(isPresented: $claimPop) {
            SettingsView(gameState: gameState) // Presents Settings View as a sheet
        }
    }
    
    private func showSettingsSheet() {
        claimPop = true
    }
    
    private func triggerWatchAd() {
        gameState.audioController?.playSFX("cash_registers")
        
        // Trigger stub rewards
        gameState.watchAdForCash()
        
        // Animate coins indicator
        coinAnimation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            coinAnimation = false
        }
        
        // Coach announcer voices congratulations
        if gameState.save.isVoiceEnabled {
            gameState.audioController?.speakCoachLine("Sweet! You just watched an advertisement sponsor and earned five hundred bonus cash!")
        }
    }
}

// Convert UIColor to SwiftUI Color utility helper
extension UIColor {
    public func toColor() -> Color {
        return Color(self)
    }
}
