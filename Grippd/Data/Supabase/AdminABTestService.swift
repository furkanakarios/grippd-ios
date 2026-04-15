import Foundation
import Supabase

// MARK: - ExperimentStat

struct ExperimentStat: Identifiable {
    let id: UUID
    let name: String
    let isActive: Bool
    let variantCounts: [String: Int]   // ["A": 120, "B": 118]

    var totalAssigned: Int { variantCounts.values.reduce(0, +) }
}

// MARK: - AdminABTestService

@MainActor
final class AdminABTestService {
    static let shared = AdminABTestService()
    private let client = SupabaseClientService.shared.client
    private init() {}

    func fetchExperiments() async throws -> [ABExperiment] {
        try await client
            .from("ab_experiments")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchStats() async throws -> [ExperimentStat] {
        struct Row: Decodable {
            let experimentId: UUID
            let experimentName: String
            let isActive: Bool
            let variant: String?
            let count: Int

            enum CodingKeys: String, CodingKey {
                case experimentId   = "experiment_id"
                case experimentName = "experiment_name"
                case isActive       = "is_active"
                case variant, count
            }
        }
        let rows: [Row] = try await client
            .rpc("admin_get_experiment_stats")
            .execute()
            .value

        // Satırları experiment bazında grupla
        var groups: [UUID: (name: String, isActive: Bool, counts: [String: Int])] = [:]
        for row in rows {
            let key = row.experimentId
            var entry = groups[key] ?? (row.experimentName, row.isActive, [:])
            if let variant = row.variant {
                entry.counts[variant] = row.count
            }
            groups[key] = entry
        }
        return groups.map { id, data in
            ExperimentStat(id: id, name: data.name, isActive: data.isActive, variantCounts: data.counts)
        }.sorted { $0.name < $1.name }
    }

    func createExperiment(name: String, description: String, variants: [String]) async throws {
        struct Payload: Encodable {
            let name: String
            let description: String
            let variants: [String]
        }
        try await client
            .from("ab_experiments")
            .insert(Payload(name: name, description: description, variants: variants))
            .execute()
    }

    func setActive(_ id: UUID, active: Bool) async throws {
        try await client
            .from("ab_experiments")
            .update(["is_active": active])
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteExperiment(_ id: UUID) async throws {
        try await client
            .from("ab_experiments")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
