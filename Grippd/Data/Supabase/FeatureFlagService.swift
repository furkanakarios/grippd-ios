import Foundation
import Supabase

// MARK: - FeatureFlag

struct FeatureFlag: Identifiable, Decodable {
    let id: UUID
    let key: String
    let description: String
    var isEnabled: Bool
    let audience: String   // "all" | "premium" | "admin"
    let updatedAt: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, key, description, audience
        case isEnabled  = "is_enabled"
        case updatedAt  = "updated_at"
        case createdAt  = "created_at"
    }
}

// MARK: - FeatureFlagService

/// Uygulama genelinde feature flag okuma.
/// Başlatma sırasında fetchAll() çağrılır; sonrası isEnabled(key:) ile senkron erişim.
@MainActor
final class FeatureFlagService {
    static let shared = FeatureFlagService()
    private let client = SupabaseClientService.shared.client
    private var flags: [String: FeatureFlag] = [:]
    private init() {}

    /// Tüm flagleri DB'den çek ve cache'e yaz. App açılışında çağrılır.
    func fetchAll() async {
        guard let fetched = try? await client
            .from("feature_flags")
            .select()
            .execute()
            .value as [FeatureFlag]
        else { return }
        flags = Dictionary(uniqueKeysWithValues: fetched.map { ($0.key, $0) })
    }

    /// Flag aktif mi? audience kontrolü de yapar.
    /// - `isPremium`: kullanıcının premium olup olmadığı
    /// - `isAdmin`: kullanıcının admin olup olmadığı
    func isEnabled(_ key: String, isPremium: Bool = false, isAdmin: Bool = false) -> Bool {
        guard let flag = flags[key], flag.isEnabled else { return false }
        switch flag.audience {
        case "premium": return isPremium || isAdmin
        case "admin":   return isAdmin
        default:        return true
        }
    }

    /// Cache'i temizle (oturum kapanınca)
    func clearCache() { flags.removeAll() }
}
