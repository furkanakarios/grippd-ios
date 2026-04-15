import Foundation
import SwiftData

@MainActor
final class LogService {
    static let shared = LogService()

    private var context: ModelContext { LocalCacheService.shared.context }

    private init() {}

    // MARK: - Current User ID

    /// Mevcut auth kullanıcısının ID'si (sync, cache'li)
    private var _cachedOwnerID: String?

    var currentOwnerID: String {
        if let cached = _cachedOwnerID { return cached }
        // Sync fallback: Supabase session'dan UUID çekemiyoruz sync olarak,
        // bu yüzden setOwner() ile dışarıdan set edilmesi beklenir.
        return ""
    }

    /// Login/logout sırasında çağrılır
    func setOwner(_ userID: String) {
        _cachedOwnerID = userID
        migrateOrphanedLogs(to: userID)
    }

    func clearOwner() {
        _cachedOwnerID = nil
    }

    /// ownerID boş olan eski logları mevcut kullanıcıya ata (migration)
    private func migrateOrphanedLogs(to userID: String) {
        let descriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate { $0.ownerID == "" }
        )
        let orphaned = (try? context.fetch(descriptor)) ?? []
        guard !orphaned.isEmpty else { return }
        orphaned.forEach { $0.ownerID = userID }
        try? context.save()
    }

    // MARK: - Fetch

    /// Belirli bir içeriğe ait tüm log kayıtları (en yeni önce)
    func logs(for contentKey: String) -> [LogEntry] {
        let owner = currentOwnerID
        let descriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate { $0.contentKey == contentKey && $0.ownerID == owner },
            sortBy: [SortDescriptor(\.watchedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Tüm log kayıtları (en yeni önce)
    func allLogs() -> [LogEntry] {
        let owner = currentOwnerID
        let descriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate { $0.ownerID == owner },
            sortBy: [SortDescriptor(\.watchedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Belirli bir içerik türündeki loglar
    func logs(for contentType: Content.ContentType) -> [LogEntry] {
        let owner = currentOwnerID
        let raw = contentType.rawValue
        let descriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate { $0.contentTypeRaw == raw && $0.ownerID == owner },
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
        Task { await LogSyncService.shared.sync(entry) }
    }

    func update(_ entry: LogEntry, watchedAt: Date, platform: LogPlatform?,
                isRewatch: Bool, rating: Double?, emoji: String?, note: String?) {
        entry.watchedAt = watchedAt
        entry.platformRaw = platform?.rawValue
        entry.isRewatch = isRewatch
        entry.rating = rating
        entry.emoji = emoji
        entry.note = note
        try? context.save()
        Task { await LogSyncService.shared.update(entry) }
    }

    func delete(_ entry: LogEntry) {
        Task { await LogSyncService.shared.delete(entry) }
        context.delete(entry)
        try? context.save()
    }

    func deleteAll(for contentKey: String) {
        let entries = logs(for: contentKey)
        entries.forEach { entry in
            Task { await LogSyncService.shared.delete(entry) }
            context.delete(entry)
        }
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

    // MARK: - Wrapped

    struct WrappedStats {
        let year: Int
        let totalLogged: Int
        let totalMovies: Int
        let totalShows: Int
        let totalBooks: Int
        let averageRating: Double?
        let topPlatform: LogPlatform?
        let rewatchCount: Int
        let longestStreak: Int
        let topEmoji: String?
        let topRatedTitle: String?
        let topRatedRating: Double?
        let mostActiveMonth: String?
        let mostActiveMonthCount: Int
        let firstLogTitle: String?
        let firstLogDate: Date?
        let personalityType: String          // hesaplanan "izleyici tipi"
        let personalityEmoji: String
    }

    func wrappedStats(year: Int = Calendar.current.component(.year, from: Date())) -> WrappedStats? {
        let calendar = Calendar.current
        let yearLogs = allLogs().filter {
            calendar.component(.year, from: $0.watchedAt) == year
        }
        guard !yearLogs.isEmpty else { return nil }

        let movies = yearLogs.filter { $0.contentType == .movie }
        let shows  = yearLogs.filter { $0.contentType == .tv_show }
        let books  = yearLogs.filter { $0.contentType == .book }

        // Ortalama puan
        let ratings = yearLogs.compactMap(\.rating).filter { $0 > 0 }
        let avg = ratings.isEmpty ? nil : ratings.reduce(0, +) / Double(ratings.count)

        // Top platform
        var platformMap = [LogPlatform: Int]()
        for log in yearLogs { if let p = log.platform { platformMap[p, default: 0] += 1 } }
        let topPlatform = platformMap.max(by: { $0.value < $1.value })?.key

        // En yüksek puanlı içerik
        let topRated = yearLogs.compactMap({ log -> (String, Double)? in
            guard let r = log.rating, r > 0 else { return nil }
            return (log.contentTitle, r)
        }).max(by: { $0.1 < $1.1 })

        // En aktif ay
        var monthMap = [Int: Int]()
        for log in yearLogs {
            let m = calendar.component(.month, from: log.watchedAt)
            monthMap[m, default: 0] += 1
        }
        let topMonth = monthMap.max(by: { $0.value < $1.value })
        let monthNames = ["Ocak","Şubat","Mart","Nisan","Mayıs","Haziran",
                          "Temmuz","Ağustos","Eylül","Ekim","Kasım","Aralık"]
        let mostActiveMonth = topMonth.map { monthNames[max(0, min(11, $0.key - 1))] }

        // İlk log
        let first = yearLogs.min(by: { $0.watchedAt < $1.watchedAt })

        // En çok kullanılan emoji
        var emojiMap = [String: Int]()
        for log in yearLogs { if let e = log.emoji { emojiMap[e, default: 0] += 1 } }
        let topEmoji = emojiMap.max(by: { $0.value < $1.value })?.key

        // Streak (yıl içi)
        let streak = calculateStreak(logs: yearLogs)

        // Rewatch
        let rewatchCount = yearLogs.filter { $0.isRewatch }.count

        // Kişilik tipi
        let (personality, personalityEmoji) = personalityType(
            movies: movies.count, shows: shows.count, books: books.count,
            rewatches: rewatchCount, avg: avg
        )

        return WrappedStats(
            year: year,
            totalLogged: yearLogs.count,
            totalMovies: movies.count,
            totalShows: shows.count,
            totalBooks: books.count,
            averageRating: avg,
            topPlatform: topPlatform,
            rewatchCount: rewatchCount,
            longestStreak: streak,
            topEmoji: topEmoji,
            topRatedTitle: topRated?.0,
            topRatedRating: topRated?.1,
            mostActiveMonth: mostActiveMonth,
            mostActiveMonthCount: topMonth?.value ?? 0,
            firstLogTitle: first?.contentTitle,
            firstLogDate: first?.watchedAt,
            personalityType: personality,
            personalityEmoji: personalityEmoji
        )
    }

    private func personalityType(
        movies: Int, shows: Int, books: Int, rewatches: Int, avg: Double?
    ) -> (String, String) {
        let total = movies + shows + books
        if total == 0 { return ("Gizemli İzleyici", "🕵️") }
        let movieRatio = Double(movies) / Double(total)
        let showRatio  = Double(shows)  / Double(total)
        let bookRatio  = Double(books)  / Double(total)

        if bookRatio > 0.6  { return ("Kitap Kurdu", "📚") }
        if showRatio > 0.6  { return ("Dizi Bağımlısı", "📺") }
        if movieRatio > 0.6 { return ("Sinefil", "🎬") }
        if rewatches > total / 3 { return ("Nostaljik Ruh", "🔁") }
        if let avg, avg >= 8.5 { return ("Seçici İzleyici", "🎯") }
        if let avg, avg <= 5.0 { return ("Eleştirmen Ruhu", "🔍") }
        return ("Evrensel Tüketici", "🌍")
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
