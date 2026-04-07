import Foundation
import SwiftData

@MainActor
final class LocalCacheService {
    static let shared = LocalCacheService()

    private let container: ModelContainer

    private init() {
        let schema = Schema([CachedContent.self, CachedSearchQuery.self, UserCreatedContent.self, LogEntry.self, WatchlistEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("SwiftData container oluşturulamadı: \(error)")
        }
    }

    var context: ModelContext { container.mainContext }

    // MARK: - Content Cache

    func cachedContent(id: String) -> CachedContent? {
        let descriptor = FetchDescriptor<CachedContent>(
            predicate: #Predicate { $0.id == id }
        )
        let results = (try? context.fetch(descriptor)) ?? []
        guard let cached = results.first else { return nil }
        if cached.isExpired {
            context.delete(cached)
            return nil
        }
        return cached
    }

    func cacheContent(_ content: Content, ttl: TimeInterval = 86400) {
        let cacheID: String
        if let tmdbID = content.tmdbID {
            cacheID = CachedContent.cacheID(tmdbID: tmdbID, type: content.contentType)
        } else if let booksID = content.googleBooksID {
            cacheID = CachedContent.cacheID(googleBooksID: booksID)
        } else {
            cacheID = "user_\(content.id.uuidString)"
        }

        // Mevcut kaydı güncelle veya yeni ekle
        if let existing = cachedContent(id: cacheID) {
            context.delete(existing)
        }

        let cached = CachedContent(
            id: cacheID,
            tmdbID: content.tmdbID,
            googleBooksID: content.googleBooksID,
            title: content.title,
            originalTitle: content.originalTitle,
            overview: content.overview,
            posterURLString: content.posterURL?.absoluteString,
            backdropURLString: content.backdropURL?.absoluteString,
            releaseYear: content.releaseYear,
            contentTypeRaw: content.contentType.rawValue,
            genres: content.genres,
            averageRating: content.averageRating,
            runtime: content.runtime,
            isUserCreated: content.isUserCreated,
            ttl: ttl
        )
        context.insert(cached)
        try? context.save()
    }

    func cacheContents(_ contents: [Content], ttl: TimeInterval = 3600) {
        contents.forEach { cacheContent($0, ttl: ttl) }
    }

    // MARK: - Search Cache

    func cachedSearchResults(queryKey: String) -> [CachedContent]? {
        let descriptor = FetchDescriptor<CachedSearchQuery>(
            predicate: #Predicate { $0.queryKey == queryKey }
        )
        guard let query = (try? context.fetch(descriptor))?.first,
              !query.isExpired else { return nil }

        return query.ids.compactMap { cachedContent(id: $0) }
    }

    func cacheSearchResults(_ contents: [Content], queryKey: String, ttl: TimeInterval = 3600) {
        cacheContents(contents, ttl: ttl + 3600)

        let ids: [String] = contents.compactMap { content in
            if let tmdbID = content.tmdbID {
                return CachedContent.cacheID(tmdbID: tmdbID, type: content.contentType)
            } else if let booksID = content.googleBooksID {
                return CachedContent.cacheID(googleBooksID: booksID)
            }
            return nil
        }

        let descriptor = FetchDescriptor<CachedSearchQuery>(
            predicate: #Predicate { $0.queryKey == queryKey }
        )
        if let existing = (try? context.fetch(descriptor))?.first {
            context.delete(existing)
        }

        context.insert(CachedSearchQuery(queryKey: queryKey, resultIDs: ids, ttl: ttl))
        try? context.save()
    }

    // MARK: - Cleanup

    func clearExpired() {
        let now = Date()
        let contentDescriptor = FetchDescriptor<CachedContent>(
            predicate: #Predicate { $0.expiresAt < now }
        )
        let queryDescriptor = FetchDescriptor<CachedSearchQuery>(
            predicate: #Predicate { $0.expiresAt < now }
        )
        (try? context.fetch(contentDescriptor))?.forEach { context.delete($0) }
        (try? context.fetch(queryDescriptor))?.forEach { context.delete($0) }
        try? context.save()
    }

    func clearAll() {
        try? context.delete(model: CachedContent.self)
        try? context.delete(model: CachedSearchQuery.self)
        try? context.save()
    }
}
