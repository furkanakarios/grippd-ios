import Foundation
import Supabase

// MARK: - Domain Model

struct AppNotification: Identifiable {
    let id: UUID
    let type: NotificationType
    let actor: NotificationActor
    let logID: UUID?
    let commentID: UUID?
    let isRead: Bool
    let createdAt: Date

    enum NotificationType: String {
        case follow
        case like = "like_log"
        case comment
    }
}

struct NotificationActor: Identifiable {
    let id: UUID
    let username: String
    let displayName: String
    let avatarURL: URL?
}

// MARK: - Service

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private let client = SupabaseClientService.shared.client

    private init() {}

    // MARK: - Fetch

    func fetchNotifications(limit: Int = 50) async throws -> [AppNotification] {
        struct Row: Decodable {
            let id: String
            let type: String
            let logId: String?
            let commentId: String?
            let isRead: Bool
            let createdAt: String
            let actor: ActorSnippet

            enum CodingKeys: String, CodingKey {
                case id, type, actor
                case logId = "log_id"
                case commentId = "comment_id"
                case isRead = "is_read"
                case createdAt = "created_at"
            }

            struct ActorSnippet: Decodable {
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
        }

        let rows: [Row] = try await client
            .from("notifications")
            .select("id, type, log_id, comment_id, is_read, created_at, actor:actor_id(id, username, display_name, avatar_url)")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return rows.compactMap { row in
            guard let notifID = UUID(uuidString: row.id),
                  let actorID = UUID(uuidString: row.actor.id),
                  let type = AppNotification.NotificationType(rawValue: row.type) else { return nil }

            return AppNotification(
                id: notifID,
                type: type,
                actor: NotificationActor(
                    id: actorID,
                    username: row.actor.username,
                    displayName: row.actor.displayName ?? row.actor.username,
                    avatarURL: row.actor.avatarUrl.flatMap { URL(string: $0) }
                ),
                logID: row.logId.flatMap { UUID(uuidString: $0) },
                commentID: row.commentId.flatMap { UUID(uuidString: $0) },
                isRead: row.isRead,
                createdAt: formatter.date(from: row.createdAt) ?? Date()
            )
        }
    }

    // MARK: - Unread Count

    func unreadCount() async -> Int {
        struct Row: Decodable { let id: String }
        let rows: [Row] = (try? await client
            .from("notifications")
            .select("id")
            .eq("is_read", value: false)
            .execute()
            .value) ?? []
        return rows.count
    }

    // MARK: - Log Content Fetch (navigasyon için)

    struct LogContentInfo {
        let contentType: Content.ContentType
        let tmdbID: Int?
        let googleBooksID: String?
    }

    func fetchLogContent(logID: UUID) async -> LogContentInfo? {
        struct Row: Decodable {
            let content: ContentSnippet
            struct ContentSnippet: Decodable {
                let contentType: String
                let tmdbId: Int?
                let googleBooksId: String?
                enum CodingKeys: String, CodingKey {
                    case contentType = "content_type"
                    case tmdbId = "tmdb_id"
                    case googleBooksId = "google_books_id"
                }
            }
        }
        let rows: [Row] = (try? await client
            .from("logs")
            .select("content:content_id(content_type, tmdb_id, google_books_id)")
            .eq("id", value: logID.uuidString)
            .limit(1)
            .execute()
            .value) ?? []

        guard let row = rows.first else { return nil }
        let ct: Content.ContentType = switch row.content.contentType {
            case "movie":   .movie
            case "tv_show": .tv_show
            default:        .book
        }
        return LogContentInfo(
            contentType: ct,
            tmdbID: row.content.tmdbId,
            googleBooksID: row.content.googleBooksId
        )
    }

    // MARK: - Mark Read

    func markAllRead() async {
        try? await client
            .from("notifications")
            .update(["is_read": true])
            .eq("is_read", value: false)
            .execute()
    }

    func markRead(notificationID: UUID) async {
        try? await client
            .from("notifications")
            .update(["is_read": true])
            .eq("id", value: notificationID.uuidString)
            .execute()
    }
}
