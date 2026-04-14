import Foundation
import UserNotifications
import UIKit
import Supabase

// MARK: - PushTokenService

@MainActor
final class PushTokenService {
    static let shared = PushTokenService()
    private let client = SupabaseClientService.shared.client
    private init() {}

    /// Push izni ister ve token'ı Supabase'e kaydeder.
    func registerIfNeeded(userID: UUID) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            if granted { await registerToken(userID: userID) }
        case .authorized, .provisional:
            await registerToken(userID: userID)
        default:
            break
        }
    }

    private func registerToken(userID: UUID) async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    /// AppDelegate/SceneDelegate'den çağrılır; token'ı DB'ye upsert eder.
    func saveToken(_ deviceToken: Data, userID: UUID) async {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        struct Payload: Encodable {
            let userId: String
            let token: String
            let platform: String
            let updatedAt: String
            enum CodingKeys: String, CodingKey {
                case userId     = "user_id"
                case token, platform
                case updatedAt  = "updated_at"
            }
        }
        let payload = Payload(
            userId: userID.uuidString,
            token: token,
            platform: "ios",
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        try? await client
            .from("device_tokens")
            .upsert(payload, onConflict: "user_id,token")
            .execute()
    }

    /// Çıkış yaparken token'ı sil.
    func removeToken(userID: UUID) async {
        guard let token = await currentToken() else { return }
        try? await client
            .from("device_tokens")
            .delete()
            .eq("user_id", value: userID.uuidString)
            .eq("token", value: token)
            .execute()
    }

    private func currentToken() async -> String? {
        // Kaydedilen son token'ı UserDefaults'tan okur
        UserDefaults.standard.string(forKey: "apns_device_token")
    }
}
