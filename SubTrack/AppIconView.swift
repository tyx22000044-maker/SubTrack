import SwiftUI

/// SubTrack App Icon design — 1024×1024
/// To export: run this preview, take screenshot, crop to 1024×1024, drag into
/// Xcode → Assets.xcassets → AppIcon → 1024pt slot
struct AppIconView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0d1117"), Color(hex: "10141a")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle glow
            Circle()
                .fill(Color(hex: "adc6ff").opacity(0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -30, y: -40)

            // Center icon group
            VStack(spacing: 10) {
                // Bar chart icon
                HStack(alignment: .bottom, spacing: 7) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: "adc6ff").opacity(0.4))
                        .frame(width: 22, height: 52)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: "adc6ff").opacity(0.65))
                        .frame(width: 22, height: 76)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: "adc6ff"))
                        .frame(width: 22, height: 96)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: "adc6ff").opacity(0.55))
                        .frame(width: 22, height: 64)
                }

                // Wordmark
                Text("SubTrack")
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .tracking(1)
            }
        }
        .frame(width: 512, height: 512)
        .clipShape(RoundedRectangle(cornerRadius: 115)) // iOS icon rounding at 512pt
    }
}

#Preview("App Icon 512pt") {
    AppIconView()
        .frame(width: 512, height: 512)
}
