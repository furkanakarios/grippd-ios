import Foundation
import SwiftData

@MainActor
final class WatchlistService {
    static let shared = WatchlistService()

    private var context: ModelContext { LocalCacheService.shared.context }

    private init() {}

    // MARK: - Fetch

    func all() -> [WatchlistEntry] {
        let descriptor = FetchDescriptor<WatchlistEntry>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func entries(for contentType: Content.ContentType) -> [WatchlistEntry] {
        let raw = contentType.rawValue
        let descriptor = FetchDescriptor<WatchlistEntry>(
            predicate: #Predicate { $0.contentTypeRaw == raw },
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func isInWatchlist(_ contentKey: String) -> Bool {
        let descriptor = FetchDescriptor<WatchlistEntry>(
            predicate: #Predicate { $0.contentKey == contentKey }
        )
        return ((try? context.fetch(descriptor)) ?? []).isEmpty == false
    }

    // MARK: - Add / Remove / Toggle

    func add(contentKey: String, contentType: Content.ContentType, title: String, posterPath: String?) {
        guard !isInWatchlist(contentKey) else { return }
        let entry = WatchlistEntry(
            contentKey: contentKey,
            contentType: contentType,
            contentTitle: title,
            posterPath: posterPath
        )
        context.insert(entry)
        try? context.save()
    }

    func remove(_ contentKey: String) {
        let descriptor = FetchDescriptor<WatchlistEntry>(
            predicate: #Predicate { $0.contentKey == contentKey }
        )
        (try? context.fetch(descriptor))?.forEach { context.delete($0) }
        try? context.save()
    }

    @discardableResult
    func toggle(contentKey: String, contentType: Content.ContentType, title: String, posterPath: String?) -> Bool {
        if isInWatchlist(contentKey) {
            remove(contentKey)
            return false
        } else {
            add(contentKey: contentKey, contentType: contentType, title: title, posterPath: posterPath)
            return true
        }
    }
}
