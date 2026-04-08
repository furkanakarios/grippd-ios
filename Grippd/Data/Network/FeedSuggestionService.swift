import Foundation

/// Kullanıcı ilgi alanlarına göre içerik önerisi oluşturur.
/// Feed boş olduğunda (kimseyi takip etmiyorsun) gösterilir.
final class FeedSuggestionService {
    static let shared = FeedSuggestionService()
    private let tmdb = TMDBClient.shared

    private init() {}

    struct SuggestionSection: Identifiable {
        let id = UUID()
        let title: String
        let emoji: String
        let items: [Content]
    }

    /// Verilen ilgi alanlarına göre öneriler getirir.
    /// Hiç ilgi alanı yoksa trending içerikler döner.
    func fetchSuggestions(interests: [String]) async -> [SuggestionSection] {
        let parsed = interests.compactMap { ContentInterest(rawValue: $0) }

        if parsed.isEmpty {
            return await fetchTrending()
        }

        let movieInterests = parsed.filter { !$0.isBookInterest }
        let bookInterests  = parsed.filter { $0.isBookInterest }

        var sections: [SuggestionSection] = []

        // Film/dizi önerileri: ilk 2 ilgiden genre-based discover
        for interest in movieInterests.prefix(2) {
            guard let genreIDs = interest.tmdbGenreIDs, let genreID = genreIDs.first else { continue }
            async let movies = (try? tmdb.discoverMovies(genreID: genreID, page: 1)) ?? .empty
            async let shows  = (try? tmdb.discoverTVShows(genreID: genreID, page: 1)) ?? .empty
            let (m, s) = await (movies, shows)
            let items = (m.results.prefix(5).map(TMDBMapper.toContent) +
                         s.results.prefix(5).map(TMDBMapper.toContent))
                .shuffled()
                .prefix(8)
            if !items.isEmpty {
                sections.append(SuggestionSection(
                    title: interest.rawValue,
                    emoji: interest.emoji,
                    items: Array(items)
                ))
            }
        }

        // Trending movies fallback ek section olarak her zaman ekle
        if let trending = try? await tmdb.trendingMovies() {
            let items = trending.results.prefix(10).map(TMDBMapper.toContent)
            if !items.isEmpty {
                sections.append(SuggestionSection(
                    title: "Bu Hafta Trend",
                    emoji: "🔥",
                    items: Array(items)
                ))
            }
        }

        // Trending TV fallback
        if let trending = try? await tmdb.trendingTVShows() {
            let items = trending.results.prefix(10).map(TMDBMapper.toContent)
            if !items.isEmpty {
                sections.append(SuggestionSection(
                    title: "Popüler Diziler",
                    emoji: "📺",
                    items: Array(items)
                ))
            }
        }

        _ = bookInterests // ileride Google Books entegrasyonu için

        return sections
    }

    // MARK: - Trending (fallback)

    private func fetchTrending() async -> [SuggestionSection] {
        async let movies = (try? tmdb.trendingMovies()) ?? .empty
        async let shows  = (try? tmdb.trendingTVShows()) ?? .empty
        let (m, s) = await (movies, shows)

        var sections: [SuggestionSection] = []
        if !m.results.isEmpty {
            sections.append(SuggestionSection(
                title: "Bu Hafta Trend",
                emoji: "🔥",
                items: Array(m.results.prefix(10).map(TMDBMapper.toContent))
            ))
        }
        if !s.results.isEmpty {
            sections.append(SuggestionSection(
                title: "Popüler Diziler",
                emoji: "📺",
                items: Array(s.results.prefix(10).map(TMDBMapper.toContent))
            ))
        }
        return sections
    }
}

private extension TMDBPagedResponse {
    static var empty: TMDBPagedResponse {
        TMDBPagedResponse(page: 0, results: [], totalPages: 0, totalResults: 0)
    }
}
