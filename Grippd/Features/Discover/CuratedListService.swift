import Foundation

// MARK: - Curated List

struct CuratedList: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String          // SF Symbol
    let accentHex: String     // hex string for Hashable conformance
    let source: Source

    enum Source: Hashable {
        case tmdbDiscover(genreID: Int, contentType: ContentKind, sortBy: String)
        case tmdbTrending(contentType: ContentKind, timeWindow: String)
        case tmdbNowPlaying
        case tmdbUpcoming
        case tmdbTopRated(contentType: ContentKind)
        case books(query: String)
    }

    enum ContentKind: Hashable { case movie, tv }
}

// MARK: - Curated List Item (display)

enum CuratedItem: Identifiable {
    case movie(TMDBMovie)
    case tv(TMDBTVShow)
    case book(GoogleBook)

    var id: String {
        switch self {
        case .movie(let m): return "movie-\(m.id)"
        case .tv(let t):    return "tv-\(t.id)"
        case .book(let b):  return "book-\(b.id)"
        }
    }

    var title: String {
        switch self {
        case .movie(let m): return m.title
        case .tv(let t):    return t.name
        case .book(let b):  return b.volumeInfo.title
        }
    }

    var posterURL: URL? {
        switch self {
        case .movie(let m): return m.posterURL
        case .tv(let t):    return t.posterURL
        case .book(let b):  return b.volumeInfo.imageLinks?.thumbnailURL
        }
    }

    var rating: Double? {
        switch self {
        case .movie(let m): return m.voteAverage > 0 ? m.voteAverage : nil
        case .tv(let t):    return t.voteAverage > 0 ? t.voteAverage : nil
        case .book(let b):  return b.volumeInfo.averageRating.map { $0 * 2 } // 5→10 scale
        }
    }
}

// MARK: - Static Catalog

extension CuratedList {
    static let all: [CuratedList] = [
        CuratedList(
            id: "oscar-winners",
            title: "En Beğenilen Filmler",
            subtitle: "Tüm zamanların favorileri",
            icon: "trophy.fill",
            accentHex: "#F5C518",
            source: .tmdbTopRated(contentType: .movie)
        ),
        CuratedList(
            id: "sci-fi-gems",
            title: "Bilim Kurgu",
            subtitle: "Geleceğe yolculuk",
            icon: "sparkles",
            accentHex: "#4FC3F7",
            source: .tmdbDiscover(genreID: 878, contentType: .movie, sortBy: "popularity.desc")
        ),
        CuratedList(
            id: "top-rated-tv",
            title: "En İyi Diziler",
            subtitle: "Binge-worthy seçkiler",
            icon: "tv.fill",
            accentHex: "#81C784",
            source: .tmdbTopRated(contentType: .tv)
        ),
        CuratedList(
            id: "action-movies",
            title: "Aksiyon & Macera",
            subtitle: "Nefes kesen filmler",
            icon: "flame.fill",
            accentHex: "#FF7043",
            source: .tmdbDiscover(genreID: 28, contentType: .movie, sortBy: "popularity.desc")
        ),
        CuratedList(
            id: "top-rated-movies",
            title: "Tüm Zamanların En İyileri",
            subtitle: "Sinema tarihi",
            icon: "star.fill",
            accentHex: "#FFD54F",
            source: .tmdbTopRated(contentType: .movie)
        ),
        CuratedList(
            id: "upcoming",
            title: "Yakında Vizyonda",
            subtitle: "Merakla beklenenler",
            icon: "calendar",
            accentHex: "#CE93D8",
            source: .tmdbUpcoming
        ),
        CuratedList(
            id: "classic-books",
            title: "Edebiyat Klasikleri",
            subtitle: "Mutlaka okunması gerekenler",
            icon: "books.vertical.fill",
            accentHex: "#A5D6A7",
            source: .books(query: "subject:classics")
        ),
        CuratedList(
            id: "thriller-books",
            title: "Gerilim & Polisiye",
            subtitle: "Sizi bırakmayan kitaplar",
            icon: "magnifyingglass",
            accentHex: "#EF9A9A",
            source: .books(query: "subject:crime+thriller")
        ),
    ]
}

// MARK: - Service

@MainActor
final class CuratedListService {
    static let shared = CuratedListService()
    private init() {}

    func fetchItems(for list: CuratedList) async -> [CuratedItem] {
        switch list.source {
        case .tmdbDiscover(let genreID, let kind, let sortBy):
            switch kind {
            case .movie:
                let r = try? await TMDBClient.shared.discoverMovies(genreID: genreID, sortBy: sortBy)
                return (r?.results ?? []).prefix(20).map { .movie($0) }
            case .tv:
                let r = try? await TMDBClient.shared.discoverTVShows(genreID: genreID, sortBy: sortBy)
                return (r?.results ?? []).prefix(20).map { .tv($0) }
            }

        case .tmdbTrending(let kind, let window):
            switch kind {
            case .movie:
                let r = try? await TMDBClient.shared.trendingMovies(timeWindow: window)
                return (r?.results ?? []).prefix(20).map { .movie($0) }
            case .tv:
                let r = try? await TMDBClient.shared.trendingTVShows(timeWindow: window)
                return (r?.results ?? []).prefix(20).map { .tv($0) }
            }

        case .tmdbNowPlaying:
            let r = try? await TMDBClient.shared.nowPlayingMovies()
            return (r?.results ?? []).prefix(20).map { .movie($0) }

        case .tmdbUpcoming:
            let r = try? await TMDBClient.shared.upcomingMovies()
            return (r?.results ?? []).prefix(20).map { .movie($0) }

        case .tmdbTopRated(let kind):
            switch kind {
            case .movie:
                let r = try? await TMDBClient.shared.topRatedMovies()
                return (r?.results ?? []).prefix(20).map { .movie($0) }
            case .tv:
                let r = try? await TMDBClient.shared.topRatedTVShows()
                return (r?.results ?? []).prefix(20).map { .tv($0) }
            }

        case .books(let query):
            let r = try? await GoogleBooksClient.shared.search(query: query, maxResults: 20)
            return (r?.items ?? [])
                .filter { $0.volumeInfo.imageLinks?.thumbnailURL != nil }
                .prefix(20).map { .book($0) }
        }
    }
}
