import Foundation
import Supabase

/// CustomList ve CustomListItem'ları Supabase'e senkronize eder.
/// Tüm işlemler fire-and-forget — UI'ı bloklamaz, hata olursa sessizce geçer.
@MainActor
final class ListSyncService {
    static let shared = ListSyncService()
    private let client = SupabaseClientService.shared.client

    private init() {}

    // MARK: - List Sync

    func syncList(_ list: CustomList) async {
        guard let userID = client.auth.currentUser?.id else { return }
        struct ListPayload: Encodable {
            let id: String
            let user_id: String
            let name: String
            let description: String
            let list_type: String
            let is_public: Bool
            let is_default: Bool
        }
        do {
            try await client
                .from("lists")
                .upsert(
                    ListPayload(
                        id: list.id,
                        user_id: userID.uuidString,
                        name: list.name,
                        description: list.emoji,
                        list_type: "custom",
                        is_public: true,
                        is_default: false
                    ),
                    onConflict: "id"
                )
                .execute()

            for item in list.items {
                await syncItem(listID: list.id, item: item)
            }
        } catch {
            print("[ListSync] syncList error: \(error)")
        }
    }

    func deleteList(listID: String) async {
        do {
            try await client
                .from("lists")
                .delete()
                .eq("id", value: listID)
                .execute()
        } catch {
            print("[ListSync] deleteList error: \(error)")
        }
    }

    // MARK: - Item Sync

    func syncItem(listID: String, item: CustomListItem) async {
        guard let contentID = await getContentID(
            contentKey: item.contentKey,
            title: item.contentTitle,
            posterPath: item.posterPath
        ) else { return }

        struct ItemPayload: Encodable {
            let list_id: String
            let content_id: String
        }
        do {
            try await client
                .from("list_items")
                .upsert(ItemPayload(list_id: listID, content_id: contentID), onConflict: "list_id,content_id")
                .execute()
        } catch {
            print("[ListSync] syncItem error: \(error)")
        }
    }

    func removeItem(listID: String, contentKey: String) async {
        guard let contentID = await getContentID(contentKey: contentKey, title: "", posterPath: nil) else { return }
        do {
            try await client
                .from("list_items")
                .delete()
                .eq("list_id", value: listID)
                .eq("content_id", value: contentID)
                .execute()
        } catch {
            print("[ListSync] removeItem error: \(error)")
        }
    }

    // MARK: - Content Lookup/Create

    private func getContentID(contentKey: String, title: String, posterPath: String?) async -> String? {
        let parts = contentKey.split(separator: "-", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        let typePrefix = String(parts[0])
        let externalID = String(parts[1])

        do {
            switch typePrefix {
            case "movie":
                guard let tmdbID = Int(externalID) else { return nil }
                return try await getOrCreateTMDB(tmdbID: tmdbID, contentType: "movie", title: title, posterPath: posterPath)
            case "tv":
                guard let tmdbID = Int(externalID) else { return nil }
                return try await getOrCreateTMDB(tmdbID: tmdbID, contentType: "tv_show", title: title, posterPath: posterPath)
            case "book":
                return try await getOrCreateBook(googleBooksID: externalID, title: title, posterPath: posterPath)
            default:
                return nil
            }
        } catch {
            return nil
        }
    }

    private func getOrCreateTMDB(tmdbID: Int, contentType: String, title: String, posterPath: String?) async throws -> String {
        struct Row: Decodable { let id: String }
        let existing: [Row] = (try? await client
            .from("content")
            .select("id")
            .eq("tmdb_id", value: tmdbID)
            .eq("content_type", value: contentType)
            .limit(1)
            .execute()
            .value) ?? []

        if let row = existing.first { return row.id }

        let posterURL = posterPath.map { "https://image.tmdb.org/t/p/w500\($0)" }
        struct Payload: Encodable { let tmdb_id: Int; let content_type, title: String; let poster_url: String? }
        let inserted: [Row] = try await client
            .from("content")
            .insert(Payload(tmdb_id: tmdbID, content_type: contentType, title: title, poster_url: posterURL))
            .select("id")
            .execute()
            .value

        guard let id = inserted.first?.id else { throw ListSyncError.insertFailed }
        return id
    }

    private func getOrCreateBook(googleBooksID: String, title: String, posterPath: String?) async throws -> String {
        struct Row: Decodable { let id: String }
        let existing: [Row] = (try? await client
            .from("content")
            .select("id")
            .eq("google_books_id", value: googleBooksID)
            .limit(1)
            .execute()
            .value) ?? []

        if let row = existing.first { return row.id }

        struct Payload: Encodable { let google_books_id, content_type, title: String; let poster_url: String? }
        let inserted: [Row] = try await client
            .from("content")
            .insert(Payload(google_books_id: googleBooksID, content_type: "book", title: title, poster_url: posterPath))
            .select("id")
            .execute()
            .value

        guard let id = inserted.first?.id else { throw ListSyncError.insertFailed }
        return id
    }
}

// MARK: - Errors

private enum ListSyncError: Error {
    case insertFailed
}
