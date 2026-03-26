import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "10141a").ignoresSafeArea()

            VStack(spacing: 20) {
                // App Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "adc6ff"), Color(hex: "6e9cff")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                        .shadow(color: Color(hex: "adc6ff").opacity(0.35), radius: 24, y: 8)

                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(Color(hex: "001a41"))
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // Wordmark
                VStack(spacing: 6) {
                    Text("SubTrack")
                        .font(.system(size: 38, weight: .bold, design: .default))
                        .foregroundColor(.white)
                    Text("智能订阅管理")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "8b90a0"))
                        .tracking(2)
                }
                .opacity(textOpacity)
            }

            // Bottom tagline
            VStack {
                Spacer()
                Text("让每一笔订阅都值得")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "414755"))
                    .padding(.bottom, 48)
            }
            .opacity(taglineOpacity)
        }
        .onAppear { animate() }
    }

    private func animate() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            textOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.55)) {
            taglineOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onFinished()
        }
    }
}
