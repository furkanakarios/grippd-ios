import Foundation
import Supabase

// MARK: - AdminUserSummary

struct AdminUserSummary: Identifiable {
    let id: UUID
    let username: String
    let displayName: String
    let avatarURL: URL?
    let planType: String          // "free" | "premium"
    var isBanned: Bool
    let isAdmin: Bool
    let logCount: Int
    let createdAt: Date

    var isPremium: Bool { planType == "premium" }
}

// MARK: - AdminUserService

@MainActor
final class AdminUserService {
    static let shared = AdminUserService()
    private let client = SupabaseClientService.shared.client
    private init() {}

    // MARK: - Fetch

    func fetchUsers(search: String? = nil) async throws -> [AdminUserSummary] {
        struct Row: Decodable {
            let id: String
            let username: String
            let displayName: String
            let avatarUrl: String?
            let planType: String
            let isBanned: Bool
            let isAdmin: Bool
            let createdAt: String
            let logCount: Int

            enum CodingKeys: String, CodingKey {
                case id, username
                case displayName = "display_name"
                case avatarUrl   = "avatar_url"
                case planType    = "plan_type"
                case isBanned    = "is_banned"
                case isAdmin     = "is_admin"
                case createdAt   = "created_at"
                case logCount    = "log_count"
            }
        }

        let params: [String: AnyJSON] = [
            "search_term": search.map { AnyJSON.string($0) } ?? AnyJSON.null
        ]

        let rows: [Row] = try await client
            .rpc("admin_get_users", params: params)
            .execute()
            .value

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return rows.map { row in
            AdminUserSummary(
                id: UUID(uuidString: row.id) ?? UUID(),
                username: row.username,
                displayName: row.displayName,
                avatarURL: row.avatarUrl.flatMap { URL(string: $0) },
                planType: row.planType,
                isBanned: row.isBanned,
                isAdmin: row.isAdmin,
                logCount: row.logCount,
                createdAt: formatter.date(from: row.createdAt) ?? Date()
            )
        }
    }

    // MARK: - Ban / Unban

    func setBanned(userID: UUID, banned: Bool) async throws {
        try await client
            .from("users")
            .update(["is_banned": banned])
            .eq("id", value: userID.uuidString)
            .execute()
    }

    // MARK: - Plan

    func setPlan(userID: UUID, plan: String) async throws {
        try await client
            .from("users")
            .update(["plan_type": plan])
            .eq("id", value: userID.uuidString)
            .execute()
    }
}
