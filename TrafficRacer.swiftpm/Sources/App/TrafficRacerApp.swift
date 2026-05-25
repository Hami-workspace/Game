import SwiftUI

@main
struct TrafficRacerApp: App {
    @StateObject private var gameState = GameState()
    
    var body: some Scene {
        WindowGroup {
            MainContainerView(gameState: gameState)
                .ignoresSafeArea()
                .preferredColorScheme(.dark) // Dark synthwave force
        }
    }
}
