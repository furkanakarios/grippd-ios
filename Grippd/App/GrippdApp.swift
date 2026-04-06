import SwiftUI
import Auth

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
        let raw = url.absoluteString

        // Supabase PKCE ve legacy fragment formatlarının ikisini de kontrol et
        // PKCE:    grippd://auth?code=xxx&type=recovery
        // Legacy:  grippd://auth#access_token=xxx&type=recovery
        let combined = raw + (url.fragment ?? "")
        let isRecovery = combined.contains("type=recovery")

        do {
            // session(from:) hem PKCE code exchange hem de fragment token'ı handle eder
            let session = try await SupabaseClientService.shared.client.auth.session(from: url)
            await MainActor.run {
                if isRecovery {
                    // Recovery session kuruldu — şifre güncelleme ekranını göster
                    appState.pendingDeepLink = .passwordReset
                } else {
                    // Email confirm vs. — direkt giriş yap
                    appState.isAuthenticated = true
                }
                _ = session
            }
        } catch {
            // session(from:) bazen recovery'de throw eder ama token set edilmiş olur
            if isRecovery {
                await MainActor.run {
                    appState.pendingDeepLink = .passwordReset
                }
            }
        }
    }
}
