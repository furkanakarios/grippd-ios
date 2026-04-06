import SwiftUI
import Supabase

@main
struct GrippdApp: App {

    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onOpenURL { url in
                    Task { await handleDeepLink(url) }
                }
        }
    }

    private func handleDeepLink(_ url: URL) async {
        // Supabase auth callback — parse token from URL fragment/query
        // URL format: grippd://auth#access_token=...&type=recovery
        // or:         grippd://auth?type=recovery&...
        let urlString = url.absoluteString

        let isRecovery = urlString.contains("type=recovery")
        let isEmailConfirm = urlString.contains("type=signup") || urlString.contains("type=email_change")

        do {
            try await SupabaseClientService.shared.client.auth.session(from: url)
        } catch {
            // session(from:) throws for recovery links — tokens are still set
        }

        await MainActor.run {
            if isRecovery {
                appState.isAuthenticated = false
                appState.pendingDeepLink = .passwordReset
            } else if isEmailConfirm {
                appState.isAuthenticated = true
            }
        }
    }
}
