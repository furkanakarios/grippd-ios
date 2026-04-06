import Foundation
import SwiftData

@MainActor
final class LogService {
    static let shared = LogService()

    private var context: ModelContext { LocalCacheService.shared.context }

    private init() {}

    // MARK: - Fetch

    /// Belirli bir içeriğe ait tüm log kayıtları (en yeni önce)
    func logs(for contentKey: String) -> [LogEntry] {
        let descriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate { $0.contentKey == contentKey },
            sortBy: [SortDescriptor(\.watchedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Tüm log kayıtları (en yeni önce)
    func allLogs() -> [LogEntry] {
        let descriptor = FetchDescriptor<LogEntry>(
            sortBy: [SortDescriptor(\.watchedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Belirli bir içerik türündeki loglar
    func logs(for contentType: Content.ContentType) -> [LogEntry] {
        let raw = contentType.rawValue
        let descriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate { $0.contentTypeRaw == raw },
            sortBy: [SortDescriptor(\.watchedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Kullanıcı bu içeriği daha önce logladı mı?
    func isLogged(contentKey: String) -> Bool {
        !logs(for: contentKey).isEmpty
    }

    /// Bu içerik için en son log kaydı
    func latestLog(for contentKey: String) -> LogEntry? {
        logs(for: contentKey).first
    }

    // MARK: - Save / Delete

    func save(_ entry: LogEntry) {
        context.insert(entry)
        try? context.save()
    }

    func delete(_ entry: LogEntry) {
        context.delete(entry)
        try? context.save()
    }

    func deleteAll(for contentKey: String) {
        logs(for: contentKey).forEach { context.delete($0) }
        try? context.save()
    }

    // MARK: - Stats

    struct LogStats {
        let totalMovies: Int
        let totalShows: Int
        let totalBooks: Int
        let totalWatchTime: Int     // dakika
        let averageRating: Double?
    }

    func stats() -> LogStats {
        let all = allLogs()
        let movies = all.filter { $0.contentType == .movie }
        let shows  = all.filter { $0.contentType == .tv_show }
        let books  = all.filter { $0.contentType == .book }

        let ratings = all.compactMap(\.rating).filter { $0 > 0 }
        let avgRating = ratings.isEmpty ? nil : ratings.reduce(0, +) / Double(ratings.count)

        return LogStats(
            totalMovies: movies.count,
            totalShows: shows.count,
            totalBooks: books.count,
            totalWatchTime: 0,   // Step 9'da runtime hesabı eklenecek
            averageRating: avgRating
        )
    }
}
