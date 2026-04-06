import Foundation

final class DIContainer {
    static let shared = DIContainer()
    private init() {}

    lazy var contentRepository: ContentRepositoryProtocol = TMDBContentRepository()
    lazy var booksRepository: BooksRepositoryProtocol = GoogleBooksRepository()
    lazy var userRepository: UserRepositoryProtocol = UserRepositoryStub()
    lazy var logRepository: LogRepositoryProtocol = LogRepositoryStub()
}

// MARK: - TMDB Content Repository (gerçek implementasyon)

final class TMDBContentRepository: ContentRepositoryProtocol {
    private let tmdb = TMDBClient.shared

    func search(query: String, type: Content.ContentType?) async throws -> [Content] {
        switch type {
        case .movie:
            let response = try await tmdb.searchMovies(query: query)
            return response.results.map { TMDBMapper.toContent($0) }
        case .tv_show:
            let response = try await tmdb.searchTVShows(query: query)
            return response.results.map { TMDBMapper.toContent($0) }
        default:
            let response = try await tmdb.searchMulti(query: query)
            return response.results.compactMap { TMDBMapper.toContent($0) }
        }
    }

    func fetchTrending(type: Content.ContentType, page: Int = 1) async throws -> [Content] {
        switch type {
        case .movie:
            let response = try await tmdb.trendingMovies()
            return response.results.map { TMDBMapper.toContent($0) }
        case .tv_show:
            let response = try await tmdb.trendingTVShows()
            return response.results.map { TMDBMapper.toContent($0) }
        case .book:
            return []
        }
    }

    func fetchMovieDetail(tmdbID: Int) async throws -> Content {
        let movie = try await tmdb.movieDetail(id: tmdbID)
        return TMDBMapper.toContent(movie)
    }

    func fetchTVDetail(tmdbID: Int) async throws -> Content {
        let show = try await tmdb.tvShowDetail(id: tmdbID)
        return TMDBMapper.toContent(show)
    }

    func fetchSeasonDetail(showTmdbID: Int, seasonNumber: Int) async throws -> TMDBSeason {
        try await tmdb.seasonDetail(showID: showTmdbID, seasonNumber: seasonNumber)
    }

    func addUserContent(_ content: Content) async throws -> Content { content }
}

// MARK: - Stubs

private struct UserRepositoryStub: UserRepositoryProtocol {
    func fetchProfile(id: UUID) async throws -> User { fatalError("Not implemented") }
    func updateProfile(_ user: User) async throws -> User { user }
    func follow(userID: UUID) async throws {}
    func unfollow(userID: UUID) async throws {}
    func fetchFollowers(userID: UUID) async throws -> [User] { [] }
    func fetchFollowing(userID: UUID) async throws -> [User] { [] }
}

private struct LogRepositoryStub: LogRepositoryProtocol {
    func fetchLogs(userID: UUID, contentID: UUID?) async throws -> [LogEntry] { [] }
    func addLog(_ entry: LogEntry) async throws -> LogEntry { entry }
    func updateLog(_ entry: LogEntry) async throws -> LogEntry { entry }
    func deleteLog(id: UUID) async throws {}
}
