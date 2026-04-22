import Foundation
import Supabase

final class FollowService {
    static let shared = FollowService()
    private let client = SupabaseClientService.shared.client

    private init() {}

    // MARK: - Follow

    func follow(targetUserID: UUID) async throws {
        guard let currentUserID = client.auth.currentUser?.id else { return }
        struct Payload: Encodable {
            let follower_id: String
            let following_id: String
        }
        try await client
            .from("follows")
            .insert(Payload(follower_id: currentUserID.uuidString,
                            following_id: targetUserID.uuidString))
            .execute()
    }

    // MARK: - Unfollow

    func unfollow(targetUserID: UUID) async throws {
        guard let currentUserID = client.auth.currentUser?.id else { return }
        try await client
            .from("follows")
            .delete()
            .eq("follower_id", value: currentUserID.uuidString)
            .eq("following_id", value: targetUserID.uuidString)
            .execute()
    }

    // MARK: - Search Users

    func searchUsers(query: String) async throws -> [User] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let rows: [UserRow] = try await client
            .from("users")
            .select()
            .or("username.ilike.%\(query)%,display_name.ilike.%\(query)%")
            .limit(20)
            .execute()
            .value
        return rows.map { $0.toDomain() }
    }

    // MARK: - isFollowing

    func isFollowing(targetUserID: UUID) async throws -> Bool {
        guard let currentUserID = client.auth.currentUser?.id else { return false }
        struct Row: Decodable { let id: String }
        let rows: [Row] = try await client
            .from("follows")
            .select("id")
            .eq("follower_id", value: currentUserID.uuidString)
            .eq("following_id", value: targetUserID.uuidString)
            .limit(1)
            .execute()
            .value
        return !rows.isEmpty
    }
}
