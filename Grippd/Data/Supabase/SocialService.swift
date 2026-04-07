import Foundation
import Supabase

// MARK: - Public Log (başka kullanıcının logu)

struct PublicLog: Identifiable {
    let id: UUID
    let contentTitle: String
    let posterURL: URL?
    let contentType: Content.ContentType
    let watchedAt: Date
    let rating: Double?
    let emoji: String?
}

// MARK: - User Profile Data

struct UserProfileData {
    let user: User
    let followerCount: Int
    let followingCount: Int
    let logCount: Int
    let recentLogs: [PublicLog]
}

// MARK: - SocialService

@MainActor
final class SocialService {
    static let shared = SocialService()
    private let client = SupabaseClientService.shared.client

    private init() {}

    // MARK: - Profile Fetch

    func fetchProfile(userID: UUID) async throws -> UserProfileData {
        async let userRows: [UserRow] = client
            .from("users")
            .select("id, username, display_name, avatar_url, banner_url, bio, is_private, plan_type, created_at")
            .eq("id", value: userID.uuidString)
            .limit(1)
            .execute()
            .value

        async let followerRows: [CountRow] = client
            .from("follows")
            .select("id", head: false, count: .exact)
            .eq("following_id", value: userID.uuidString)
            .execute()
            .value

        async let followingRows: [CountRow] = client
            .from("follows")
            .select("id", head: false, count: .exact)
            .eq("follower_id", value: userID.uuidString)
            .execute()
            .value

        async let logRows: [CountRow] = client
            .from("logs")
            .select("id", head: false, count: .exact)
            .eq("user_id", value: userID.uuidString)
            .execute()
            .value

        async let recentLogRows: [PublicLogRow] = client
            .from("logs")
            .select("id, watched_at, rating, emoji_reaction, content(title, poster_url, content_type)")
            .eq("user_id", value: userID.uuidString)
            .order("watched_at", ascending: false)
            .limit(12)
            .execute()
            .value

        let (users, followers, followings, logs, recentLogs) = try await (
            userRows, followerRows, followingRows, logRows, recentLogRows
        )

        guard let userRow = users.first else {
            throw SocialError.userNotFound
        }

        return UserProfileData(
            user: userRow.toDomain(),
            followerCount: followers.count,
            followingCount: followings.count,
            logCount: logs.count,
            recentLogs: recentLogs.compactMap { $0.toDomain() }
        )
    }

    func fetchProfile(username: String) async throws -> UserProfileData {
        let rows: [UserRow] = try await client
            .from("users")
            .select("id, username, display_name, avatar_url, banner_url, bio, is_private, plan_type, created_at")
            .eq("username", value: username)
            .limit(1)
            .execute()
            .value

        guard let row = rows.first, let id = UUID(uuidString: row.id) else {
            throw SocialError.userNotFound
        }

        return try await fetchProfile(userID: id)
    }

    // MARK: - Follower / Following Lists

    func fetchFollowers(userID: UUID) async throws -> [User] {
        let rows: [FollowWithUser] = try await client
            .from("follows")
            .select("follower:follower_id(id, username, display_name, avatar_url, banner_url, bio, is_private, plan_type, created_at)")
            .eq("following_id", value: userID.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return rows.compactMap { $0.follower?.toDomain() }
    }

    func fetchFollowing(userID: UUID) async throws -> [User] {
        let rows: [FollowWithFollowing] = try await client
            .from("follows")
            .select("following:following_id(id, username, display_name, avatar_url, banner_url, bio, is_private, plan_type, created_at)")
            .eq("follower_id", value: userID.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return rows.compactMap { $0.following?.toDomain() }
    }
}

// MARK: - Errors

enum SocialError: LocalizedError {
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .userNotFound: return "Kullanıcı bulunamadı."
        }
    }
}

// MARK: - Decodable Row Types

private struct CountRow: Decodable {
    let id: String
}

private struct PublicLogRow: Decodable {
    let id: String
    let watchedAt: String
    let rating: Double?
    let emojiReaction: String?
    let content: ContentSnippet?

    enum CodingKeys: String, CodingKey {
        case id, rating, content
        case watchedAt = "watched_at"
        case emojiReaction = "emoji_reaction"
    }

    struct ContentSnippet: Decodable {
        let title: String
        let posterUrl: String?
        let contentType: String

        enum CodingKeys: String, CodingKey {
            case title
            case posterUrl = "poster_url"
            case contentType = "content_type"
        }
    }

    func toDomain() -> PublicLog? {
        guard let content else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: watchedAt) ?? Date()
        let contentType: Content.ContentType = switch content.contentType {
            case "movie":   .movie
            case "tv_show": .tv_show
            default:        .book
        }
        return PublicLog(
            id: UUID(uuidString: id) ?? UUID(),
            contentTitle: content.title,
            posterURL: content.posterUrl.flatMap { URL(string: $0) },
            contentType: contentType,
            watchedAt: date,
            rating: rating,
            emoji: emojiReaction
        )
    }
}

private struct FollowWithUser: Decodable {
    let follower: UserRow?
}

private struct FollowWithFollowing: Decodable {
    let following: UserRow?
}
