import Foundation
import Supabase

@MainActor
final class FollowService {
    static let shared = FollowService()
    private let client = SupabaseClientService.shared.client

    private init() {}

    // MARK: - Follow / Unfollow

    func follow(targetUserID: UUID) async throws {
        guard let myID = try? await client.auth.session.user.id else { return }
        struct Payload: Encodable {
            let follower_id: String
            let following_id: String
        }
        try await client
            .from("follows")
            .insert(Payload(follower_id: myID.uuidString, following_id: targetUserID.uuidString))
            .execute()
    }

    func unfollow(targetUserID: UUID) async throws {
        guard let myID = try? await client.auth.session.user.id else { return }
        try await client
            .from("follows")
            .delete()
            .eq("follower_id", value: myID.uuidString)
            .eq("following_id", value: targetUserID.uuidString)
            .execute()
    }

    func isFollowing(targetUserID: UUID) async -> Bool {
        guard let myID = try? await client.auth.session.user.id else { return false }
        struct Row: Decodable { let id: String }
        let rows: [Row] = (try? await client
            .from("follows")
            .select("id")
            .eq("follower_id", value: myID.uuidString)
            .eq("following_id", value: targetUserID.uuidString)
            .limit(1)
            .execute()
            .value) ?? []
        return !rows.isEmpty
    }

    // MARK: - User Search

    func searchUsers(query: String) async throws -> [User] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let rows: [UserRow] = try await client
            .from("users")
            .select("id, username, display_name, avatar_url, banner_url, bio, is_private, plan_type, created_at")
            .or("username.ilike.%\(query)%,display_name.ilike.%\(query)%")
            .limit(20)
            .execute()
            .value
        return rows.map { $0.toDomain() }
    }
}
