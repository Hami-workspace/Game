import SwiftUI

public struct MainContainerView: View {
    @ObservedObject var gameState: GameState
    
    public init(gameState: GameState) {
        self.gameState = gameState
    }
    
    public var body: some View {
        ZStack {
            // Main switch router
            switch gameState.currentScreen {
            case .launch:
                LaunchView(gameState: gameState)
                    .transition(.opacity)
                
            case .welcome:
                WelcomeView(gameState: gameState)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                
            case .mainMenu:
                MainMenuView(gameState: gameState)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity
                    ))
                
            case .garage:
                GarageView(gameState: gameState)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom),
                        removal: .move(edge: .top)
                    ))
                
            case .modeSelect:
                ModeSelectView(gameState: gameState)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                
            case .levelSelect:
                LevelSelectView(gameState: gameState)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                
            case .gameplay:
                GameplayView(gameState: gameState)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: gameState.currentScreen)
        .statusBarHidden(true)
    }
}
