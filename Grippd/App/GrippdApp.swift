import SwiftUI
import Auth

@main
struct GrippdApp: App {

    @State private var appState = AppState()

    init() {
        PurchaseService.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onOpenURL { url in
                    Task { await handleDeepLink(url) }
                }
                .task {
                    // Süresi dolmuş cache kayıtlarını temizle
                    LocalCacheService.shared.clearExpired()
                }
        }
    }

    private func handleDeepLink(_ url: URL) async {
        // grippd://auth/recovery → şifre sıfırlama
        // grippd://auth          → diğer auth callback'leri (email confirm vs.)
        let isRecovery = url.host == "auth" && url.path == "/recovery"

        do {
            try await SupabaseClientService.shared.client.auth.session(from: url)
        } catch {
            // PKCE exchange bazen throw eder ama session set edilmiş olur
        }

        await MainActor.run {
            if isRecovery {
                appState.pendingDeepLink = .passwordReset
            } else {
                appState.isAuthenticated = true
            }
        }
    }
}
