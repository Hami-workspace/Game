import SwiftUI

public struct HUDView: View {
    @ObservedObject var gameState: GameState
    @ObservedObject var raceScene: RaceScene
    
    // Core callback triggers
    var onPause: () -> Void
    var onSteer: (Float) -> Void
    var onAccelerate: (Bool) -> Void
    var onBrake: (Bool) -> Void
    var onCameraToggle: () -> Void
    var onHorn: () -> Void
    
    // Control variables
    @State private var isSteeringLeft = false
    @State private var isSteeringRight = false
    
    public init(gameState: GameState, raceScene: RaceScene, onPause: @escaping () -> Void, onSteer: @escaping (Float) -> Void, onAccelerate: @escaping (Bool) -> Void, onBrake: @escaping (Bool) -> Void, onCameraToggle: @escaping () -> Void, onHorn: @escaping () -> Void) {
        self.gameState = gameState
        self.raceScene = raceScene
        self.onPause = onPause
        self.onSteer = onSteer
        self.onAccelerate = onAccelerate
        self.onBrake = onBrake
        self.onCameraToggle = onCameraToggle
        self.onHorn = onHorn
    }
    
    public var body: some View {
        ZStack {
            // TOP HUD HUD ROW (Top bar overlays)
            VStack {
                HStack(alignment: .top) {
                    
                    // Left Column: Pause button & Score stats
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Button(action: {
                                onPause()
                            }) {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                                    .overlay(Circle().stroke(GameTheme.neonPink, lineWidth: 1.5))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SCORE")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundColor(GameTheme.neonCyan)
                                Text("\(raceScene.activeScore)")
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .modifier(GlowModifier(color: GameTheme.neonCyan, radius: 4))
                            }
                        }
                        
                        // Active near-miss combo popups
                        if raceScene.comboMultiplier > 1 {
                            HStack {
                                Text("OVERTAKE COMBO")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundColor(GameTheme.neonPink)
                                
                                Text("×\(raceScene.comboMultiplier)")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .modifier(GlowModifier(color: GameTheme.neonPink, radius: 6))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.6)))
                            .transition(.scale)
                        }
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    // Center Top: Objective active Banner
                    VStack {
                        let headerText = gameState.selectedMode == .challenge ? "CHALLENGE \(gameState.activeMission?.challengeNumber ?? 1)" : gameState.selectedMode.displayName.uppercased()
                        let objectiveText = gameState.selectedMode == .challenge ? (gameState.activeMission?.objectiveText ?? "") : (gameState.selectedMode == .career ? "Overtake and finish 1st vs AI!" : "Survive! Dodge highway traffic.")
                        
                        GlassPanel(cornerRadius: 10, borderColor: GameTheme.amberGold.opacity(0.3)) {
                            VStack(spacing: 2) {
                                Text(headerText)
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundColor(GameTheme.amberGold)
                                    .tracking(2)
                                
                                Text(objectiveText)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            .frame(width: 250)
                            .padding(.vertical, -4)
                        }
                    }
                    
                    Spacer()
                    
                    // Right Column: Speedometer, Gear, Distance
                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 15) {
                            
                            // Gear box
                            VStack(spacing: 2) {
                                Text("GEAR")
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                                Text("\(raceScene.currentGear)")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(GameTheme.neonPink)
                                    .modifier(GlowModifier(color: GameTheme.neonPink, radius: 4))
                            }
                            .frame(width: 40)
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.6)))
                            
                            // Speed KPH/MPH ticker
                            let speedVal = gameState.save.isKMUnit ? Int(raceScene.currentSpeedKPH) : Int(raceScene.currentSpeedKPH * 0.621371)
                            let unitStr = gameState.save.isKMUnit ? "KPH" : "MPH"
                            
                            VStack(alignment: .trailing, spacing: 1) {
                                HStack(alignment: .bottom, spacing: 2) {
                                    Text("\(speedVal)")
                                        .font(.system(size: 32, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                        .modifier(GlowModifier(color: GameTheme.neonCyan, radius: 6))
                                    
                                    Text(unitStr)
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(GameTheme.neonCyan)
                                }
                            }
                        }
                        
                        // Distance and Timer checklist
                        HStack(spacing: 12) {
                            // Distance covered
                            let distVal = gameState.save.isKMUnit ? (raceScene.totalDistanceMeters / 1000.0) : (raceScene.totalDistanceMeters / 1609.34)
                            let distUnit = gameState.save.isKMUnit ? "km" : "mi"
                            
                            HStack(spacing: 4) {
                                Image(systemName: "road.lanes").font(.system(size: 10))
                                Text(String(format: "%.2f %@", distVal, distUnit))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            
                            // Overtakes count
                            HStack(spacing: 4) {
                                Image(systemName: "car.2.fill").font(.system(size: 10))
                                Text("\(raceScene.activeOvertakes)")
                            }
                            .foregroundColor(.white.opacity(0.8))
                            
                            // Timer countdown (if applicable)
                            if gameState.selectedMode == .challenge || gameState.selectedMode == .timeTrial {
                                HStack(spacing: 4) {
                                    Image(systemName: "stopwatch.fill").font(.system(size: 10))
                                    Text(String(format: "%.1fs", raceScene.timeRemaining))
                                }
                                .foregroundColor(raceScene.timeRemaining < 10 ? Color.red : GameTheme.successGreen)
                                .modifier(GlowModifier(color: raceScene.timeRemaining < 10 ? Color.red : .clear, radius: 4))
                            }
                        }
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 15)
                
                Spacer()
                
                // BOTTOM AREA - ON-SCREEN STEER BUTTONS & PADS
                HStack {
                    
                    // Left Edge Steer Controls
                    if gameState.save.controlType == "buttons" {
                        HStack(spacing: 20) {
                            // Steer Left Button pad
                            Button(action: {}) {}
                                .pressAction(onPress: {
                                    isSteeringLeft = true
                                    onSteer(-1.0)
                                }, onRelease: {
                                    isSteeringLeft = false
                                    updateSteeringInputs()
                                })
                                .buttonStyle(HUDPadStyle(iconName: "arrow.left", isPressed: isSteeringLeft))
                            
                            // Steer Right Button pad
                            Button(action: {}) {}
                                .pressAction(onPress: {
                                    isSteeringRight = true
                                    onSteer(1.0)
                                }, onRelease: {
                                    isSteeringRight = false
                                    updateSteeringInputs()
                                })
                                .buttonStyle(HUDPadStyle(iconName: "arrow.right", isPressed: isSteeringRight))
                        }
                        .padding(.leading, 30)
                    } else {
                        // Tilt Shift calibration guide graphic
                        VStack(spacing: 4) {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .font(.system(size: 20))
                            Text("TILT TO STEER")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(GameTheme.neonCyan.opacity(0.6))
                        .padding(.leading, 40)
                    }
                    
                    // Center horn blast button
                    Button(action: {
                        onHorn()
                    }) {
                        Image(systemName: "megaphone.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .overlay(Circle().stroke(GameTheme.neonCyan.opacity(0.5), lineWidth: 1.5))
                    }
                    
                    Spacer()
                    
                    // Right Edge: Camera Toggle & Pedal pads
                    HStack(spacing: 20) {
                        
                        // Camera View Cycler
                        Button(action: {
                            onCameraToggle()
                        }) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                                .overlay(Circle().stroke(GameTheme.neonPink, lineWidth: 1.5))
                        }
                        
                        // Decelerate/Brake pedal
                        HUDPedalButton(title: "BRAKE", iconName: "arrow.down.square.fill", color: GameTheme.neonPink, onPress: {
                            onBrake(true)
                        }, onRelease: {
                            onBrake(false)
                        })
                        
                        // Accelerate gas pedal (only visible if Auto Acceleration is manual!)
                        if !gameState.save.isAutoAcceleration {
                            HUDPedalButton(title: "GAS", iconName: "arrow.up.square.fill", color: GameTheme.successGreen, onPress: {
                                onAccelerate(true)
                            }, onRelease: {
                                onAccelerate(false)
                            })
                        }
                    }
                    .padding(.trailing, 30)
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    private func updateSteeringInputs() {
        if isSteeringLeft {
            onSteer(-1.0)
        } else if isSteeringRight {
            onSteer(1.0)
        } else {
            onSteer(0.0) // Return to center neutral
        }
    }
}

// MARK: - Customizable HUD Button Styles

struct HUDPadStyle: ButtonStyle {
    let iconName: String
    let isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        Image(systemName: iconName)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 65, height: 65)
            .background(Circle().fill(isPressed ? GameTheme.neonCyan : Color.black.opacity(0.55)))
            .overlay(Circle().stroke(GameTheme.neonCyan, lineWidth: 2))
            .scaleEffect(isPressed ? 0.92 : 1.0)
    }
}

struct HUDPedalButton: View {
    let title: String
    let iconName: String
    let color: Color
    let onPress: () -> Void
    let onRelease: () -> Void
    
    @State private var pressed = false
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.white.opacity(0.7))
            
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 55, height: 75)
                .background(RoundedRectangle(cornerRadius: 10).fill(pressed ? color : Color.black.opacity(0.55)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 2))
                .scaleEffect(pressed ? 0.92 : 1.0)
        }
        .pressAction(onPress: {
            pressed = true
            onPress()
        }, onRelease: {
            pressed = false
            onRelease()
        })
    }
}

// MARK: - Specialized Touch Press Gestures Recognizer Extension

struct PressGestureModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        onPress()
                    }
                    .onEnded { _ in
                        onRelease()
                    }
            )
    }
}

extension View {
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressGestureModifier(onPress: onPress, onRelease: onRelease))
    }
}
 Amor
