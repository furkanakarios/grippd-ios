import SwiftUI
import RevenueCatUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isCheckingAuth {
                SplashView()
            } else if appState.pendingDeepLink == .passwordReset {
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
        .animation(.easeInOut(duration: 0.5), value: appState.isCheckingAuth)
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: appState.needsOnboarding)
        .animation(.easeInOut(duration: 0.3), value: appState.pendingDeepLink == nil)
        .sheet(isPresented: Binding(
            get: { appState.showPaywall },
            set: { appState.showPaywall = $0 }
        )) {
            PaywallView()
                .onPurchaseCompleted { _ in
                    appState.showPaywall = false
                    appState.isPremium = true
                    // DB plan_type senkronu RevenueCat webhook (Edge Function) ile yapılır.
                }
                .onRestoreCompleted { _ in
                    appState.showPaywall = false
                    appState.isPremium = true
                    // DB plan_type senkronu RevenueCat webhook (Edge Function) ile yapılır.
                }
        }
        .task { await checkAuth() }
    }

    private func checkAuth() async {
        let start = Date()

        // Session kontrolü
        let vm = AuthViewModel()
        await vm.restoreSession(appState: appState)

        // Animasyon bitene kadar splash'ta kal — SplashView.totalDuration ile senkron
        let elapsed = Date().timeIntervalSince(start)
        let remaining = SplashView.totalDuration - elapsed
        if remaining > 0 {
            try? await Task.sleep(for: .seconds(remaining))
        }

        await MainActor.run {
            appState.isCheckingAuth = false
        }
    }
}
