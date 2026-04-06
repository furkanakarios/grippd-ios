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
