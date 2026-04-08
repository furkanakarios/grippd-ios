import Foundation
import Supabase

// MARK: - Feed Activity

struct FeedActivity: Identifiable {
    let id: UUID
    let user: FeedUser
    let contentTitle: String
    let posterURL: URL?
    let contentType: Content.ContentType
    let contentKey: String           // "movie-123", "book-abc" — navigasyon için
    let watchedAt: Date
    let rating: Double?
    let emoji: String?
    let isRewatch: Bool
    var likeCount: Int
    var isLiked: Bool
    var commentCount: Int
}

struct FeedUser: Identifiable {
    let id: UUID
    let username: String
    let displayName: String
    let avatarURL: URL?
}

// MARK: - FeedService

@MainActor
final class FeedService {
    static let shared = FeedService()
    private let client = SupabaseClientService.shared.client

    private let pageSize = 20

    private init() {}

    func fetchFeed(page: Int = 0) async throws -> [FeedActivity] {
        guard let myID = try? await client.auth.session.user.id else { return [] }

        let rows: [FeedRow] = try await client
            .from("logs")
            .select("""
                id,
                watched_at,
                rating,
                emoji_reaction,
                is_rewatch,
                user:user_id(id, username, display_name, avatar_url),
                content:content_id(title, poster_url, content_type, tmdb_id, google_books_id)
            """)
            .in("user_id", values: followingIDs(myID: myID))
            .order("watched_at", ascending: false)
            .range(from: page * pageSize, to: (page + 1) * pageSize - 1)
            .execute()
            .value

        var activities = rows.compactMap { $0.toDomain() }

        // Like ve yorum verilerini batch olarak çek
        let logIDs = activities.map { $0.id }
        async let likeData = LikeService.shared.fetchLikeData(logIDs: logIDs, myID: myID)
        async let commentCounts = CommentService.shared.fetchCommentCounts(logIDs: logIDs)
        let (likes, comments) = await (likeData, commentCounts)

        for i in activities.indices {
            let id = activities[i].id
            if let data = likes[id] {
                activities[i].likeCount = data.count
                activities[i].isLiked = data.isLiked
            }
            activities[i].commentCount = comments[id] ?? 0
        }

        return activities
    }

    // Takip edilen kullanıcı ID'lerini çek
    private func followingIDs(myID: UUID) async -> [String] {
        struct Row: Decodable { let following_id: String }
        let rows: [Row] = (try? await client
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: myID.uuidString)
            .execute()
            .value) ?? []
        return rows.map { $0.following_id }
    }
}

// MARK: - Decodable Rows

private struct FeedRow: Decodable {
    let id: String
    let watchedAt: String
    let rating: Double?
    let emojiReaction: String?
    let isRewatch: Bool
    let user: UserSnippet?
    let content: ContentSnippet?

    enum CodingKeys: String, CodingKey {
        case id, rating, user, content
        case watchedAt = "watched_at"
        case emojiReaction = "emoji_reaction"
        case isRewatch = "is_rewatch"
    }

    struct UserSnippet: Decodable {
        let id: String
        let username: String
        let displayName: String?
        let avatarUrl: String?

        enum CodingKeys: String, CodingKey {
            case id, username
            case displayName = "display_name"
            case avatarUrl = "avatar_url"
        }
    }

    struct ContentSnippet: Decodable {
        let title: String
        let posterUrl: String?
        let contentType: String
        let tmdbId: Int?
        let googleBooksId: String?

        enum CodingKeys: String, CodingKey {
            case title
            case posterUrl = "poster_url"
            case contentType = "content_type"
            case tmdbId = "tmdb_id"
            case googleBooksId = "google_books_id"
        }
    }

    func toDomain() -> FeedActivity? {
        guard let user, let content else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: watchedAt) ?? Date()

        let contentType: Content.ContentType = switch content.contentType {
            case "movie":   .movie
            case "tv_show": .tv_show
            default:        .book
        }

        let contentKey: String = switch contentType {
            case .movie:   "movie-\(content.tmdbId ?? 0)"
            case .tv_show: "tv-\(content.tmdbId ?? 0)"
            case .book:    "book-\(content.googleBooksId ?? "")"
        }

        return FeedActivity(
            id: UUID(uuidString: id) ?? UUID(),
            user: FeedUser(
                id: UUID(uuidString: user.id) ?? UUID(),
                username: user.username,
                displayName: user.displayName ?? user.username,
                avatarURL: user.avatarUrl.flatMap { URL(string: $0) }
            ),
            contentTitle: content.title,
            posterURL: content.posterUrl.flatMap { URL(string: $0) },
            contentType: contentType,
            contentKey: contentKey,
            watchedAt: date,
            rating: rating,
            emoji: emojiReaction,
            isRewatch: isRewatch,
            likeCount: 0,
            isLiked: false,
            commentCount: 0
        )
    }
}
