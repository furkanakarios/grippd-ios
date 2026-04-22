import Foundation
import Supabase

/// Yerel LogEntry'leri Supabase'e senkronize eder.
/// Tüm işlemler fire-and-forget — UI'ı bloklamaz, hata olursa sessizce geçer.
@MainActor
final class LogSyncService {
    static let shared = LogSyncService()
    private let client = SupabaseClientService.shared.client

    private init() {}

    // MARK: - Public API

    /// Giriş sonrası remoteID'si olmayan (sync başarısız) logları tekrar dener.
    func syncPending() async {
        guard let userID = client.auth.currentUser?.id else { return }
        let pending = LogService.shared.allLogs().filter {
            $0.remoteID == nil && $0.ownerID == userID.uuidString
        }
        for entry in pending {
            await sync(entry)
        }
    }

    /// Giriş sonrası Supabase'deki tüm log'ları lokale çeker. Eksik olanları oluşturur.
    func fetchAllFromRemote(ownerID: String) async {
        struct RemoteContent: Decodable {
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
        struct RemoteLog: Decodable {
            let id: String
            let watchedAt: String
            let rating: Double?
            let emojiReaction: String?
            let isRewatch: Bool
            let notes: String?
            let content: RemoteContent
            enum CodingKeys: String, CodingKey {
                case id, rating, notes, content
                case watchedAt = "watched_at"
                case emojiReaction = "emoji_reaction"
                case isRewatch = "is_rewatch"
            }
        }

        do {
            let rows: [RemoteLog] = try await client
                .from("logs")
                .select("id, watched_at, rating, emoji_reaction, is_rewatch, notes, content:content_id(title, poster_url, content_type, tmdb_id, google_books_id)")
                .eq("user_id", value: ownerID)
                .order("watched_at", ascending: false)
                .execute()
                .value

            let existingRemoteIDs = Set(LogService.shared.allLogs().compactMap { $0.remoteID })
            let context = LocalCacheService.shared.context
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var didInsert = false

            for row in rows {
                guard !existingRemoteIDs.contains(row.id) else { continue }
                let c = row.content
                let contentKey: String
                if let tmdbID = c.tmdbId {
                    let prefix = c.contentType == "tv_show" ? "tv" : c.contentType
                    contentKey = "\(prefix)-\(tmdbID)"
                } else if let booksID = c.googleBooksId {
                    contentKey = "book-\(booksID)"
                } else { continue }

                guard let contentType = Content.ContentType(rawValue: c.contentType) else { continue }
                let watchedAt = formatter.date(from: row.watchedAt) ?? Date()

                let posterPath: String?
                if let url = c.posterUrl, url.contains("image.tmdb.org/t/p/w500") {
                    posterPath = String(url.dropFirst("https://image.tmdb.org/t/p/w500".count))
                } else {
                    posterPath = c.posterUrl
                }

                let entry = LogEntry(
                    ownerID: ownerID,
                    contentKey: contentKey,
                    contentType: contentType,
                    contentTitle: c.title,
                    posterPath: posterPath,
                    watchedAt: watchedAt,
                    isRewatch: row.isRewatch,
                    rating: row.rating,
                    emoji: row.emojiReaction,
                    note: row.notes
                )
                entry.remoteID = row.id
                context.insert(entry)
                didInsert = true
            }

            if didInsert {
                try? context.save()
                NotificationCenter.default.post(name: .logsDidSyncFromRemote, object: nil)
            }
        } catch {
            print("[LogSync] fetchAllFromRemote error: \(error)")
        }
    }

    /// Yeni log kaydedilince çağrılır. content upsert + log insert.
    func sync(_ entry: LogEntry) async {
        guard !entry.ownerID.isEmpty else { return }
        do {
            let contentID = try await upsertContent(entry: entry)
            let remoteID  = try await insertLog(entry: entry, contentID: contentID)
            entry.remoteID = remoteID
            try? LocalCacheService.shared.context.save()
        } catch {
            // Sessizce geç — yerel log zaten kaydedildi
            print("[LogSync] sync error: \(error)")
        }
    }

    /// Log güncellenince çağrılır.
    func update(_ entry: LogEntry) async {
        guard let remoteID = entry.remoteID else {
            // Remote kaydı yoksa yeniden sync et
            await sync(entry)
            return
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        struct Payload: Encodable {
            let watched_at: String
            let rating: Double?
            let emoji_reaction: String?
            let is_rewatch: Bool
            let notes: String?
        }
        do {
            try await client
                .from("logs")
                .update(Payload(
                    watched_at: formatter.string(from: entry.watchedAt),
                    rating: entry.rating,
                    emoji_reaction: entry.emoji,
                    is_rewatch: entry.isRewatch,
                    notes: entry.note
                ))
                .eq("id", value: remoteID)
                .execute()
        } catch {
            print("[LogSync] update error: \(error)")
        }
    }

    /// Log silinince çağrılır.
    func delete(_ entry: LogEntry) async {
        guard let remoteID = entry.remoteID else { return }
        do {
            try await client
                .from("logs")
                .delete()
                .eq("id", value: remoteID)
                .execute()
        } catch {
            print("[LogSync] delete error: \(error)")
        }
    }

    // MARK: - Content Upsert

    private func upsertContent(entry: LogEntry) async throws -> String {
        let parts = entry.contentKey.split(separator: "-", maxSplits: 1)
        guard parts.count == 2 else { throw SyncError.invalidContentKey }
        let typePrefix = String(parts[0])
        let externalID = String(parts[1])

        switch typePrefix {
        case "movie":
            guard let tmdbID = Int(externalID) else { throw SyncError.invalidContentKey }
            return try await upsertTMDB(
                tmdbID: tmdbID,
                contentType: "movie",
                title: entry.contentTitle,
                posterPath: entry.posterPath
            )
        case "tv":
            guard let tmdbID = Int(externalID) else { throw SyncError.invalidContentKey }
            return try await upsertTMDB(
                tmdbID: tmdbID,
                contentType: "tv_show",
                title: entry.contentTitle,
                posterPath: entry.posterPath
            )
        case "book":
            return try await upsertBook(
                googleBooksID: externalID,
                title: entry.contentTitle,
                posterPath: entry.posterPath
            )
        default:
            throw SyncError.invalidContentKey
        }
    }

    private func upsertTMDB(tmdbID: Int, contentType: String, title: String, posterPath: String?) async throws -> String {
        let posterURL = posterPath.map { "https://image.tmdb.org/t/p/w500\($0)" }

        struct Payload: Encodable {
            let tmdb_id: Int
            let content_type: String
            let title: String
            let poster_url: String?
        }
        struct Row: Decodable { let id: String }

        // Önce mevcut kaydı ara — upsert UPDATE tetiklediği için RLS'e takılıyor
        let existing: [Row] = (try? await client
            .from("content")
            .select("id")
            .eq("tmdb_id", value: tmdbID)
            .eq("content_type", value: contentType)
            .limit(1)
            .execute()
            .value) ?? []

        if let id = existing.first?.id { return id }

        // Yoksa insert et
        let rows: [Row] = try await client
            .from("content")
            .insert(Payload(tmdb_id: tmdbID, content_type: contentType, title: title, poster_url: posterURL))
            .select("id")
            .execute()
            .value

        guard let id = rows.first?.id else { throw SyncError.upsertFailed }
        return id
    }

    private func upsertBook(googleBooksID: String, title: String, posterPath: String?) async throws -> String {
        struct Row: Decodable { let id: String }

        // Önce mevcut kaydı ara
        let existing: [Row] = (try? await client
            .from("content")
            .select("id")
            .eq("google_books_id", value: googleBooksID)
            .limit(1)
            .execute()
            .value) ?? []

        if let id = existing.first?.id { return id }

        // Yoksa insert et
        struct Payload: Encodable {
            let google_books_id: String
            let content_type: String
            let title: String
            let poster_url: String?
        }

        let inserted: [Row] = try await client
            .from("content")
            .insert(Payload(google_books_id: googleBooksID, content_type: "book", title: title, poster_url: posterPath))
            .select("id")
            .execute()
            .value

        guard let id = inserted.first?.id else { throw SyncError.upsertFailed }
        return id
    }

    // MARK: - Log Insert

    private func insertLog(entry: LogEntry, contentID: String) async throws -> String {
        struct Payload: Encodable {
            let user_id: String
            let content_id: String
            let watched_at: String
            let rating: Double?
            let emoji_reaction: String?
            let is_rewatch: Bool
            let notes: String?
        }
        struct Row: Decodable { let id: String }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let rows: [Row] = try await client
            .from("logs")
            .insert(Payload(
                user_id: entry.ownerID,
                content_id: contentID,
                watched_at: formatter.string(from: entry.watchedAt),
                rating: entry.rating,
                emoji_reaction: entry.emoji,
                is_rewatch: entry.isRewatch,
                notes: entry.note
            ))
            .select("id")
            .execute()
            .value

        guard let id = rows.first?.id else { throw SyncError.insertFailed }
        return id
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let logsDidSyncFromRemote = Notification.Name("logsDidSyncFromRemote")
}

// MARK: - Errors

private enum SyncError: Error {
    case invalidContentKey
    case upsertFailed
    case insertFailed
}
