import SwiftUI

public struct GameTheme {
    // Premium Color Palette
    public static let bgDark = Color(hex: "#0D0B18")         // Sleek Cyber Dark
    public static let bgPanel = Color(hex: "#16132A")        // Translucent card base
    public static let neonPink = Color(hex: "#FF007F")       // Cyber Pink accent
    public static let neonCyan = Color(hex: "#00FFFF")       // Cyber Cyan accent
    public static let amberGold = Color(hex: "#FFB300")      // Gold Coins/Highscore accent
    public static let successGreen = Color(hex: "#39FF14")   // Electric green
    
    // Gradients
    public static let primaryGradient = LinearGradient(
        colors: [neonPink, Color(hex: "#B5179E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let secondaryGradient = LinearGradient(
        colors: [neonCyan, Color(hex: "#4CC9F0")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let goldGradient = LinearGradient(
        colors: [amberGold, Color(hex: "#FFE066")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Neon glow helper
    public static func neonShadow(color: Color, radius: CGFloat = 8) -> some ViewModifier {
        GlowModifier(color: color, radius: radius)
    }
}

// Helper Extension for Hex Colors
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Glowing View Modifier
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 1.5)
    }
}

// Glassmorphism Container Panel
public struct GlassPanel<Content: View>: View {
    public let cornerRadius: CGFloat
    public let borderColor: Color
    public let content: () -> Content
    
    public init(cornerRadius: CGFloat = 16, borderColor: Color = GameTheme.neonPink.opacity(0.2), @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.content = content
    }
    
    public var body: some View {
        content()
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(GameTheme.bgPanel.opacity(0.75))
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
    }
}

// Cyber Neon Button Style
public struct CyberButtonStyle: ButtonStyle {
    public let color: Color
    public let glowEnabled: Bool
    
    public init(color: Color = GameTheme.neonPink, glowEnabled: Bool = true) {
        self.color = color
        self.glowEnabled = glowEnabled
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: color.opacity(glowEnabled && !configuration.isPressed ? 0.6 : 0.0), radius: 8)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
