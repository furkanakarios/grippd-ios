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

        let rows: [Row] = try await client
            .from("content")
            .upsert(
                Payload(tmdb_id: tmdbID, content_type: contentType, title: title, poster_url: posterURL),
                onConflict: "tmdb_id,content_type"
            )
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

// MARK: - Errors

private enum SyncError: Error {
    case invalidContentKey
    case upsertFailed
    case insertFailed
}
