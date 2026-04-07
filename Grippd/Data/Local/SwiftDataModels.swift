import Foundation
import SwiftData

// MARK: - Cached Content

@Model
final class CachedContent {
    @Attribute(.unique) var id: String          // "tmdb_movie_123" veya "gbooks_abc"
    var tmdbID: Int?
    var googleBooksID: String?
    var title: String
    var originalTitle: String?
    var overview: String?
    var posterURLString: String?
    var backdropURLString: String?
    var releaseYear: Int?
    var contentTypeRaw: String                  // "movie", "tv_show", "book"
    var genresData: Data                        // [String] JSON
    var averageRating: Double?
    var runtime: Int?
    var isUserCreated: Bool
    var cachedAt: Date
    var expiresAt: Date

    init(
        id: String,
        tmdbID: Int? = nil,
        googleBooksID: String? = nil,
        title: String,
        originalTitle: String? = nil,
        overview: String? = nil,
        posterURLString: String? = nil,
        backdropURLString: String? = nil,
        releaseYear: Int? = nil,
        contentTypeRaw: String,
        genres: [String] = [],
        averageRating: Double? = nil,
        runtime: Int? = nil,
        isUserCreated: Bool = false,
        ttl: TimeInterval = 86400  // 24 saat
    ) {
        self.id = id
        self.tmdbID = tmdbID
        self.googleBooksID = googleBooksID
        self.title = title
        self.originalTitle = originalTitle
        self.overview = overview
        self.posterURLString = posterURLString
        self.backdropURLString = backdropURLString
        self.releaseYear = releaseYear
        self.contentTypeRaw = contentTypeRaw
        self.genresData = (try? JSONEncoder().encode(genres)) ?? Data()
        self.averageRating = averageRating
        self.runtime = runtime
        self.isUserCreated = isUserCreated
        self.cachedAt = Date()
        self.expiresAt = Date().addingTimeInterval(ttl)
    }

    var isExpired: Bool { Date() > expiresAt }

    var genres: [String] {
        (try? JSONDecoder().decode([String].self, from: genresData)) ?? []
    }

    func toDomain() -> Content {
        Content(
            id: UUID(),
            tmdbID: tmdbID,
            googleBooksID: googleBooksID,
            title: title,
            originalTitle: originalTitle,
            overview: overview,
            posterURL: posterURLString.flatMap { URL(string: $0) },
            backdropURL: backdropURLString.flatMap { URL(string: $0) },
            releaseYear: releaseYear,
            contentType: Content.ContentType(rawValue: contentTypeRaw) ?? .movie,
            genres: genres,
            averageRating: averageRating,
            tmdbPopularity: nil,
            runtime: runtime,
            isUserCreated: isUserCreated,
            createdByUserID: nil,
            createdAt: cachedAt
        )
    }

    static func cacheID(tmdbID: Int, type: Content.ContentType) -> String {
        "tmdb_\(type.rawValue)_\(tmdbID)"
    }

    static func cacheID(googleBooksID: String) -> String {
        "gbooks_\(googleBooksID)"
    }
}

// MARK: - User Created Content (kalıcı, TTL yok)

@Model
final class UserCreatedContent {
    @Attribute(.unique) var id: String          // UUID string
    var title: String
    var contentTypeRaw: String                  // "movie", "tv_show", "book"
    var year: Int?
    var overview: String?
    var posterURLString: String?
    var genresRaw: String                       // virgülle ayrılmış
    var runtime: Int?                           // film/dizi → dakika, kitap → sayfa
    var createdAt: Date

    init(
        title: String,
        contentType: Content.ContentType,
        year: Int? = nil,
        overview: String? = nil,
        posterURLString: String? = nil,
        genres: [String] = [],
        runtime: Int? = nil
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.contentTypeRaw = contentType.rawValue
        self.year = year
        self.overview = overview
        self.posterURLString = posterURLString
        self.genresRaw = genres.joined(separator: ", ")
        self.runtime = runtime
        self.createdAt = Date()
    }

    var contentType: Content.ContentType {
        Content.ContentType(rawValue: contentTypeRaw) ?? .movie
    }

    var genres: [String] {
        genresRaw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    func toContent() -> Content {
        Content(
            id: UUID(uuidString: id) ?? UUID(),
            tmdbID: nil,
            googleBooksID: nil,
            title: title,
            originalTitle: nil,
            overview: overview,
            posterURL: posterURLString.flatMap { URL(string: $0) },
            backdropURL: nil,
            releaseYear: year,
            contentType: contentType,
            genres: genres,
            averageRating: nil,
            tmdbPopularity: nil,
            runtime: runtime,
            isUserCreated: true,
            createdByUserID: nil,
            createdAt: createdAt
        )
    }
}

// MARK: - Log Entry (izlendi/okundu kaydı)

@Model
final class LogEntry {
    @Attribute(.unique) var id: String              // UUID string
    var contentKey: String                          // "movie-27205", "tv-1396", "book-abc"
    var contentTypeRaw: String                      // "movie", "tv_show", "book"
    var contentTitle: String
    var posterPath: String?

    var watchedAt: Date                             // ne zaman izlendi/okundu
    var platformRaw: String?                        // "netflix", "cinema", "library" vb.
    var isRewatch: Bool                             // tekrar izleme/okuma mı?

    var rating: Double?                             // 0.0–10.0, 0.5 adımlı; nil = puanlanmadı
    var emoji: String?                              // tek emoji reaksiyon
    var note: String?                               // kısa not

    var createdAt: Date

    init(
        contentKey: String,
        contentType: Content.ContentType,
        contentTitle: String,
        posterPath: String? = nil,
        watchedAt: Date = Date(),
        platform: LogPlatform? = nil,
        isRewatch: Bool = false,
        rating: Double? = nil,
        emoji: String? = nil,
        note: String? = nil
    ) {
        self.id = UUID().uuidString
        self.contentKey = contentKey
        self.contentTypeRaw = contentType.rawValue
        self.contentTitle = contentTitle
        self.posterPath = posterPath
        self.watchedAt = watchedAt
        self.platformRaw = platform?.rawValue
        self.isRewatch = isRewatch
        self.rating = rating
        self.emoji = emoji
        self.note = note
        self.createdAt = Date()
    }

    var contentType: Content.ContentType {
        Content.ContentType(rawValue: contentTypeRaw) ?? .movie
    }

    var platform: LogPlatform? {
        platformRaw.flatMap { LogPlatform(rawValue: $0) }
    }

    /// Poster URL'i (TMDB veya Google Books formatında)
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
}

// MARK: - Log Platform

enum LogPlatform: String, CaseIterable, Identifiable {
    case netflix       = "netflix"
    case disneyPlus    = "disney_plus"
    case amazonPrime   = "amazon_prime"
    case hboMax        = "hbo_max"
    case appletv       = "apple_tv"
    case bluTV         = "blu_tv"
    case mubi          = "mubi"
    case cinema        = "cinema"
    case dvd           = "dvd"
    case library       = "library"       // kitaplık (kitaplar için)
    case kindle        = "kindle"
    case physicalBook  = "physical_book"
    case other         = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .netflix:      return "Netflix"
        case .disneyPlus:   return "Disney+"
        case .amazonPrime:  return "Prime Video"
        case .hboMax:       return "HBO Max"
        case .appletv:      return "Apple TV+"
        case .bluTV:        return "BluTV"
        case .mubi:         return "MUBI"
        case .cinema:       return "Sinemada"
        case .dvd:          return "DVD / Blu-ray"
        case .library:      return "Kütüphaneden"
        case .kindle:       return "Kindle"
        case .physicalBook: return "Basılı Kitap"
        case .other:        return "Diğer"
        }
    }

    var icon: String {
        switch self {
        case .netflix:      return "play.rectangle.fill"
        case .disneyPlus:   return "play.rectangle.fill"
        case .amazonPrime:  return "play.rectangle.fill"
        case .hboMax:       return "play.rectangle.fill"
        case .appletv:      return "appletv.fill"
        case .bluTV:        return "play.rectangle.fill"
        case .mubi:         return "play.rectangle.fill"
        case .cinema:       return "popcorn.fill"
        case .dvd:          return "opticaldisc"
        case .library:      return "building.columns.fill"
        case .kindle:       return "ipad.and.iphone"
        case .physicalBook: return "book.closed.fill"
        case .other:        return "ellipsis.circle.fill"
        }
    }

    /// İçerik türüne uygun platformlar
    static func platforms(for contentType: Content.ContentType) -> [LogPlatform] {
        switch contentType {
        case .movie:
            return [.netflix, .disneyPlus, .amazonPrime, .hboMax, .appletv, .bluTV, .mubi, .cinema, .dvd, .other]
        case .tv_show:
            return [.netflix, .disneyPlus, .amazonPrime, .hboMax, .appletv, .bluTV, .mubi, .other]
        case .book:
            return [.physicalBook, .kindle, .library, .other]
        }
    }
}

// MARK: - Custom List

@Model
final class CustomList {
    @Attribute(.unique) var id: String
    var name: String
    var emoji: String          // liste ikonu
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade) var items: [CustomListItem] = []

    init(name: String, emoji: String = "📋") {
        self.id = UUID().uuidString
        self.name = name
        self.emoji = emoji
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class CustomListItem {
    @Attribute(.unique) var id: String
    var contentKey: String
    var contentTypeRaw: String
    var contentTitle: String
    var posterPath: String?
    var addedAt: Date

    var list: CustomList?

    init(contentKey: String, contentType: Content.ContentType, contentTitle: String, posterPath: String? = nil) {
        self.id = UUID().uuidString
        self.contentKey = contentKey
        self.contentTypeRaw = contentType.rawValue
        self.contentTitle = contentTitle
        self.posterPath = posterPath
        self.addedAt = Date()
    }

    var contentType: Content.ContentType {
        Content.ContentType(rawValue: contentTypeRaw) ?? .movie
    }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
}

// MARK: - Watchlist Entry

@Model
final class WatchlistEntry {
    @Attribute(.unique) var contentKey: String   // "movie-27205", "tv-1396", "book-abc"
    var contentTypeRaw: String
    var contentTitle: String
    var posterPath: String?
    var addedAt: Date

    init(
        contentKey: String,
        contentType: Content.ContentType,
        contentTitle: String,
        posterPath: String? = nil
    ) {
        self.contentKey = contentKey
        self.contentTypeRaw = contentType.rawValue
        self.contentTitle = contentTitle
        self.posterPath = posterPath
        self.addedAt = Date()
    }

    var contentType: Content.ContentType {
        Content.ContentType(rawValue: contentTypeRaw) ?? .movie
    }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
}

// MARK: - Cached Search Query

@Model
final class CachedSearchQuery {
    @Attribute(.unique) var queryKey: String     // "movie:breaking bad"
    var resultIDs: Data                          // [String] JSON — CachedContent.id listesi
    var cachedAt: Date
    var expiresAt: Date

    init(queryKey: String, resultIDs: [String], ttl: TimeInterval = 3600) {
        self.queryKey = queryKey
        self.resultIDs = (try? JSONEncoder().encode(resultIDs)) ?? Data()
        self.cachedAt = Date()
        self.expiresAt = Date().addingTimeInterval(ttl)
    }

    var isExpired: Bool { Date() > expiresAt }

    var ids: [String] {
        (try? JSONDecoder().decode([String].self, from: resultIDs)) ?? []
    }
}
