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

// MARK: - Placeholder — Step 7'de NavigationRouter ile değiştirilecek
private struct MainTabView: View {
    var body: some View {
        TabView {
            Text("Feed")
                .tabItem { Label("Feed", systemImage: "house") }
            Text("Ara")
                .tabItem { Label("Ara", systemImage: "magnifyingglass") }
            Text("Keşfet")
                .tabItem { Label("Keşfet", systemImage: "compass.drawing") }
            DevProfileView()
                .tabItem { Label("Profil", systemImage: "person.circle") }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Dev profile — sadece Step 7'ye kadar

private struct DevProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var authVM = AuthViewModel()

    var body: some View {
        ZStack {
            GrippdBackground()
            VStack(spacing: GrippdTheme.Spacing.lg) {
                Spacer()

                if let user = appState.currentUser {
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(GrippdTheme.Colors.accent)
                        Text(user.displayName)
                            .font(GrippdTheme.Typography.title)
                            .foregroundStyle(.white)
                        Text("@\(user.username)")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }

                Spacer()

                GrippdSecondaryButton("Oturumu Kapat", icon: "rectangle.portrait.and.arrow.right") {
                    Task { await authVM.signOut(appState: appState) }
                }
                .padding(.horizontal, GrippdTheme.Spacing.xl)
                .padding(.bottom, GrippdTheme.Spacing.xxl)
            }
        }
        .preferredColorScheme(.dark)
    }
}
