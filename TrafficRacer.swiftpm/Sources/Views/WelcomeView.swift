import SwiftUI

public struct WelcomeView: View {
    @ObservedObject var gameState: GameState
    @State private var animateCoach = false
    @State private var claimStatusText: String = ""
    @State private var rewardClaimed = false
    @State private var claimAmount = 0
    
    // Streaks mapping
    private let rewardAmounts = [500, 1000, 1500, 2000, 2800, 3800, 5000]
    
    public init(gameState: GameState) {
        self.gameState = gameState
    }
    
    public var body: some View {
        ZStack {
            GameTheme.bgDark.ignoresSafeArea()
            
            // Neon accent glows
            Circle()
                .fill(GameTheme.neonPink.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -250, y: -100)
            
            Circle()
                .fill(GameTheme.neonCyan.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: 250, y: 100)
            
            HStack(spacing: 30) {
                // Coach Announcer Figure
                VStack(spacing: 15) {
                    // Geometric low-poly avatar representer of Coach
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(LinearGradient(colors: [GameTheme.neonPink.opacity(0.4), GameTheme.bgPanel], startPoint: .top, endPoint: .bottom))
                            .frame(width: 180, height: 220)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(GameTheme.neonPink, lineWidth: 2)
                            )
                        
                        VStack(spacing: 10) {
                            // Avatar Icon or shape
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(GameTheme.neonCyan)
                                .scaleEffect(animateCoach ? 1.05 : 0.95)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateCoach)
                            
                            Text("COACH")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(2)
                            
                            Text("RACING PRO")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(GameTheme.neonCyan)
                        }
                    }
                    .scaleEffect(animateCoach ? 1.02 : 0.98)
                    .offset(y: animateCoach ? -5 : 5)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateCoach)
                }
                .padding(.leading, 30)
                
                // Welcome and Daily Calendar Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("DAILY RACING BONUS")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .modifier(GlowModifier(color: GameTheme.neonPink, radius: 8))
                    
                    // Coach Bubble Message
                    GlassPanel(cornerRadius: 12, borderColor: GameTheme.neonCyan.opacity(0.4)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hey Racer! Ready to tear up the asphalt today? Claim your daily stipend and let's build your dream machine in the garage!")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: 480)
                    }
                    
                    // Streak calendar
                    HStack(spacing: 10) {
                        ForEach(0..<7) { dayIndex in
                            let amount = rewardAmounts[dayIndex]
                            let dayStreak = gameState.save.dailyRewardStreak
                            let isPast = dayIndex < dayStreak
                            let isCurrent = dayIndex == dayStreak && gameState.isDailyRewardAvailable()
                            
                            VStack(spacing: 8) {
                                Text("DAY \(dayIndex + 1)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(isCurrent ? GameTheme.neonCyan : (isPast ? .white.opacity(0.4) : .white.opacity(0.6)))
                                
                                Image(systemName: isPast ? "checkmark.circle.fill" : "gift.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(isPast ? GameTheme.successGreen : (isCurrent ? GameTheme.neonPink : .white.opacity(0.3)))
                                
                                Text("+\(amount)")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundColor(isCurrent ? GameTheme.amberGold : .white.opacity(0.8))
                            }
                            .frame(width: 65, height: 90)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isCurrent ? GameTheme.neonCyan.opacity(0.15) : GameTheme.bgPanel.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isCurrent ? GameTheme.neonCyan : Color.white.opacity(0.1), lineWidth: 1.5)
                            )
                        }
                    }
                    
                    // Claim Button Actions
                    HStack(spacing: 15) {
                        if !rewardClaimed {
                            Button("CLAIM DAILY REWARD") {
                                claimReward()
                            }
                            .buttonStyle(CyberButtonStyle(color: GameTheme.neonPink))
                        } else {
                            Button("ENTER HUB") {
                                withAnimation {
                                    gameState.currentScreen = .mainMenu
                                }
                            }
                            .buttonStyle(CyberButtonStyle(color: GameTheme.neonCyan))
                            
                            Text(claimStatusText)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(GameTheme.successGreen)
                                .modifier(GlowModifier(color: GameTheme.successGreen, radius: 4))
                                .transition(.opacity)
                        }
                    }
                }
                .padding(.trailing, 30)
            }
        }
        .onAppear {
            animateCoach = true
            // Play a gentle welcome chime or speak Coach's lines when shown
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if gameState.save.isVoiceEnabled {
                    gameState.audioController?.speakCoachLine("Hey Racer! Ready to tear up the asphalt today? Claim your daily stipend and let's get rolling!")
                }
            }
        }
    }
    
    private func claimReward() {
        let amount = gameState.claimDailyReward()
        if amount > 0 {
            claimAmount = amount
            rewardClaimed = true
            claimStatusText = "CLAIMED +\(amount) CASH STREAK!"
            
            // Audio sound effect feedback
            gameState.audioController?.playSFX("claim_reward")
            
            // Voice TTS dialogue trigger
            if gameState.save.isVoiceEnabled {
                gameState.audioController?.speakCoachLine("Awesome! You just scored \(amount) cash credits. Let's go buy some hypercars!")
            }
        } else {
            // Already claimed
            rewardClaimed = true
            claimStatusText = "ALREADY CLAIMED TODAY!"
        }
    }
}
