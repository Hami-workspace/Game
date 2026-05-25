import SwiftUI

public struct LevelSelectView: View {
    @ObservedObject var gameState: GameState
    @State private var selectedLocIndex = 0
    @State private var activeChallengeIndex = 0
    
    // Custom coordinates for stylized aesthetic map pins in Landscape:
    // ranges from 0-100% on width/height
    private let pinCoordinates = [
        (x: 20, y: 40), // Farmland
        (x: 45, y: 30), // City
        (x: 60, y: 65), // Mountain Day
        (x: 72, y: 35), // Mountain Night
        (x: 88, y: 55)  // Snow
    ]
    
    public init(gameState: GameState) {
        self.gameState = gameState
    }
    
    public var body: some View {
        ZStack {
            GameTheme.bgDark.ignoresSafeArea()
            
            // MAP GRAPHICAL BASE LAYER
            ZStack {
                // Cyber stylized grid/continents lines representer
                VStack(spacing: 40) {
                    ForEach(0..<6) { _ in
                        HStack(spacing: 50) {
                            ForEach(0..<8) { _ in
                                Circle()
                                    .fill(GameTheme.neonCyan.opacity(0.04))
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }
                
                // Drawing stylized map routes
                Path { path in
                    path.move(to: CGPoint(x: 100, y: 150))
                    path.addLine(to: CGPoint(x: 250, y: 100))
                    path.addLine(to: CGPoint(x: 350, y: 220))
                    path.addLine(to: CGPoint(x: 450, y: 120))
                    path.addLine(to: CGPoint(x: 550, y: 180))
                }
                .stroke(GameTheme.neonCyan.opacity(0.1), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [5, 5]))
            }
            .ignoresSafeArea()
            
            // Interactive Map Pins Overlay
            GeometryReader { geo in
                ForEach(0..<gameState.locations.count) { idx in
                    let loc = gameState.locations[idx]
                    let isUnlocked = gameState.currentLevel >= loc.unlockRequiredLevel
                    let coord = pinCoordinates[idx]
                    let isSelected = selectedLocIndex == idx
                    
                    let posX = CGFloat(coord.x) / 100.0 * geo.size.width
                    let posY = CGFloat(coord.y) / 100.0 * geo.size.height
                    
                    // Pin Button
                    Button(action: {
                        if isUnlocked {
                            gameState.audioController?.playSFX("ui_click")
                            selectedLocIndex = idx
                            gameState.selectedLocationId = loc.id
                        } else {
                            gameState.audioController?.playSFX("buzzer")
                            if gameState.save.isVoiceEnabled {
                                gameState.audioController?.speakCoachLine("Racer, you must expand your driver ranking to level \(loc.unlockRequiredLevel) to navigate this dangerous territory!")
                            }
                        }
                    }) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? GameTheme.neonPink : (isUnlocked ? GameTheme.neonCyan : Color.gray))
                                    .frame(width: isSelected ? 32 : 24, height: isSelected ? 32 : 24)
                                    .modifier(GlowModifier(color: isSelected ? GameTheme.neonPink : (isUnlocked ? GameTheme.neonCyan : .clear), radius: isSelected ? 8 : 4))
                                
                                if !isUnlocked {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Text(loc.name)
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(4)
                        }
                    }
                    .position(x: posX, y: posY)
                }
            }
            
            // SIDE DETAIL INTERFACE PANELS
            HStack(alignment: .top) {
                // Left: Navigation & Location specs
                VStack(alignment: .leading, spacing: 14) {
                    // Header back
                    Button(action: {
                        gameState.audioController?.playSFX("ui_click")
                        withAnimation {
                            gameState.currentScreen = .modeSelect
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("BACK TO MODES")
                        }
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(GameTheme.neonPink)
                    }
                    .padding(.top, 10)
                    
                    let loc = gameState.locations[selectedLocIndex]
                    
                    // Location Card
                    GlassPanel(cornerRadius: 16, borderColor: GameTheme.neonCyan.opacity(0.3)) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("LOCATION")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(GameTheme.neonCyan)
                                .tracking(1)
                            
                            Text(loc.name.uppercased())
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .modifier(GlowModifier(color: GameTheme.neonCyan, radius: 4))
                            
                            // Specifications list
                            VStack(alignment: .leading, spacing: 6) {
                                specItem(icon: "arrow.up.and.down.circle.fill", label: "ROAD TYPE:", value: loc.isTwoWay ? "Two Way Traffic" : "One Way Traffic")
                                specItem(icon: "sun.max.fill", label: "TIME DIAL:", value: loc.isNight ? "Night Runs" : "Daytime Cruise")
                                specItem(icon: "gauge.with.needle.fill", label: "ROAD TIRE GRIP:", value: loc.frictionMultiplier < 1.0 ? "Low Grip (Drift!)" : "Standard High Friction")
                                
                                // Dynamic score display
                                let highscore = gameState.selectedMode == .endless ? gameState.save.endlessHighScore : 0
                                specItem(icon: "trophy.fill", label: "RECORD SCORE:", value: highscore > 0 ? "\(highscore) pts" : "Yet to play!")
                            }
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                        }
                        .frame(width: 250)
                    }
                    
                    // Garage shortcut button
                    Button(action: {
                        gameState.audioController?.playSFX("ui_click")
                        withAnimation {
                            gameState.currentScreen = .garage
                        }
                    }) {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver.fill")
                            Text("GARAGE SHORTCUT")
                        }
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(GameTheme.neonPink, lineWidth: 1.5))
                    }
                }
                .padding(.leading, 25)
                
                Spacer()
                
                // Right: Play button & Challenges sub-selector (if challenge mode is equipped)
                VStack(alignment: .trailing, spacing: 14) {
                    // Header Map Mode Status Info
                    Text("ACTIVE: \(gameState.selectedMode.displayName.uppercased())")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(GameTheme.amberGold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.black.opacity(0.4)))
                        .padding(.top, 10)
                    
                    if gameState.selectedMode == .challenge {
                        // Display 5 playable challenge missions
                        GlassPanel(cornerRadius: 16, borderColor: GameTheme.neonPink.opacity(0.3)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("MISSIONS CHECKLIST")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(GameTheme.neonPink)
                                    .tracking(1)
                                
                                ScrollView {
                                    VStack(spacing: 6) {
                                        ForEach(0..<gameState.missions.count) { idx in
                                            let mission = gameState.missions[idx]
                                            let isSelected = activeChallengeIndex == idx
                                            
                                            HStack {
                                                Image(systemName: mission.isCompleted ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(mission.isCompleted ? GameTheme.successGreen : .white.opacity(0.3))
                                                
                                                Text("CHALLENGE \(mission.challengeNumber)")
                                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                                    .foregroundColor(isSelected ? GameTheme.neonCyan : .white)
                                                
                                                Spacer()
                                                
                                                Text("+\(mission.cashReward)")
                                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                                    .foregroundColor(GameTheme.amberGold)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(isSelected ? GameTheme.neonPink.opacity(0.2) : Color.white.opacity(0.05))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(isSelected ? GameTheme.neonPink : Color.clear, lineWidth: 1.5)
                                            )
                                            .onTapGesture {
                                                gameState.audioController?.playSFX("ui_click")
                                                activeChallengeIndex = idx
                                                gameState.activeMissionId = mission.id
                                            }
                                        }
                                    }
                                }
                                .frame(height: 120)
                            }
                            .frame(width: 250)
                        }
                    }
                    
                    // Selected active objectives display card (for Challenge mode)
                    if gameState.selectedMode == .challenge {
                        let mission = gameState.missions[activeChallengeIndex]
                        GlassPanel(cornerRadius: 12, borderColor: GameTheme.amberGold.opacity(0.2)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("OBJECTIVE:")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(GameTheme.amberGold)
                                Text(mission.objectiveText)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                            }
                            .frame(width: 230, alignment: .leading)
                        }
                    }
                    
                    Spacer()
                    
                    // START THE ENGINE / PLAY ACTION
                    Button(action: {
                        startRace()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "bolt.fill")
                            Text("START THE ENGINE")
                        }
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(GameTheme.primaryGradient)
                        )
                        .modifier(GlowModifier(color: GameTheme.neonPink, radius: 8))
                    }
                    .padding(.bottom, 20)
                }
                .padding(.trailing, 25)
            }
        }
        .onAppear {
            // Set defaults when opening
            gameState.selectedLocationId = gameState.locations[selectedLocIndex].id
            if gameState.selectedMode == .challenge {
                gameState.activeMissionId = gameState.missions[activeChallengeIndex].id
            } else {
                gameState.activeMissionId = nil
            }
        }
    }
    
    // MARK: - Row Specs Helper
    
    private func specItem(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(GameTheme.neonPink)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Start Race Initializer
    
    private func startRace() {
        // Enforce challenge selection syncing
        if gameState.selectedMode == .challenge {
            gameState.activeMissionId = gameState.missions[activeChallengeIndex].id
        } else {
            gameState.activeMissionId = nil
        }
        
        gameState.audioController?.stopMusic()
        gameState.audioController?.playSFX("race_start_chirp")
        gameState.audioController?.startEngineSound()
        
        // Routely swap screen to Gameplay!
        withAnimation {
            gameState.currentScreen = .gameplay
        }
    }
}
