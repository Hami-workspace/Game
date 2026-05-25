import SwiftUI

public struct ResultsView: View {
    @ObservedObject var gameState: GameState
    
    // Stats passed from active scene
    let victory: Bool
    let score: Int
    let distance: Int
    let overtakes: Int
    let nearMisses: Int
    
    // Action triggers
    var onRetry: () -> Void
    var onQuit: () -> Void
    
    // Rewards calculated
    @State private var cashEarned: Int = 0
    @State private var expEarned: Int = 0
    @State private var doubleClaimed = false
    @State private var coinAnimate = false
    @State private var isNewHighScore = false
    
    public init(gameState: GameState, victory: Bool, score: Int, distance: Int, overtakes: Int, nearMisses: Int, onRetry: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.gameState = gameState
        self.victory = victory
        self.score = score
        self.distance = distance
        self.overtakes = overtakes
        self.nearMisses = nearMisses
        self.onRetry = onRetry
        self.onQuit = onQuit
    }
    
    public var body: some View {
        ZStack {
            // Darkened backdrop overlay
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header Status
                VStack(spacing: 4) {
                    if victory {
                        Text("VICTORY STAGE!")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(GameTheme.successGreen)
                            .modifier(GlowModifier(color: GameTheme.successGreen, radius: 10))
                    } else {
                        Text("CAR CRASHED!")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(GameTheme.neonPink)
                            .modifier(GlowModifier(color: GameTheme.neonPink, radius: 10))
                    }
                    
                    Text("\(gameState.activeLocation.name) • \(gameState.selectedMode.displayName.uppercased())")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(GameTheme.neonCyan)
                        .tracking(2)
                }
                
                // New Highscore alert
                if isNewHighScore {
                    Text("NEW PERSONAL HIGH SCORE!")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(GameTheme.successGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(GameTheme.successGreen.opacity(0.15)))
                        .overlay(Capsule().stroke(GameTheme.successGreen, lineWidth: 1))
                        .modifier(GlowModifier(color: GameTheme.successGreen, radius: 4))
                }
                
                HStack(spacing: 20) {
                    // Left Column: Driving Stats Summary
                    GlassPanel(cornerRadius: 18, borderColor: Color.white.opacity(0.1)) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("DRIVING PERFORMANCE")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(GameTheme.neonCyan)
                                .tracking(1)
                            
                            statRecapRow(label: "FINAL SCORE:", value: "\(score) pts")
                            statRecapRow(label: "DISTANCE COVERED:", value: "\(distance) m")
                            statRecapRow(label: "VEHICLES OVERTAKEN:", value: "\(overtakes)")
                            statRecapRow(label: "CLOSE NEAR-MISSES:", value: "\(nearMisses)")
                        }
                        .frame(width: 250, height: 160)
                    }
                    
                    // Right Column: Profile rewards earned
                    GlassPanel(cornerRadius: 18, borderColor: GameTheme.amberGold.opacity(0.3)) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("REWARDS EARNED")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(GameTheme.amberGold)
                                .tracking(1)
                            
                            // Cash Payout
                            HStack(spacing: 10) {
                                Image(systemName: "circle.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(GameTheme.amberGold)
                                    .scaleEffect(coinAnimate ? 1.2 : 1.0)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("CASH PAYOUT")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("+\(cashEarned)")
                                        .font(.system(size: 20, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // EXP Payout
                            HStack(spacing: 10) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(GameTheme.neonPink)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("EXP DRIFT VALUE")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("+\(expEarned)")
                                        .font(.system(size: 20, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(width: 200, height: 160)
                    }
                }
                
                // Double rewards ad stub button
                if !doubleClaimed {
                    Button(action: {
                        triggerDoubleRewards()
                    }) {
                        HStack {
                            Image(systemName: "play.tv.fill")
                            Text("WATCH SPONSOR AD TO DOUBLE REWARDS!")
                        }
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).stroke(GameTheme.neonCyan, lineWidth: 2))
                        .foregroundColor(GameTheme.neonCyan)
                        .modifier(GlowModifier(color: GameTheme.neonCyan, radius: 4))
                    }
                    .padding(.top, 10)
                } else {
                    Text("REWARDS DOUBLED +\(cashEarned) CASH!")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(GameTheme.successGreen)
                        .modifier(GlowModifier(color: GameTheme.successGreen, radius: 4))
                        .padding(.top, 10)
                }
                
                // BOTTOM ACTION ROUTING STRIP
                HStack(spacing: 15) {
                    Button("RETRY RACE") {
                        gameState.audioController?.playSFX("race_start_chirp")
                        onRetry()
                    }
                    .buttonStyle(CyberButtonStyle(color: GameTheme.neonPink))
                    
                    // Next Level (Only show if victory in Challenge mode!)
                    if gameState.selectedMode == .challenge && victory {
                        Button("NEXT CHALLENGE") {
                            advanceChallenge()
                        }
                        .buttonStyle(CyberButtonStyle(color: GameTheme.successGreen))
                    }
                    
                    Button("GARAGE") {
                        gameState.audioController?.playSFX("ui_click")
                        withAnimation {
                            gameState.currentScreen = .garage
                        }
                    }
                    .buttonStyle(CyberButtonStyle(color: GameTheme.neonCyan))
                    
                    Button("MAIN MENU") {
                        gameState.audioController?.playSFX("ui_click")
                        onQuit()
                    }
                    .buttonStyle(CyberButtonStyle(color: Color.gray))
                }
                .padding(.top, 15)
            }
            .padding()
        }
        .onAppear {
            calculateRewards()
        }
    }
    
    private func statRecapRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Cash & EXP Calculations
    
    private func calculateRewards() {
        // Base rewards are derived from score + distance
        let baseCash = (score / 10) + (distance / 5) + (nearMisses * 200)
        let baseExp = (distance / 2) + (nearMisses * 350)
        
        cashEarned = max(100, baseCash)
        expEarned = max(200, baseExp)
        
        // Write scores/rewards into GameState persistence
        if gameState.selectedMode == .endless {
            isNewHighScore = gameState.updateEndlessScore(score)
            // Add Endless standard rewards
            gameState.addRewards(cashReward: cashEarned, expReward: expEarned)
        } else if gameState.selectedMode == .challenge {
            if victory, let mission = gameState.activeMission {
                gameState.completeMission(id: mission.id, score: score)
            }
            // Add baseline challenge participation reward
            gameState.addRewards(cashReward: cashEarned, expReward: expEarned)
        } else {
            // Free ride has no rewards, career has position rewards
            if gameState.selectedMode == .career {
                // Large bonus for winning position
                let careerCash = victory ? 12000 : 2000
                let careerExp = victory ? 8000 : 1000
                cashEarned = careerCash
                expEarned = careerExp
                gameState.addRewards(cashReward: cashEarned, expReward: expEarned)
            } else {
                // Free ride stubs
                cashEarned = 0
                expEarned = 0
            }
        }
        
        // Coach announcer encourages
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if gameState.save.isVoiceEnabled {
                if victory {
                    gameState.audioController?.speakCoachLine("Outstanding performance! You completed the racing objective cleanly. Take your cash rewards!")
                } else {
                    gameState.audioController?.speakCoachLine("A minor fender bender. No worries! Pick yourself up, tune the machine in the garage, and let's go again.")
                }
            }
        }
    }
    
    private func triggerDoubleRewards() {
        gameState.audioController?.playSFX("cash_registers")
        
        // Double rewards locally in gamestate
        gameState.claimAdDoubleRewards(baseCash: cashEarned, baseExp: expEarned)
        
        // Animate UI counters
        doubleClaimed = true
        cashEarned *= 2
        expEarned *= 2
        
        coinAnimate = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            coinAnimate = false
        }
        
        if gameState.save.isVoiceEnabled {
            gameState.audioController?.speakCoachLine("Double payout awarded! Your sponsorship credits have been loaded into your account.")
        }
    }
    
    private func advanceChallenge() {
        gameState.audioController?.playSFX("ui_click")
        
        // Look for next mission index
        if let mission = gameState.activeMission,
           let index = gameState.missions.firstIndex(where: { $0.id == mission.id }),
           index < gameState.missions.count - 1 {
            let nextMission = gameState.missions[index + 1]
            gameState.activeMissionId = nextMission.id
            onRetry() // Starts race with next mission!
        } else {
            onQuit()
        }
    }
}
