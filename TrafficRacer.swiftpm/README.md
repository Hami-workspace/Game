# Neon Highway Racer 3D (iOS Game)

A complete, App-Store-ready **3D Arcade Highway Traffic-Racing Game** built natively for **iOS (iPhone + iPad)** using **SwiftUI** for menus/HUD overlays and **SceneKit** for the 3D gameplay scene, targeting iOS 16+.

The project is structured as a **Swift Playgrounds App (`.swiftpm`) bundle**. 

---

## Key Features Built-in

- **Endless Recycled Highway:** Automatic segment recycling pool (6 segments of 100m) with dynamic guard rails, road dashes, and custom procedural roadside scenery.
- **Procedural 3D Low-Poly Models:** Custom vehicles (player hypercars and traffic types: sedan, pickup, sports car, heavy semi, oil chemical tanker) built using SceneKit geometry primitives. No external asset files are required to compile!
- **Dynamic Customizer:** Paint color picker, alloy wheel hub styles, underglow color maps, and a customizable alphanumeric license plate that renders the player's name in **3D text (`SCNText`)** on the car!
- **Automatic 6-Speed Transmission:** Simulated gearbox that calculates RPM and applies pitch-shifting to the engine audio loop in real-time.
- **Slippery Drift Physics:** Low tire grip simulation in the **Frost Snow** location, implementing sideslip calculations and counter-steering.
- **Career AI Rival:** A head-to-head opponent vehicle utilizing human rubber-banding logic, racing the player to a 1,500m finish line.
- **Dynamic Coach Announcer:** Interactive welcome popup, daily streak streaks, and personalized tips read aloud in real-time using iOS's native speech synthesis (`AVSpeechSynthesizer`).
- **Persistence System:** Auto-saves wallet currency, EXP level, upgrades, owned cars, customized styles, streak counters, high scores, and audio preferences between sessions.
- **Simulator Keyboard Hotkeys:** Custom keyboard listeners (W/S/A/D, H, C, Space/Esc) built directly on the bridged view controller for rapid simulator testing on Mac.

---

## Project Structure & Architecture

The application is structured inside a highly organized MVVM model:

```text
TrafficRacer.swiftpm/
├── Package.swift               # Swift Playgrounds App manifest (iOS 16+, Landscape)
├── Sources/
│   ├── App/
│   │   └── TrafficRacerApp.swift # SwiftUI App Entry Point
│   ├── Models/
│   │   ├── Car.swift           # Hypercar specification profile schemas
│   │   ├── Location.swift      # Location skies, lightings, and grip configurations
│   │   ├── Mission.swift       # Challenge targets, limits, and payout rates
│   │   └── SaveData.swift      # Persisted user profile variables
│   ├── GameState/
│   │   ├── GameState.swift     # Core ObservableObject managing session profile
│   │   ├── AudioController.swift # AVAudioEngine pitch-shifting & TTS voices
│   │   └── MotionManager.swift  # CoreMotion device tilt steers manager
│   ├── Scenes/
│   │   ├── RaceScene.swift     # Core 3D SceneKit gameplay world simulation
│   │   ├── VehicleNode.swift   # Procedural SCNNode low-poly 3D models builders
│   │   ├── RoadManager.swift   # Procedural endless highway segment recycler
│   │   ├── TrafficManager.swift# Traffic spawner, lane-AI, and near-miss checks
│   │   └── PhysicsHelper.swift # SCNPhysicsBody collision bitmasks
│   ├── Theme/
│   │   └── GameTheme.swift     # Cyber-Synthwave dark styling palette & buttons
│   ├── Views/
│   │   ├── MainContainerView.swift # Coordinator router / screen switcher
│   │   ├── LaunchView.swift        # Loading splash with Tip ticker
│   │   ├── WelcomeView.swift       # Announcer welcome & Daily Streaks
│   │   ├── MainMenuView.swift      # Turntable 3D rotating display hub
│   │   ├── ModeSelectView.swift    # Game Mode cards carousel
│   │   ├── LevelSelectView.swift   # Interactive map pin pins selector
│   │   ├── GarageView.swift        # Pip upgrades, visuals customize, test drives
│   │   ├── HUDView.swift           # In-race speedometer overlays & touch pedal pads
│   │   ├── PauseView.swift         # Glass pause panel options
│   │   └── ResultsView.swift       # Final scorecard recap & Double ad stubs
│   └── Resources/
│       ├── cars.json           # Catalog of 15 premium original cars
│       ├── locations.json      # Environments settings (skyboxes, grip friction)
│       └── missions.json       # Challenge objectives specifications
└── README.md                   # This instruction guide
```

---

## How to Open, Build, and Run

### On macOS (with Xcode):
1. Copy the entire folder `TrafficRacer.swiftpm` to your Mac.
2. Double-click the `TrafficRacer.swiftpm` folder. macOS will automatically identify it as a Swift Playgrounds App package and open it directly in **Xcode**!
3. Alternatively, open Xcode, select **File -> Open...**, navigate to the directory, and select the folder.
4. Select an iOS Simulator (e.g., iPhone 15 Pro, iPad Pro) or your plugged-in hardware device.
5. Click the **Run** button (or press `Cmd + R`). The app compiles and boots instantly in **Landscape** orientation!

### On iPad (with Swift Playgrounds):
1. AirDrop the `TrafficRacer.swiftpm` bundle directory to your iPad.
2. iPad will automatically prompt to open it in **Swift Playgrounds App** (available free on the App Store).
3. Tap the **Play** button. You can play, edit code, and inspect the 3D SceneKit world live on your tablet!

---

## Expanding Game Content via JSON Configs

All data elements are decoded dynamically from static JSON catalogs under `Sources/Resources/`. You can scale this game to the moon without modifying code!

### 1. Adding/Editing Cars (`cars.json`)
You can expand or edit the stats of the **15 cars** (Mule, Volt, Apex, etc.). To add a car, append a new block inside the array:
```json
{
  "id": "phantom_super",
  "name": "Phantom Carbon",
  "baseSpeed": 5,
  "baseHandling": 4,
  "baseBrake": 5,
  "topSpeedKPH": 450,
  "price": 6500000,
  "speedUpgrades": 0,
  "handlingUpgrades": 0,
  "brakeUpgrades": 0,
  "paintColorHex": "#1A1A1A",
  "wheelStyle": "sport",
  "lightColorHex": "#00FFFF",
  "plateText": "STEALTH",
  "isUnlocked": false
}
```

### 2. Expanding Challenges (`missions.json`)
You can expand the Challenge checklist up to **100 missions**. To add a mission, append a new challenge card detailing target values and objectives:
```json
{
  "id": "challenge_6",
  "challengeNumber": 6,
  "objectiveText": "Perform 10 close near-miss passes in under 80 seconds!",
  "targetType": "performNearMisses",
  "targetValue": 10,
  "targetTimeLimit": 80,
  "cashReward": 8500,
  "isCompleted": false,
  "highHighScore": 0
}
```
Available `targetType` triggers built-in:
- `"reachFinishLine"`: Reach target Z distance (meters).
- `"reachSpeedLimit"`: Hitting KPH speedometer.
- `"performNearMisses"`: Dodging traffic cars closely.
- `"accumulateDistance"`: Surviving highway segments.
- `"holdSpeedDuration"`: Hold a target speed (KPH) for X seconds.

---

## Asset Slots & Custom Sound Toggles

We have equipped the game with safe stubs so it compiles out of the box. To add physical custom MP3/WAV assets to the target bundle:
1. Drag your files into `Sources/Resources/` folder.
2. In `AudioController.swift`, the file bindings are configured. Make sure your asset names match these:
   - **Background Music Loop:** `synthwave_bg.mp3` (loops automatically).
   - **Continuous Engine Sound Loop:** `engine_loop.wav` (loops and pitches automatically).
   - **Vehicle Crash sound:** `explosion_crash.wav` (triggered upon collision contacts).
   - **Near-Miss sound:** `whoosh_nearmiss.wav` (triggered when overtaking traffic closely).
   - **Gear shift:** `gear_click.wav` (triggered when automatic gearbox shifts gears).
   - **Cash rewards register:** `cash_registers.wav` (triggered when claiming bonuses or doubling).
   - **UI Clicks:** `ui_click.wav` (standard buttons navigation tap).

---

## Ad SDK Integration Slots (TODOs)

We have stubbed all ad reward options inside `GameState.swift` to immediately grant rewards without third-party paid dependencies. To implement a real mobile ad network (e.g., Google AdMob or AppLovin MAX):

1. Add your chosen SDK dependency inside `Package.swift` in the `dependencies` array.
2. Import the framework in `GameState.swift`.
3. In `GameState.swift`, replace the following stub bodies with your SDK presentation callbacks:
   - **`watchAdForCash()`**: Triggers a Rewarded Ad. Upon completion, grant `save.cash += 500`.
   - **`claimAdDoubleRewards(baseCash:baseExp)`**: Triggers a Rewarded Ad. Upon completion, double the parameters.
   - **`unlockCarViaAd(id:)`**: Triggers a Rewarded Ad. Upon completion, unlock the requested vehicle ID.
