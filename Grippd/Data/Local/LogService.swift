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
        let totalLogged: Int
        let averageRating: Double?
        let ratingDistribution: [Int: Int]   // puan (1-10) → log sayısı
        let topPlatform: LogPlatform?
        let platformCounts: [(platform: LogPlatform, count: Int)]
        let rewatchCount: Int
        let thisYearCount: Int
        let thisMonthCount: Int
        let longestStreak: Int               // gün
        let topEmoji: String?
    }

    func stats() -> LogStats {
        let all = allLogs()
        let movies = all.filter { $0.contentType == .movie }
        let shows  = all.filter { $0.contentType == .tv_show }
        let books  = all.filter { $0.contentType == .book }

        let ratings = all.compactMap(\.rating).filter { $0 > 0 }
        let avgRating = ratings.isEmpty ? nil : ratings.reduce(0, +) / Double(ratings.count)

        // Puan dağılımı (1-10 tam sayıya yuvarla)
        var dist = [Int: Int]()
        for r in ratings {
            let key = Int(r.rounded())
            dist[key, default: 0] += 1
        }

        // Platform sayıları
        var platformMap = [LogPlatform: Int]()
        for log in all {
            if let p = log.platform { platformMap[p, default: 0] += 1 }
        }
        let platformCounts = platformMap
            .map { (platform: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        let topPlatform = platformCounts.first?.platform

        // Rewatch sayısı
        let rewatchCount = all.filter { $0.isRewatch }.count

        // Bu yıl / bu ay
        let calendar = Calendar.current
        let now = Date()
        let thisYearCount = all.filter { calendar.isDate($0.watchedAt, equalTo: now, toGranularity: .year) }.count
        let thisMonthCount = all.filter { calendar.isDate($0.watchedAt, equalTo: now, toGranularity: .month) }.count

        // En uzun streak (gün bazlı)
        let longestStreak = calculateStreak(logs: all)

        // En çok kullanılan emoji
        var emojiMap = [String: Int]()
        for log in all { if let e = log.emoji { emojiMap[e, default: 0] += 1 } }
        let topEmoji = emojiMap.max(by: { $0.value < $1.value })?.key

        return LogStats(
            totalMovies: movies.count,
            totalShows: shows.count,
            totalBooks: books.count,
            totalLogged: all.count,
            averageRating: avgRating,
            ratingDistribution: dist,
            topPlatform: topPlatform,
            platformCounts: platformCounts,
            rewatchCount: rewatchCount,
            thisYearCount: thisYearCount,
            thisMonthCount: thisMonthCount,
            longestStreak: longestStreak,
            topEmoji: topEmoji
        )
    }

    private func calculateStreak(logs: [LogEntry]) -> Int {
        guard !logs.isEmpty else { return 0 }
        let calendar = Calendar.current
        let days = Set(logs.map { calendar.startOfDay(for: $0.watchedAt) }).sorted(by: >)
        var maxStreak = 1
        var current = 1
        for i in 1..<days.count {
            let diff = calendar.dateComponents([.day], from: days[i], to: days[i-1]).day ?? 0
            if diff == 1 { current += 1; maxStreak = max(maxStreak, current) }
            else { current = 1 }
        }
        return maxStreak
    }
}
