import Foundation

final class WatchmodeClient {
    static let shared = WatchmodeClient()

    private let baseURL = "https://api.watchmode.com/v1"
    private let apiKey: String
    private let session: URLSession

    // In-memory cache: key = "movie-{tmdbID}" or "tv-{tmdbID}"
    private var cache: [String: WatchmodeCacheEntry] = [:]

    private init() {
        let key = Bundle.main.object(forInfoDictionaryKey: "WatchmodeApiKey") as? String ?? ""
        self.apiKey = key
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public

    /// Returns streaming sources for a movie (TMDB ID), with 24h in-memory cache.
    func sourcesForMovie(tmdbID: Int) async throws -> [WatchmodeSource] {
        try await sources(cacheKey: "movie-\(tmdbID)", searchField: "tmdb_movie_id", tmdbID: tmdbID)
    }

    /// Returns streaming sources for a TV show (TMDB ID), with 24h in-memory cache.
    func sourcesForTV(tmdbID: Int) async throws -> [WatchmodeSource] {
        try await sources(cacheKey: "tv-\(tmdbID)", searchField: "tmdb_tv_id", tmdbID: tmdbID)
    }

    // MARK: - Private

    private func sources(cacheKey: String, searchField: String, tmdbID: Int) async throws -> [WatchmodeSource] {
        // Return cached if still fresh
        if let entry = cache[cacheKey], !entry.isExpired {
            return entry.sources
        }

        guard !apiKey.isEmpty else {
            throw WatchmodeError.missingAPIKey
        }

        // Step 1: find the Watchmode title ID
        let searchResponse: WatchmodeSearchResponse = try await get("search", params: [
            "search_field": searchField,
            "search_value": "\(tmdbID)"
        ])

        guard let titleID = searchResponse.titleResults.first?.id else {
            let entry = WatchmodeCacheEntry(sources: [], fetchedAt: Date())
            cache[cacheKey] = entry
            return []
        }

        // Step 2: fetch sources for Turkey
        let sources: [WatchmodeSource] = try await get("title/\(titleID)/sources", params: ["regions": "TR"])

        // Deduplicate by (sourceID, type) — Watchmode sometimes returns duplicates for SD/HD
        var seen = Set<String>()
        let deduped = sources.filter { source in
            let key = "\(source.sourceID)-\(source.type)"
            return seen.insert(key).inserted
        }

        // Sort: sub first, then free, then rent/buy
        let sorted = deduped.sorted { a, b in
            let order: [WatchmodeSource.SourceType] = [.subscription, .free, .rent, .buy, .tve, .unknown]
            let ai = order.firstIndex(of: a.type) ?? 99
            let bi = order.firstIndex(of: b.type) ?? 99
            return ai < bi
        }

        let entry = WatchmodeCacheEntry(sources: sorted, fetchedAt: Date())
        cache[cacheKey] = entry
        return sorted
    }

    private func get<T: Decodable>(_ path: String, params: [String: String] = [:]) async throws -> T {
        var allParams = params
        allParams["apiKey"] = apiKey

        var components = URLComponents(string: "\(baseURL)/\(path)/")!
        components.queryItems = allParams.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = components.url else { throw WatchmodeError.invalidURL }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else { throw WatchmodeError.httpError(0) }
        guard (200...299).contains(http.statusCode) else { throw WatchmodeError.httpError(http.statusCode) }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Errors

enum WatchmodeError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Watchmode API anahtarı eksik."
        case .invalidURL: return "Geçersiz URL."
        case .httpError(let code): return "Sunucu hatası (\(code))."
        }
    }
}
