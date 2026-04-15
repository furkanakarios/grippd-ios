import Foundation
import Supabase
import CryptoKit

// MARK: - ABExperiment

struct ABExperiment: Identifiable, Decodable {
    let id: UUID
    let name: String
    let description: String
    let variants: [String]
    let isActive: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, variants
        case isActive  = "is_active"
        case createdAt = "created_at"
    }
}

// MARK: - ABTestService

/// Kullanıcıya deterministik varyant atar.
/// Aynı userID + experimentName kombinasyonu her zaman aynı varyantı döner.
/// Aktif deney yoksa veya kullanıcı atanmamışsa nil döner — mevcut davranış değişmez.
@MainActor
final class ABTestService {
    static let shared = ABTestService()
    private let client = SupabaseClientService.shared.client

    /// Bellek cache — oturum boyunca DB çağrısı tekrarlanmaz
    private var cache: [String: String] = [:]

    private init() {}

    /// Kullanıcının bir deney için varyantını döner.
    /// Henüz atanmamışsa DB'ye yazar; deney aktif değilse nil döner.
    func variant(for experimentName: String, userID: UUID) async -> String? {
        let cacheKey = "\(experimentName):\(userID)"
        if let cached = cache[cacheKey] { return cached }

        // DB'de mevcut atama var mı?
        struct AssignmentRow: Decodable {
            let variant: String
        }
        if let row = try? await client
            .from("ab_assignments")
            .select("variant")
            .eq("user_id", value: userID.uuidString)
            .execute()
            .value as [AssignmentRow],
           let first = row.first {
            cache[cacheKey] = first.variant
            return first.variant
        }

        // Deney aktif mi?
        struct ExperimentRow: Decodable {
            let id: String
            let variants: [String]
        }
        guard let experiments = try? await client
            .from("ab_experiments")
            .select("id, variants")
            .eq("name", value: experimentName)
            .eq("is_active", value: true)
            .limit(1)
            .execute()
            .value as [ExperimentRow],
              let experiment = experiments.first,
              !experiment.variants.isEmpty
        else { return nil }

        // Deterministik hash ile varyant seç
        let assigned = deterministicVariant(
            userID: userID,
            experimentName: experimentName,
            variants: experiment.variants
        )

        // DB'ye yaz
        struct Payload: Encodable {
            let experimentId: String
            let userId: String
            let variant: String
            enum CodingKeys: String, CodingKey {
                case experimentId = "experiment_id"
                case userId       = "user_id"
                case variant
            }
        }
        try? await client
            .from("ab_assignments")
            .upsert(Payload(experimentId: experiment.id, userId: userID.uuidString, variant: assigned),
                    onConflict: "experiment_id,user_id")
            .execute()

        cache[cacheKey] = assigned
        return assigned
    }

    /// Oturum kapanınca cache temizle
    func clearCache() { cache.removeAll() }

    // MARK: - Deterministik Hash

    private func deterministicVariant(userID: UUID, experimentName: String, variants: [String]) -> String {
        let input = "\(userID.uuidString):\(experimentName)"
        let digest = SHA256.hash(data: Data(input.utf8))
        let hashValue = digest.withUnsafeBytes { $0.load(as: UInt64.self) }
        let index = Int(hashValue % UInt64(variants.count))
        return variants[index]
    }
}
