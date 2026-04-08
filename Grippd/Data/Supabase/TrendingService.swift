import Foundation
import Supabase

// MARK: - Trending Item

struct TrendingItem: Decodable, Identifiable {
    let contentId: String
    let logCount: Int
    let title: String
    let posterUrl: String?
    let contentType: String
    let tmdbId: Int?
    let googleBooksId: String?

    enum CodingKeys: String, CodingKey {
        case contentId    = "content_id"
        case logCount     = "log_count"
        case title
        case posterUrl    = "poster_url"
        case contentType  = "content_type"
        case tmdbId       = "tmdb_id"
        case googleBooksId = "google_books_id"
    }

    var id: String { contentId }

    var posterURL: URL? { posterUrl.flatMap { URL(string: $0) } }

    var resolvedContentType: Content.ContentType {
        switch contentType {
        case "movie":   return .movie
        case "tv_show": return .tv_show
        default:        return .book
        }
    }
}

// MARK: - Trending User

struct TrendingUser: Decodable, Identifiable {
    let userId: String
    let username: String
    let displayName: String
    let avatarUrl: String?
    let logCount: Int

    enum CodingKeys: String, CodingKey {
        case userId      = "user_id"
        case username
        case displayName = "display_name"
        case avatarUrl   = "avatar_url"
        case logCount    = "log_count"
    }

    var id: String { userId }
    var avatarURL: URL? { avatarUrl.flatMap { URL(string: $0) } }
    var userUUID: UUID? { UUID(uuidString: userId) }
}

// MARK: - Service

@MainActor
final class TrendingService {
    static let shared = TrendingService()
    private let client = SupabaseClientService.shared.client
    private init() {}

    /// Son 7 günde Grippd kullanıcılarının en çok log attığı içerikler
    func fetchTrending(limit: Int = 12) async -> [TrendingItem] {
        do {
            let items: [TrendingItem] = try await client
                .rpc("get_trending_content", params: ["limit_count": limit])
                .execute()
                .value
            return items
        } catch {
            return []
        }
    }

    /// Son 7 günde en aktif kullanıcılar (log sayısına göre)
    func fetchTrendingUsers(limit: Int = 10) async -> [TrendingUser] {
        do {
            let users: [TrendingUser] = try await client
                .rpc("get_trending_users", params: ["limit_count": limit])
                .execute()
                .value
            return users
        } catch {
            return []
        }
    }
}
