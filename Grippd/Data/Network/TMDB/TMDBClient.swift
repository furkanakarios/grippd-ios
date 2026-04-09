import Foundation

final class TMDBClient {
    static let shared = TMDBClient()

    private let apiKey: String
    private let baseURL = "https://api.themoviedb.org/3"
    private let language = "tr-TR"
    private let session: URLSession

    private init() {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "TMDBApiKey") as? String, !key.isEmpty else {
            fatalError("TMDB API key missing from Info.plist. Check xcconfig setup.")
        }
        self.apiKey = key
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 20_000_000, diskCapacity: 100_000_000)
        self.session = URLSession(configuration: config)
    }

    // MARK: - Movies

    func popularMovies(page: Int = 1) async throws -> TMDBPagedResponse<TMDBMovie> {
        try await get("movie/popular", params: ["page": "\(page)"])
    }

    func trendingMovies(timeWindow: String = "week") async throws -> TMDBPagedResponse<TMDBMovie> {
        try await get("trending/movie/\(timeWindow)")
    }

    func movieDetail(id: Int) async throws -> TMDBMovie {
        try await get("movie/\(id)", params: ["append_to_response": "credits"])
    }

    func nowPlayingMovies(page: Int = 1) async throws -> TMDBPagedResponse<TMDBMovie> {
        try await get("movie/now_playing", params: ["page": "\(page)", "region": "TR"])
    }

    func upcomingMovies(page: Int = 1) async throws -> TMDBPagedResponse<TMDBMovie> {
        try await get("movie/upcoming", params: ["page": "\(page)", "region": "TR"])
    }

    func searchMovies(query: String, page: Int = 1) async throws -> TMDBPagedResponse<TMDBMovie> {
        try await get("search/movie", params: ["query": query, "page": "\(page)"])
    }

    // MARK: - TV Shows

    func popularTVShows(page: Int = 1) async throws -> TMDBPagedResponse<TMDBTVShow> {
        try await get("tv/popular", params: ["page": "\(page)"])
    }

    func trendingTVShows(timeWindow: String = "week") async throws -> TMDBPagedResponse<TMDBTVShow> {
        try await get("trending/tv/\(timeWindow)")
    }

    func tvShowDetail(id: Int) async throws -> TMDBTVShow {
        try await get("tv/\(id)", params: ["append_to_response": "credits"])
    }

    func seasonDetail(showID: Int, seasonNumber: Int) async throws -> TMDBSeason {
        try await get("tv/\(showID)/season/\(seasonNumber)", params: ["append_to_response": "episodes"])
    }

    func episodeDetail(showID: Int, seasonNumber: Int, episodeNumber: Int) async throws -> TMDBEpisode {
        try await get(
            "tv/\(showID)/season/\(seasonNumber)/episode/\(episodeNumber)",
            params: ["append_to_response": "credits"]
        )
    }

    func onTheAirShows(page: Int = 1) async throws -> TMDBPagedResponse<TMDBTVShow> {
        try await get("tv/on_the_air", params: ["page": "\(page)"])
    }

    func searchTVShows(query: String, page: Int = 1) async throws -> TMDBPagedResponse<TMDBTVShow> {
        try await get("search/tv", params: ["query": query, "page": "\(page)"])
    }

    // MARK: - Person Search

    func searchPersons(query: String, page: Int = 1) async throws -> TMDBPagedResponse<TMDBPerson> {
        try await get("search/person", params: ["query": query, "page": "\(page)"])
    }

    // MARK: - Multi Search (film + dizi birlikte)

    func searchMulti(query: String, page: Int = 1) async throws -> TMDBPagedResponse<TMDBSearchResult> {
        try await get("search/multi", params: ["query": query, "page": "\(page)"])
    }

    // MARK: - Top Rated

    func topRatedMovies(page: Int = 1) async throws -> TMDBPagedResponse<TMDBMovie> {
        try await get("movie/top_rated", params: ["page": "\(page)"])
    }

    func topRatedTVShows(page: Int = 1) async throws -> TMDBPagedResponse<TMDBTVShow> {
        try await get("tv/top_rated", params: ["page": "\(page)"])
    }

    // MARK: - Similar / Recommendations

    func similarMovies(id: Int) async throws -> TMDBPagedResponse<TMDBMovie> {
        try await get("movie/\(id)/similar")
    }

    func similarTVShows(id: Int) async throws -> TMDBPagedResponse<TMDBTVShow> {
        try await get("tv/\(id)/similar")
    }

    // MARK: - Generic Discover

    func discover<T: Decodable>(path: String, params: [String: String]) async throws -> TMDBPagedResponse<T> {
        try await get("discover/\(path)", params: params)
    }

    // MARK: - Discover by Genre

    func discoverMovies(genreID: Int, page: Int = 1, sortBy: String = "popularity.desc", minVoteCount: Int = 200) async throws -> TMDBPagedResponse<TMDBMovie> {
        try await get("discover/movie", params: [
            "with_genres": "\(genreID)",
            "sort_by": sortBy,
            "page": "\(page)",
            "vote_count.gte": "\(minVoteCount)"
        ])
    }

    func discoverTVShows(genreID: Int, page: Int = 1, sortBy: String = "popularity.desc") async throws -> TMDBPagedResponse<TMDBTVShow> {
        try await get("discover/tv", params: [
            "with_genres": "\(genreID)",
            "sort_by": sortBy,
            "page": "\(page)"
        ])
    }

    // MARK: - Genres

    func movieGenres() async throws -> [TMDBGenre] {
        struct Response: Decodable { let genres: [TMDBGenre] }
        let response: Response = try await get("genre/movie/list")
        return response.genres
    }

    func tvGenres() async throws -> [TMDBGenre] {
        struct Response: Decodable { let genres: [TMDBGenre] }
        let response: Response = try await get("genre/tv/list")
        return response.genres
    }

    // MARK: - Generic Request

    private func get<T: Decodable>(_ path: String, params: [String: String] = [:]) async throws -> T {
        var components = URLComponents(string: "\(baseURL)/\(path)")!
        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: language)
        ]
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw TMDBError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw TMDBError.httpError(statusCode: http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw TMDBError.decodingError(error)
        }
    }
}

// MARK: - Errors

enum TMDBError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçersiz URL."
        case .invalidResponse: return "Sunucu yanıtı alınamadı."
        case .httpError(let code): return "Sunucu hatası: \(code)"
        case .decodingError(let e): return "Veri işleme hatası: \(e.localizedDescription)"
        }
    }
}
