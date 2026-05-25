import SwiftUI

// Struct to represent a Mode card in UI
struct GameModeDetails: Identifiable {
    let id: GameMode
    let name: String
    let iconName: String
    let description: String
    let accentColor: Color
    let bgGradient: LinearGradient
}

public struct ModeSelectView: View {
    @ObservedObject var gameState: GameState
    @State private var selectedIndex = 0
    @State private var bounceAnimate = false
    
    // Details catalog for our 6 modes
    private let modeDetails = [
        GameModeDetails(
            id: .endless,
            name: "ENDLESS SURVIVAL",
            iconName: "infinity",
            description: "Drive down an infinite highway, dodge traffic, and see how long you can survive. Difficulty and density scale with distance!",
            accentColor: GameTheme.neonCyan,
            bgGradient: GameTheme.secondaryGradient
        ),
        GameModeDetails(
            id: .challenge,
            name: "CHALLENGE MISSION",
            iconName: "checklist",
            description: "100 discrete technical missions! Beat time limits, hit top speed gates, accumulate close near-miss combos to claim massive cash rewards.",
            accentColor: GameTheme.neonPink,
            bgGradient: GameTheme.primaryGradient
        ),
        GameModeDetails(
            id: .career,
            name: "CAREER CHAMPION",
            iconName: "trophy.fill",
            description: "Go head-to-head against a single aggressive AI rival! Race through 5 locations. Pure position race to cross the finish line first.",
            accentColor: GameTheme.amberGold,
            bgGradient: GameTheme.goldGradient
        ),
        GameModeDetails(
            id: .freeRide,
            name: "FREE PRACTICE RIDE",
            iconName: "sparkles",
            description: "No traffic laws, no crash fail states, and no pressure. Cruise the highways to practice your steering, drift, and high-speed maneuvers.",
            accentColor: GameTheme.successGreen,
            bgGradient: LinearGradient(colors: [GameTheme.successGreen, Color(hex: "#10B981")], startPoint: .topLeading, endPoint: .bottomTrailing)
        ),
        GameModeDetails(
            id: .timeTrial,
            name: "TIME TRIAL COUNTDOWN",
            iconName: "hourglass.badge.plus",
            description: "Fixed distance race against an aggressive countdown timer. Safely execute close near-miss passes to earn time refunds and survive!",
            accentColor: Color.orange,
            bgGradient: LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
        ),
        GameModeDetails(
            id: .chase,
            name: "HIGHWAY CHASE",
            iconName: "shield.rhythm.fill",
            description: "Chase down targets or evade pursuit in this high-intensity game of highway tag! (Unlocked for 99,000 cash or after 10 challenges).",
            accentColor: Color.red,
            bgGradient: LinearGradient(colors: [Color.red, Color(hex: "#9B0000")], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    ]
    
    public init(gameState: GameState) {
        self.gameState = gameState
    }
    
    public var body: some View {
        ZStack {
            GameTheme.bgDark.ignoresSafeArea()
            
            // Background ambient glow circles
            Circle()
                .fill(modeDetails[selectedIndex].accentColor.opacity(0.12))
                .frame(width: 450, height: 450)
                .blur(radius: 90)
                .offset(y: 40)
            
            VStack {
                // TOP NAVIGATION HEADER
                HStack {
                    Button(action: {
                        gameState.audioController?.playSFX("ui_click")
                        withAnimation {
                            gameState.currentScreen = .mainMenu
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("BACK TO MENU")
                        }
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(GameTheme.neonPink)
                    }
                    
                    Spacer()
                    
                    Text("SELECT GAME MODE")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .modifier(GlowModifier(color: modeDetails[selectedIndex].accentColor, radius: 6))
                        .tracking(2)
                    
                    Spacer()
                    
                    // Cash Balance
                    HStack(spacing: 5) {
                        Image(systemName: "circle.circle.fill")
                            .foregroundColor(GameTheme.amberGold)
                        Text("\(gameState.save.cash)")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.4)))
                }
                .padding(.horizontal, 25)
                .padding(.top, 15)
                
                Spacer()
                
                // CENTER CAROUSEL BLOCK
                let mode = modeDetails[selectedIndex]
                let isUnlocked = gameState.isModeUnlocked(mode.id)
                
                HStack(spacing: 30) {
                    // Previous Button Arrow
                    Button(action: {
                        navigateCarousel(forward: false)
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 42))
                            .foregroundColor(selectedIndex > 0 ? mode.accentColor : Color.white.opacity(0.1))
                    }
                    .disabled(selectedIndex == 0)
                    
                    // Large Card Details Panel
                    GlassPanel(cornerRadius: 24, borderColor: mode.accentColor.opacity(0.4)) {
                        HStack(spacing: 20) {
                            // Mode Large Icon Panel
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(mode.bgGradient)
                                    .frame(width: 140, height: 160)
                                    .modifier(GlowModifier(color: mode.accentColor, radius: 8))
                                
                                Image(systemName: mode.iconName)
                                    .font(.system(size: 54))
                                    .foregroundColor(.white)
                                    .scaleEffect(bounceAnimate ? 1.08 : 0.95)
                                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: bounceAnimate)
                            }
                            .padding(.leading, 10)
                            
                            // Info Text Column
                            VStack(alignment: .leading, spacing: 12) {
                                Text(mode.name)
                                    .font(.system(size: 26, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text(mode.description)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineSpacing(4)
                                    .frame(height: 70, alignment: .topLeading)
                                
                                // Selection Buttons / Purchase stubs
                                HStack {
                                    if isUnlocked {
                                        Button(action: {
                                            selectMode(mode.id)
                                        }) {
                                            HStack {
                                                Text("ENTER MODE")
                                                Image(systemName: "chevron.right.circle.fill")
                                            }
                                        }
                                        .buttonStyle(CyberButtonStyle(color: mode.accentColor))
                                    } else {
                                        // Mode locked: Show price purchase
                                        Button(action: {
                                            purchaseMode(mode.id)
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "lock.fill")
                                                Text("UNLOCK FOR \(mode.id.unlockCost) CASH")
                                            }
                                        }
                                        .buttonStyle(CyberButtonStyle(color: GameTheme.amberGold))
                                        .disabled(gameState.save.cash < mode.id.unlockCost)
                                        
                                        Text("OR COMPLETE 10 MISSIONS")
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                            }
                            .padding(.trailing, 10)
                        }
                        .frame(width: 520, height: 180)
                    }
                    
                    // Next Button Arrow
                    Button(action: {
                        navigateCarousel(forward: true)
                    }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 42))
                            .foregroundColor(selectedIndex < modeDetails.count - 1 ? mode.accentColor : Color.white.opacity(0.1))
                    }
                    .disabled(selectedIndex == modeDetails.count - 1)
                }
                
                Spacer()
                
                // Indicators bar
                HStack(spacing: 8) {
                    ForEach(0..<modeDetails.count) { idx in
                        Circle()
                            .fill(idx == selectedIndex ? modeDetails[idx].accentColor : Color.white.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 25)
            }
        }
        .onAppear {
            bounceAnimate = true
            // Match carousel state to selected mode
            if let index = modeDetails.firstIndex(where: { $0.id == gameState.selectedMode }) {
                selectedIndex = index
            }
        }
    }
    
    // MARK: - Actions
    
    private func navigateCarousel(forward: Bool) {
        gameState.audioController?.playSFX("ui_click")
        if forward {
            if selectedIndex < modeDetails.count - 1 {
                selectedIndex += 1
            }
        } else {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
        }
    }
    
    private func selectMode(_ mode: GameMode) {
        gameState.audioController?.playSFX("ui_click")
        gameState.selectedMode = mode
        
        withAnimation {
            // Route to level select pin map for map configurations!
            gameState.currentScreen = .levelSelect
        }
    }
    
    private func purchaseMode(_ mode: GameMode) {
        gameState.audioController?.playSFX("cash_registers")
        let success = gameState.buyMode(mode)
        if success {
            // Force refresh UI state
            let current = selectedIndex
            selectedIndex = current
            
            if gameState.save.isVoiceEnabled {
                gameState.audioController?.speakCoachLine("Outstanding choice! The highway chase pursuit mode is now fully unlocked for you.")
            }
        }
    }
}
