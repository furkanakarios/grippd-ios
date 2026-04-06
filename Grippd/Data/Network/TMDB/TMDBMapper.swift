import Foundation

enum TMDBMapper {

    // MARK: - Movie → Content

    static func toContent(_ movie: TMDBMovie) -> Content {
        Content(
            id: UUID(),
            tmdbID: movie.id,
            googleBooksID: nil,
            title: movie.title,
            originalTitle: movie.originalTitle == movie.title ? nil : movie.originalTitle,
            overview: movie.overview.isEmpty ? nil : movie.overview,
            posterURL: movie.posterURL,
            backdropURL: movie.backdropURL,
            releaseYear: movie.releaseYear.flatMap { Int($0) },
            contentType: .movie,
            genres: movie.genres?.map { $0.name } ?? [],
            averageRating: movie.voteAverage,
            tmdbPopularity: movie.popularity,
            runtime: movie.runtime,
            isUserCreated: false,
            createdAt: Date()
        )
    }

    // MARK: - TV Show → Content

    static func toContent(_ show: TMDBTVShow) -> Content {
        Content(
            id: UUID(),
            tmdbID: show.id,
            googleBooksID: nil,
            title: show.name,
            originalTitle: show.originalName == show.name ? nil : show.originalName,
            overview: show.overview.isEmpty ? nil : show.overview,
            posterURL: show.posterURL,
            backdropURL: show.backdropURL,
            releaseYear: show.firstAirYear.flatMap { Int($0) },
            contentType: .tv_show,
            genres: show.genres?.map { $0.name } ?? [],
            averageRating: show.voteAverage,
            tmdbPopularity: show.popularity,
            runtime: nil,
            isUserCreated: false,
            createdAt: Date()
        )
    }

    // MARK: - Search Result → Content

    static func toContent(_ result: TMDBSearchResult) -> Content? {
        switch result {
        case .movie(let m): return toContent(m)
        case .tv(let t):    return toContent(t)
        case .unknown:      return nil
        }
    }
}
