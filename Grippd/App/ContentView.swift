import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.pendingDeepLink == .passwordReset {
                PasswordResetView()
            } else if appState.isAuthenticated {
                if appState.needsOnboarding {
                    OnboardingView()
                } else {
                    MainTabView()
                }
            } else {
                SignInView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: appState.needsOnboarding)
        .animation(.easeInOut(duration: 0.3), value: appState.pendingDeepLink == nil)
    }
}
