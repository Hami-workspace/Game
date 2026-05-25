import SwiftUI

public struct LaunchView: View {
    @ObservedObject var gameState: GameState
    
    @State private var loadingProgress: Double = 0.0
    @State private var currentTip: String = ""
    private let tips = [
        "Tip: Overtake closely at high speed for HUGE combo multipliers!",
        "Tip: Frost Snow has low grip. Master the slip and counter-steer to drift!",
        "Tip: City skies look spectacular in First-Person camera view!",
        "Tip: Customize your license plate in the Garage to show off your signature look!",
        "Tip: Watch ads in the Hub to quickly score starting bonus cash!",
        "Tip: Underglow lights can be customized in the Garage for night runs!"
    ]
    
    private let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    private let tipTimer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()
    
    public init(gameState: GameState) {
        self.gameState = gameState
    }
    
    public var body: some View {
        ZStack {
            // Retro Cyber Background Grid
            GameTheme.bgDark.ignoresSafeArea()
            
            // Grid artwork background overlay
            VStack {
                Spacer()
                // Visual representation of a neon synthwave horizon grid
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [GameTheme.neonPink.opacity(0.15), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: 250)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Game Title Logo
                VStack(spacing: 5) {
                    Text("NEON")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(GameTheme.neonCyan)
                        .modifier(GlowModifier(color: GameTheme.neonCyan, radius: 10))
                        .tracking(8)
                    
                    Text("HIGHWAY RACER")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .modifier(GlowModifier(color: GameTheme.neonPink, radius: 12))
                        .italic()
                        .tracking(4)
                }
                
                Spacer()
                
                // Loader and Tips
                VStack(spacing: 20) {
                    // Tip Box
                    GlassPanel(cornerRadius: 12, borderColor: GameTheme.neonCyan.opacity(0.3)) {
                        Text(currentTip)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(height: 40)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: 550)
                    
                    // Progress Bar
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("PRELOADING ASSETS...")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(GameTheme.neonCyan)
                                .tracking(1)
                            
                            Spacer()
                            
                            Text("\(Int(loadingProgress * 100))%")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        // Custom Neon Loading bar track
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 10)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [GameTheme.neonPink, GameTheme.neonCyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: CGFloat(loadingProgress) * 450, height: 10)
                                .modifier(GlowModifier(color: GameTheme.neonPink, radius: 6))
                        }
                        .frame(width: 450)
                    }
                }
                .padding(.bottom, 60)
            }
            .padding()
        }
        .onAppear {
            currentTip = tips.randomElement() ?? ""
            
            // Activate background music preload safely
            gameState.audioController = AudioController()
            gameState.audioController?.playMusic()
        }
        .onReceive(timer) { _ in
            if loadingProgress < 1.0 {
                // Smooth progressive loading increments
                loadingProgress += 0.015
            } else {
                // Done loading! Go to Welcome popup or Main Menu
                timer.upstream.connect().cancel()
                withAnimation(.spring()) {
                    if gameState.isDailyRewardAvailable() {
                        gameState.currentScreen = .welcome
                    } else {
                        gameState.currentScreen = .mainMenu
                    }
                }
            }
        }
        .onReceive(tipTimer) { _ in
            withAnimation(.easeInOut) {
                currentTip = tips.randomElement() ?? ""
            }
        }
    }
}
