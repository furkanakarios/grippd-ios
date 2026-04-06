import Foundation

final class DIContainer {
    static let shared = DIContainer()
    private init() {}

    lazy var contentRepository: ContentRepositoryProtocol = TMDBContentRepository()
    lazy var booksRepository: BooksRepositoryProtocol = GoogleBooksRepository()
    lazy var userRepository: UserRepositoryProtocol = UserRepositoryStub()
    lazy var logRepository: LogRepositoryProtocol = LogRepositoryStub()
}

// MARK: - TMDB Content Repository (cache katmanlı)

final class TMDBContentRepository: ContentRepositoryProtocol {
    private let tmdb = TMDBClient.shared
    private var cache: LocalCacheService { LocalCacheService.shared }

    func search(query: String, type: Content.ContentType?) async throws -> [Content] {
        let typeKey = type?.rawValue ?? "multi"
        let queryKey = "\(typeKey):\(query.lowercased())"

        // Cache hit
        if let cached = await MainActor.run(body: { cache.cachedSearchResults(queryKey: queryKey) }), !cached.isEmpty {
            return cached.map { $0.toDomain() }
        }

        // Network fetch
        let results: [Content]
        switch type {
        case .movie:
            results = try await tmdb.searchMovies(query: query).results.map { TMDBMapper.toContent($0) }
        case .tv_show:
            results = try await tmdb.searchTVShows(query: query).results.map { TMDBMapper.toContent($0) }
        default:
            results = try await tmdb.searchMulti(query: query).results.compactMap { TMDBMapper.toContent($0) }
        }

        await MainActor.run { cache.cacheSearchResults(results, queryKey: queryKey) }
        return results
    }

    func fetchTrending(type: Content.ContentType, page: Int = 1) async throws -> [Content] {
        switch type {
        case .movie:
            return try await tmdb.trendingMovies().results.map { TMDBMapper.toContent($0) }
        case .tv_show:
            return try await tmdb.trendingTVShows().results.map { TMDBMapper.toContent($0) }
        case .book:
            return []
        }
    }

    func fetchMovieDetail(tmdbID: Int) async throws -> Content {
        let cacheID = CachedContent.cacheID(tmdbID: tmdbID, type: .movie)
        if let cached = await MainActor.run(body: { cache.cachedContent(id: cacheID) }) {
            return cached.toDomain()
        }
        let content = TMDBMapper.toContent(try await tmdb.movieDetail(id: tmdbID))
        await MainActor.run { cache.cacheContent(content) }
        return content
    }

    func fetchTVDetail(tmdbID: Int) async throws -> Content {
        let cacheID = CachedContent.cacheID(tmdbID: tmdbID, type: .tv_show)
        if let cached = await MainActor.run(body: { cache.cachedContent(id: cacheID) }) {
            return cached.toDomain()
        }
        let content = TMDBMapper.toContent(try await tmdb.tvShowDetail(id: tmdbID))
        await MainActor.run { cache.cacheContent(content) }
        return content
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
