import SwiftUI

public struct SettingsView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.dismiss) var dismiss // If presented as sheet
    
    // Binding helpers for clean state syncing
    @State private var isSoundEnabled: Bool = true
    @State private var isVoiceEnabled: Bool = true
    @State private var musicVolume: Double = 80.0
    @State private var sfxVolume: Double = 80.0
    @State private var isAutoAcceleration: Bool = true
    @State private var isKMUnit: Bool = true
    @State private var controlType: String = "buttons"
    
    @State private var showHelp = false
    
    public init(gameState: GameState) {
        self.gameState = gameState
    }
    
    public var body: some View {
        ZStack {
            GameTheme.bgDark.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header Bar
                HStack {
                    Text("SETTINGS")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .modifier(GlowModifier(color: GameTheme.neonPink, radius: 8))
                    
                    Spacer()
                    
                    Button(action: {
                        saveAndClose()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(GameTheme.neonPink)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                HStack(spacing: 30) {
                    // Left Column - Audio Settings
                    GlassPanel(cornerRadius: 16, borderColor: GameTheme.neonCyan.opacity(0.3)) {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("AUDIO SETTINGS")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(GameTheme.neonCyan)
                                .tracking(1)
                            
                            Toggle(isOn: $isSoundEnabled) {
                                Text("MASTER SOUNDS")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .tint(GameTheme.neonPink)
                            
                            Toggle(isOn: $isVoiceEnabled) {
                                Text("COACH VOICE ANNOUNCEMENTS")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .tint(GameTheme.neonPink)
                            
                            // Music Volume Slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("MUSIC VOLUME")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                    Text("\(Int(musicVolume))%")
                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                        .foregroundColor(GameTheme.neonPink)
                                }
                                Slider(value: $musicVolume, in: 0...100, step: 5)
                                    .tint(GameTheme.neonPink)
                                    .disabled(!isSoundEnabled)
                            }
                            
                            // SFX Volume Slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("SOUND FX VOLUME")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                    Text("\(Int(sfxVolume))%")
                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                        .foregroundColor(GameTheme.neonCyan)
                                }
                                Slider(value: $sfxVolume, in: 0...100, step: 5)
                                    .tint(GameTheme.neonCyan)
                                    .disabled(!isSoundEnabled)
                            }
                        }
                        .frame(width: 320, height: 260)
                    }
                    
                    // Right Column - Controls & Units
                    GlassPanel(cornerRadius: 16, borderColor: GameTheme.neonPink.opacity(0.3)) {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("GAMEPLAY CONFIGS")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(GameTheme.neonPink)
                                .tracking(1)
                            
                            // Control Type Picker (Buttons vs Tilt)
                            HStack {
                                Text("STEERING:")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Spacer()
                                Picker("Steering Mode", selection: $controlType) {
                                    Text("BUTTONS").tag("buttons")
                                    Text("TILT SHIFT").tag("tilt")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 160)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(8)
                            }
                            
                            // Acceleration Selector
                            Toggle(isOn: $isAutoAcceleration) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AUTO ACCELERATE")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("Always gas, just steer & brake")
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .tint(GameTheme.neonCyan)
                            
                            // Distance units
                            HStack {
                                Text("DISTANCE UNIT:")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Spacer()
                                Picker("Distance Units", selection: $isKMUnit) {
                                    Text("KM/H").tag(true)
                                    Text("MPH").tag(false)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 140)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(8)
                            }
                            
                            // Help Instructions Button
                            Button(action: {
                                gameState.audioController?.playSFX("ui_click")
                                showHelp.toggle()
                            }) {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                    Text("HOW TO PLAY / CONTROLS")
                                }
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(GameTheme.neonCyan)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).stroke(GameTheme.neonCyan, lineWidth: 1))
                            }
                        }
                        .frame(width: 320, height: 260)
                    }
                }
                
                Spacer()
            }
            .padding()
            
            // Pop-up Control Diagram Layout (Help Modal overlay)
            if showHelp {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("CONTROL DIAGRAM MANUAL")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(GameTheme.neonCyan)
                            .modifier(GlowModifier(color: GameTheme.neonCyan, radius: 6))
                        
                        GlassPanel(cornerRadius: 16, borderColor: GameTheme.neonCyan.opacity(0.4)) {
                            VStack(spacing: 15) {
                                HStack(spacing: 30) {
                                    // Touch controls column
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("TOUCH MECHANICS (ON SCREEN)")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(GameTheme.neonPink)
                                        
                                        HStack {
                                            Image(systemName: "arrow.left.and.right.circle.fill").foregroundColor(.white)
                                            Text("Buttons: Tap Left / Right indicators to Steer")
                                        }
                                        HStack {
                                            Image(systemName: "iphone.radiowaves.left.and.right").foregroundColor(.white)
                                            Text("Tilt mode: Tilt your device to Steer")
                                        }
                                        HStack {
                                            Image(systemName: "arrow.up.circle.fill").foregroundColor(.white)
                                            Text("Accelerate: Tap Right pedals (Manual mode only)")
                                        }
                                        HStack {
                                            Image(systemName: "arrow.down.circle.fill").foregroundColor(.white)
                                            Text("Brake: Tap Left pedal to slow down")
                                        }
                                        HStack {
                                            Image(systemName: "megaphone.fill").foregroundColor(.white)
                                            Text("Horn: Blast horn to clear path!")
                                        }
                                    }
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    
                                    // Keyboard controls column (Simulator support)
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("KEYBOARD MECHANICS (SIMULATOR)")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(GameTheme.neonCyan)
                                        
                                        Text("• W / Up Arrow: Accelerate Gas")
                                        Text("• S / Down Arrow: Brake / Reverse")
                                        Text("• A / Left Arrow: Steer Vehicle Left")
                                        Text("• D / Right Arrow: Steer Vehicle Right")
                                        Text("• H: Blast horn warning sirens")
                                        Text("• C: Toggle Camera (3rd Person -> 1st -> Top)")
                                        Text("• ESC / Space: Pause / Resume Game")
                                    }
                                    .font(.system(size: 11, weight: .medium, design: .mono))
                                    .foregroundColor(.white)
                                }
                                .padding()
                                
                                Button("CLOSE DIAGRAM") {
                                    gameState.audioController?.playSFX("ui_click")
                                    showHelp = false
                                }
                                .buttonStyle(CyberButtonStyle(color: GameTheme.neonPink))
                                .frame(width: 180)
                            }
                        }
                        .frame(maxWidth: 680)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadStateIntoUI()
        }
    }
    
    private func loadStateIntoUI() {
        self.isSoundEnabled = gameState.save.isSoundEnabled
        self.isVoiceEnabled = gameState.save.isVoiceEnabled
        self.musicVolume = Double(gameState.save.musicVolume * 100.0)
        self.sfxVolume = Double(gameState.save.sfxVolume * 100.0)
        self.isAutoAcceleration = gameState.save.isAutoAcceleration
        self.isKMUnit = gameState.save.isKMUnit
        self.controlType = gameState.save.controlType
    }
    
    private func saveAndClose() {
        // Apply settings changes back to GameState
        gameState.save.isSoundEnabled = isSoundEnabled
        gameState.save.isVoiceEnabled = isVoiceEnabled
        gameState.save.musicVolume = Float(musicVolume / 100.0)
        gameState.save.sfxVolume = Float(sfxVolume / 100.0)
        gameState.save.isAutoAcceleration = isAutoAcceleration
        gameState.save.isKMUnit = isKMUnit
        gameState.save.controlType = controlType
        
        gameState.saveProgress()
        
        // Update Audio buses in AudioController
        gameState.audioController?.updateSettings(
            soundEnabled: isSoundEnabled,
            voiceEnabled: isVoiceEnabled,
            musicVol: Float(musicVolume / 100.0),
            sfxVol: Float(sfxVolume / 100.0)
        )
        
        // Sound feedback
        gameState.audioController?.playSFX("ui_click")
        
        // Go back
        withAnimation {
            gameState.currentScreen = .mainMenu
        }
    }
}
