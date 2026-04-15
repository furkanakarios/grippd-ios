import SwiftUI
import Auth
import UIKit

// MARK: - AppDelegate (APNs token callback)

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Token'ı hex string olarak sakla; login sonrası PushTokenService upload eder
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(hex, forKey: "apns_device_token")
        NotificationCenter.default.post(name: .didReceiveAPNSToken, object: deviceToken)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Simulator'da beklenen hata — ignore
    }
}

extension Notification.Name {
    static let didReceiveAPNSToken = Notification.Name("didReceiveAPNSToken")
}

@main
struct GrippdApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
