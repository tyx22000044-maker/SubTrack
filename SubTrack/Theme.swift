import SwiftUI
import UIKit

// MARK: - UIColor hex helper (private)
private extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: CGFloat(a)/255)
    }
}

// MARK: - Adaptive App Colors (Light / Dark)
extension Color {
    // Static hex for subscription icons and brand accents
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }

    // Dynamic colors — automatically reflect preferredColorScheme
    static let appBackground = Color(uiColor: UIColor(dynamicProvider: {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "10141a") : UIColor(hex: "F2F4F8")
    }))
    static let appSurface = Color(uiColor: UIColor(dynamicProvider: {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "1c2026") : UIColor(hex: "FFFFFF")
    }))
    static let appSurfaceContainer = Color(uiColor: UIColor(dynamicProvider: {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "262a31") : UIColor(hex: "E8EBF0")
    }))
    static let appSurfaceHigh = Color(uiColor: UIColor(dynamicProvider: {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "31353c") : UIColor(hex: "DDE0E8")
    }))
    static let appPrimary = Color(uiColor: UIColor(dynamicProvider: {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "adc6ff") : UIColor(hex: "005BC1")
    }))
    static let appSecondary = Color(uiColor: UIColor(dynamicProvider: {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "ffb4aa") : UIColor(hex: "C5000B")
    }))
    static let appTertiary = Color(uiColor: UIColor(dynamicProvider: {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "ffb874") : UIColor(hex: "874D00")
    }))
    static let appOnSurface = Color(uiColor: UIColor(dynamicProvider: {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "dfe2eb") : UIColor(hex: "10141a")
    }))
    static let appOnSurfaceVariant = Color(uiColor: UIColor(dynamicProvider: {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "c1c6d7") : UIColor(hex: "42474F")
    }))
    static let appOutline = Color(uiColor: UIColor(dynamicProvider: {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "8b90a0") : UIColor(hex: "72777F")
    }))
    static let appOutlineVariant = Color(uiColor: UIColor(dynamicProvider: {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "414755") : UIColor(hex: "C2C7CF")
    }))
    // Primary foreground — dark blue on light primary, white on dark primary
    static let appOnPrimary = Color(uiColor: UIColor(dynamicProvider: {
        $0.userInterfaceStyle == .dark ? UIColor(hex: "001a41") : UIColor.white
    }))
}

// MARK: - Glass Card (adapts to color scheme)
struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var scheme
    var cornerRadius: CGFloat = 16
    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.07),
                            lineWidth: 0.5
                        )
                )
        )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
    func formFieldStyle() -> some View {
        self.font(.system(size: 15)).foregroundColor(Color.appOnSurface)
    }
}
