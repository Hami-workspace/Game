import SwiftUI

public struct GarageView: View {
    @ObservedObject var gameState: GameState
    
    // UI selection carousel index tracker
    @State private var selectedIndex: Int = 0
    
    // Customization selections temporary bindings
    @State private var paintColorHex: String = "#3A86FF"
    @State private var wheelStyle: String = "standard"
    @State private var lightColorHex: String = "#00FFFF"
    @State private var plateText: String = ""
    
    // Custom colors listing
    private let paintColors = [
        (name: "HOT PINK", hex: "#FF007F"),
        (name: "CYBER CYAN", hex: "#00FFFF"),
        (name: "AMBER GOLD", hex: "#FFBE0B"),
        (name: "VIPER GREEN", hex: "#38B000"),
        (name: "STEALTH BLACK", hex: "#000000"),
        (name: "ROYAL VIOLET", hex: "#7209B7")
    ]
    
    private let underglowColors = [
        (name: "CYAN", hex: "#00FFFF"),
        (name: "PINK", hex: "#FF007F"),
        (name: "GOLD", hex: "#FFBE0B"),
        (name: "GREEN", hex: "#39FF14"),
        (name: "PURPLE", hex: "#8338EC")
    ]
    
    public init(gameState: GameState) {
        self.gameState = gameState
    }
    
    public var body: some View {
        ZStack {
            GameTheme.bgDark.ignoresSafeArea()
            
            // 3D Turntable Preview in the background
            TurntableSCNView(gameState: gameState)
                .ignoresSafeArea()
            
            // Vignetting overlays
            VStack {
                Rectangle()
                    .fill(LinearGradient(colors: [GameTheme.bgDark.opacity(0.85), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(height: 100)
                Spacer()
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, GameTheme.bgDark.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 120)
            }
            .ignoresSafeArea()
            
            VStack {
                // TOP HEADER STRIP
                HStack {
                    Button(action: {
                        gameState.audioController?.playSFX("ui_click")
                        withAnimation {
                            gameState.currentScreen = .mainMenu
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("BACK TO HUB")
                        }
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(GameTheme.neonPink)
                    }
                    
                    Spacer()
                    
                    Text("GARAGE MECHANIC")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .modifier(GlowModifier(color: GameTheme.neonCyan, radius: 6))
                        .tracking(1)
                    
                    Spacer()
                    
                    // Cash Counter
                    HStack(spacing: 5) {
                        Image(systemName: "circle.circle.fill")
                            .foregroundColor(GameTheme.amberGold)
                        Text("\(gameState.save.cash)")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.4)))
                }
                .padding(.horizontal, 25)
                .padding(.top, 15)
                
                Spacer()
                
                // MIDDLE BLOCK - CAR SELECTION CAROUSEL
                let focusedCar = gameState.cars[selectedIndex]
                
                HStack {
                    // Previous Car Arrow
                    Button(action: {
                        navigateCarousel(forward: false)
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 38))
                            .foregroundColor(selectedIndex > 0 ? GameTheme.neonCyan : Color.white.opacity(0.1))
                    }
                    .disabled(selectedIndex == 0)
                    
                    Spacer()
                    
                    // Main Car Specs Box
                    GlassPanel(cornerRadius: 16, borderColor: GameTheme.neonPink.opacity(0.3)) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(focusedCar.name.uppercased())
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .modifier(GlowModifier(color: GameTheme.neonPink, radius: 4))
                                
                                Spacer()
                                
                                if !focusedCar.isUnlocked {
                                    HStack(spacing: 5) {
                                        Image(systemName: "lock.fill")
                                        Text("\(focusedCar.price) CASH")
                                    }
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundColor(GameTheme.amberGold)
                                } else if focusedCar.id == gameState.save.selectedCarId {
                                    Text("EQUIPPED")
                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                        .foregroundColor(GameTheme.successGreen)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(GameTheme.successGreen.opacity(0.15))
                                        .cornerRadius(6)
                                } else {
                                    Text("OWNED")
                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                        .foregroundColor(GameTheme.neonCyan)
                                }
                            }
                            
                            // Stats Panel
                            VStack(spacing: 8) {
                                statBarRow(title: "SPEED LIMIT", value: focusedCar.speedStat, color: GameTheme.neonPink)
                                statBarRow(title: "HANDLING", value: focusedCar.handlingStat, color: GameTheme.neonCyan)
                                statBarRow(title: "BRAKING POWER", value: focusedCar.brakeStat, color: GameTheme.successGreen)
                            }
                            
                            // Bottom Action Strip
                            HStack(spacing: 12) {
                                if !focusedCar.isUnlocked {
                                    // Purchase button
                                    Button("BUY MACHINE") {
                                        buyCar(focusedCar)
                                    }
                                    .buttonStyle(CyberButtonStyle(color: GameTheme.amberGold))
                                    .disabled(gameState.save.cash < focusedCar.price)
                                    
                                    Button("AD UNLOCK") {
                                        adUnlock(focusedCar)
                                    }
                                    .buttonStyle(CyberButtonStyle(color: GameTheme.neonCyan))
                                } else {
                                    // Selection / Customize
                                    if focusedCar.id != gameState.save.selectedCarId {
                                        Button("EQUIP CAR") {
                                            gameState.audioController?.playSFX("ui_click")
                                            gameState.selectCar(id: focusedCar.id)
                                            loadCarCustomizations(focusedCar)
                                        }
                                        .buttonStyle(CyberButtonStyle(color: GameTheme.neonCyan))
                                    }
                                    
                                    // Test Drive action
                                    Button("TEST DRIVE") {
                                        testDriveCar(focusedCar)
                                    }
                                    .buttonStyle(CyberButtonStyle(color: GameTheme.neonPink))
                                }
                            }
                        }
                        .frame(width: 320)
                    }
                    
                    Spacer()
                    
                    // Next Car Arrow
                    Button(action: {
                        navigateCarousel(forward: true)
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 38))
                            .foregroundColor(selectedIndex < gameState.cars.count - 1 ? GameTheme.neonCyan : Color.white.opacity(0.1))
                    }
                    .disabled(selectedIndex == gameState.cars.count - 1)
                }
                .padding(.horizontal, 20)
                .frame(height: 180)
                
                Spacer()
                
                // BOTTOM BLOCK - CUSTOMIZATIONS & UPGRADES (ONLY IF EQUIPPED & UNLOCKED)
                if focusedCar.isUnlocked && focusedCar.id == gameState.save.selectedCarId {
                    HStack(alignment: .top, spacing: 20) {
                        // Left: Mechanical upgrades
                        GlassPanel(cornerRadius: 16, borderColor: GameTheme.neonCyan.opacity(0.2)) {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("MECHANICAL UPGRADES")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundColor(GameTheme.neonCyan)
                                    .tracking(1)
                                
                                upgradeRow(title: "SPEED (+15KPH)", level: focusedCar.speedUpgrades, category: .speed, car: focusedCar)
                                upgradeRow(title: "HANDLING", level: focusedCar.handlingUpgrades, category: .handling, car: focusedCar)
                                upgradeRow(title: "BRAKES", level: focusedCar.brakeUpgrades, category: .brake, car: focusedCar)
                            }
                            .frame(width: 320, height: 150)
                        }
                        
                        // Right: Visual customizations
                        GlassPanel(cornerRadius: 16, borderColor: GameTheme.neonPink.opacity(0.2)) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("VISUALS CUSTOMIZATION")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundColor(GameTheme.neonPink)
                                    .tracking(1)
                                
                                // Color paint hex picker
                                HStack {
                                    Text("BODY PAINT:")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    HStack(spacing: 5) {
                                        ForEach(paintColors, id: \.hex) { item in
                                            Circle()
                                                .fill(Color(hex: item.hex))
                                                .frame(width: 20, height: 20)
                                                .overlay(Circle().stroke(paintColorHex == item.hex ? Color.white : Color.clear, lineWidth: 2))
                                                .onTapGesture {
                                                    paintColorHex = item.hex
                                                    saveCustomizations()
                                                }
                                        }
                                    }
                                }
                                
                                // Wheel Rims Style
                                HStack {
                                    Text("ALLOY RIMS:")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Picker("Alloy Rims", selection: $wheelStyle) {
                                        Text("CHROME").tag("standard")
                                        Text("TITANIUM").tag("sport")
                                        Text("DEEP GOLD").tag("deepdish")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 200)
                                    .onChange(of: wheelStyle) { _ in
                                        saveCustomizations()
                                    }
                                }
                                
                                // Underglow Neon Light
                                HStack {
                                    Text("UNDERGLOW:")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    HStack(spacing: 5) {
                                        ForEach(underglowColors, id: \.hex) { item in
                                            Circle()
                                                .fill(Color(hex: item.hex))
                                                .frame(width: 20, height: 20)
                                                .overlay(Circle().stroke(lightColorHex == item.hex ? Color.white : Color.clear, lineWidth: 2))
                                                .onTapGesture {
                                                    lightColorHex = item.hex
                                                    saveCustomizations()
                                                }
                                        }
                                    }
                                }
                                
                                // Plate Number editor
                                HStack {
                                    Text("LICENSE PLATE:")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    TextField("RACER-1", text: $plateText)
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 140)
                                        .foregroundColor(.black)
                                        .autocorrectionDisabled()
                                        .onChange(of: plateText) { newValue in
                                            // Limit length to 8 characters
                                            if newValue.count > 8 {
                                                plateText = String(newValue.prefix(8))
                                            }
                                            saveCustomizations()
                                        }
                                }
                            }
                            .frame(width: 320, height: 150)
                        }
                    }
                    .padding(.bottom, 25)
                } else {
                    // Prompt to equip
                    GlassPanel(cornerRadius: 12, borderColor: Color.white.opacity(0.1)) {
                        Text("EQUIP THIS UNLOCKED MACHINE TO CUSTOMIZE AND INSTALL RACING UPGRADES")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            // Find index of currently selected car
            if let index = gameState.cars.firstIndex(where: { $0.id == gameState.save.selectedCarId }) {
                selectedIndex = index
                loadCarCustomizations(gameState.cars[index])
            }
        }
    }
    
    // MARK: - Helper UI Builders
    
    private func statBarRow(title: String, value: Int, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 90, alignment: .leading)
            
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { pip in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(pip <= value ? color : Color.white.opacity(0.15))
                        .frame(width: 25, height: 8)
                }
            }
            Spacer()
        }
    }
    
    private func upgradeRow(title: String, level: Int, category: UpgradeCategory, car: Car) -> some View {
        let cost = car.upgradeCost(for: category)
        let isMaxed = level >= 5
        
        return HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                // Pip levels (0 to 5)
                HStack(spacing: 3) {
                    ForEach(0..<5) { idx in
                        Rectangle()
                            .fill(idx < level ? GameTheme.neonCyan : Color.white.opacity(0.15))
                            .frame(width: 14, height: 6)
                            .cornerRadius(1)
                    }
                }
            }
            
            Spacer()
            
            if isMaxed {
                Text("MAXED")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(GameTheme.successGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(GameTheme.successGreen.opacity(0.1))
                    .cornerRadius(4)
            } else {
                Button(action: {
                    upgradeCar(category: category)
                }) {
                    Text("\(cost) CASH")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(gameState.save.cash >= cost ? GameTheme.amberGold : Color.white.opacity(0.2))
                        .cornerRadius(6)
                }
                .disabled(gameState.save.cash < cost)
            }
        }
    }
    
    // MARK: - Actions
    
    private func navigateCarousel(forward: Bool) {
        gameState.audioController?.playSFX("ui_click")
        if forward {
            if selectedIndex < gameState.cars.count - 1 {
                selectedIndex += 1
            }
        } else {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
        }
        
        // Load customizations if unlocked
        let car = gameState.cars[selectedIndex]
        loadCarCustomizations(car)
    }
    
    private func loadCarCustomizations(_ car: Car) {
        paintColorHex = car.paintColorHex
        wheelStyle = car.wheelStyle
        lightColorHex = car.lightColorHex
        plateText = car.plateText
    }
    
    private func saveCustomizations() {
        let car = gameState.cars[selectedIndex]
        gameState.customizeCar(id: car.id, paintColorHex: paintColorHex, wheelStyle: wheelStyle, lightColorHex: lightColorHex, plateText: plateText)
    }
    
    private func buyCar(_ car: Car) {
        gameState.audioController?.playSFX("cash_registers")
        let success = gameState.purchaseCar(id: car.id)
        if success {
            loadCarCustomizations(gameState.cars[selectedIndex])
            
            // Speak congratulations
            if gameState.save.isVoiceEnabled {
                gameState.audioController?.speakCoachLine("Wow! That is a stellar acquisition. Let's customize the color scheme and see what she can do!")
            }
        }
    }
    
    private func adUnlock(_ car: Car) {
        gameState.audioController?.playSFX("cash_registers")
        gameState.unlockCarViaAd(id: car.id)
        loadCarCustomizations(gameState.cars[selectedIndex])
        
        if gameState.save.isVoiceEnabled {
            gameState.audioController?.speakCoachLine("Awesome! Thanks to our sponsors, this hot ride is now fully unlocked for you.")
        }
    }
    
    private func upgradeCar(category: UpgradeCategory) {
        gameState.audioController?.playSFX("wrench_clank")
        let success = gameState.upgradeCar(id: gameState.save.selectedCarId, category: category)
        if success {
            // Simple micro-refresh trigger
            let current = selectedIndex
            selectedIndex = current
        }
    }
    
    private func testDriveCar(_ car: Car) {
        // Enters Free Ride mode in this car instantly!
        gameState.audioController?.playSFX("race_start_chirp")
        
        gameState.selectedMode = .freeRide
        gameState.selectedLocationId = "farmland" // Default practice run location
        gameState.activeMissionId = nil
        
        withAnimation {
            gameState.currentScreen = .gameplay
        }
    }
}
