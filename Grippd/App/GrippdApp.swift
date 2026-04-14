import SwiftUI
import Auth

@main
struct GrippdApp: App {

    @State private var appState = AppState()

    init() {
        PurchaseService.configure()
        configureURLCache()
    }

    private func configureURLCache() {
        // 50 MB memory + 200 MB disk — helps CachedAsyncImage HTTP requests
        // and any other URLSession calls avoid redundant re-downloads.
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024
        )
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
