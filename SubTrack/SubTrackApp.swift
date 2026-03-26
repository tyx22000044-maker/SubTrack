import SwiftUI

@main
struct SubTrackApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app loads in background — zero extra wait time after splash
                ContentView()

                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
    }
}
