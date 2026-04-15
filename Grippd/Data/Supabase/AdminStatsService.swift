import Foundation
import Supabase

// MARK: - AppStats

struct AppStats: Decodable {
    let totalUsers: Int
    let premiumUsers: Int
    let bannedUsers: Int
    let newUsers7d: Int
    let totalLogs: Int
    let newLogs7d: Int
    let totalComments: Int
    let pendingReports: Int
    let resolvedReports: Int
    let activeCollections: Int

    enum CodingKeys: String, CodingKey {
        case totalUsers        = "total_users"
        case premiumUsers      = "premium_users"
        case bannedUsers       = "banned_users"
        case newUsers7d        = "new_users_7d"
        case totalLogs         = "total_logs"
        case newLogs7d         = "new_logs_7d"
        case totalComments     = "total_comments"
        case pendingReports    = "pending_reports"
        case resolvedReports   = "resolved_reports"
        case activeCollections = "active_collections"
    }
}

// MARK: - AdminStatsService

@MainActor
final class AdminStatsService {
    static let shared = AdminStatsService()
    private let client = SupabaseClientService.shared.client
    private init() {}

    func fetchStats() async throws -> AppStats {
        try await client
            .rpc("admin_get_stats")
            .execute()
            .value
    }
}
