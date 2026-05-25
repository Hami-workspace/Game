import SwiftUI

public struct PauseView: View {
    @ObservedObject var gameState: GameState
    
    var onResume: () -> Void
    var onRestart: () -> Void
    var onCameraToggle: () -> Void
    var onQuit: () -> Void
    
    public init(gameState: GameState, onResume: @escaping () -> Void, onRestart: @escaping () -> Void, onCameraToggle: @escaping () -> Void, onQuit: @escaping () -> Void) {
        self.gameState = gameState
        self.onResume = onResume
        self.onRestart = onRestart
        self.onCameraToggle = onCameraToggle
        self.onQuit = onQuit
    }
    
    public var body: some View {
        ZStack {
            // Darkened backdrop blur
            Color.black.opacity(0.75).ignoresSafeArea()
            
            GlassPanel(cornerRadius: 24, borderColor: GameTheme.neonPink.opacity(0.4)) {
                VStack(spacing: 22) {
                    
                    // Header Title
                    VStack(spacing: 4) {
                        Text("GAME PAUSED")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .modifier(GlowModifier(color: GameTheme.neonPink, radius: 10))
                        
                        Text("\(gameState.activeLocation.name) • \(gameState.selectedMode.displayName.uppercased())")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(GameTheme.neonCyan)
                            .tracking(2)
                    }
                    .padding(.top, 10)
                    
                    Divider()
                        .background(Color.white.opacity(0.15))
                        .frame(width: 250)
                    
                    // Buttons list
                    VStack(spacing: 12) {
                        Button(action: {
                            gameState.audioController?.playSFX("ui_click")
                            onResume()
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("RESUME DRIVE")
                            }
                            .frame(width: 220)
                        }
                        .buttonStyle(CyberButtonStyle(color: GameTheme.neonCyan))
                        
                        Button(action: {
                            gameState.audioController?.playSFX("ui_click")
                            onCameraToggle()
                        }) {
                            HStack {
                                Image(systemName: "eye.fill")
                                Text("CYCLE CAMERA VIEW")
                            }
                            .frame(width: 220)
                        }
                        .buttonStyle(CyberButtonStyle(color: GameTheme.neonPink.opacity(0.8)))
                        
                        Button(action: {
                            gameState.audioController?.playSFX("race_start_chirp")
                            onRestart()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("RESTART RUN")
                            }
                            .frame(width: 220)
                        }
                        .buttonStyle(CyberButtonStyle(color: GameTheme.amberGold))
                        
                        Button(action: {
                            gameState.audioController?.playSFX("ui_click")
                            onQuit()
                        }) {
                            HStack {
                                Image(systemName: "house.fill")
                                Text("QUIT TO HUB")
                            }
                            .frame(width: 220)
                        }
                        .buttonStyle(CyberButtonStyle(color: Color.gray))
                    }
                    .padding(.bottom, 10)
                }
                .frame(width: 320)
            }
        }
    }
}
