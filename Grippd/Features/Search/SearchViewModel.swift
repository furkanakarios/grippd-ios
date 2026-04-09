import Foundation

// MARK: - Filter

enum SearchFilter: String, CaseIterable {
    case all = "Tümü"
    case movies = "Filmler"
    case tv = "Diziler"
    case books = "Kitaplar"
    case person = "Kişiler"
}

// MARK: - Unified Result

enum UnifiedSearchResult: Identifiable {
    case movie(TMDBMovie)
    case tv(TMDBTVShow)
    case book(GoogleBook)
    case person(TMDBPerson)
    case userContent(Content)

    var id: String {
        switch self {
        case .movie(let m): return "movie-\(m.id)"
        case .tv(let t): return "tv-\(t.id)"
        case .book(let b): return "book-\(b.id)"
        case .person(let p): return "person-\(p.id)"
        case .userContent(let c): return "user-\(c.id.uuidString)"
        }
    }
}

// MARK: - Advanced Filters

struct SearchFilters: Equatable {
    var minYear: Int? = nil
    var maxYear: Int? = nil
    var minRating: Double? = nil   // 0–10
    var genreID: Int? = nil

    var isActive: Bool {
        minYear != nil || maxYear != nil || minRating != nil || genreID != nil
    }

    mutating func reset() {
        minYear = nil; maxYear = nil; minRating = nil; genreID = nil
    }
}

// MARK: - ViewModel

@Observable
final class SearchViewModel {

    var query = ""
    var filter: SearchFilter = .all
    var results: [UnifiedSearchResult] = []
    var isLoading = false
    var error: String?
    var advancedFilters = SearchFilters()
    var showFilterSheet = false

    // Empty state
    var searchHistory: [String] = []
    var trendingSuggestions: [String] = []

    private var searchTask: Task<Void, Never>?
    private let history = SearchHistoryService.shared

    init() {
        searchHistory = history.history
    }

    func onQueryChange() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)

        // Filtre aktifse sorgu boş olsa da discover çalıştır
        if trimmed.count < 2 && !advancedFilters.isActive {
            results = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await search(query: trimmed)
        }
    }

    func applyFilters() {
        onQueryChange()
    }

    func loadTrending() async {
        guard trendingSuggestions.isEmpty else { return }
        do {
            async let moviesTask = TMDBClient.shared.trendingMovies(timeWindow: "week")
            async let showsTask = TMDBClient.shared.trendingTVShows(timeWindow: "week")
            let (movies, shows) = try await (moviesTask, showsTask)
            let movieTitles = movies.results.prefix(5).map(\.title)
            let showTitles = shows.results.prefix(5).map(\.name)
            let all = Array(movieTitles + showTitles).prefix(8)
            trendingSuggestions = Array(all)
        } catch {
            // Sessizce geç
        }
    }

    func removeHistory(_ item: String) {
        history.remove(item)
        searchHistory = history.history
    }

    func clearHistory() {
        history.clearAll()
        searchHistory = history.history
    }

    func selectSuggestion(_ suggestion: String) {
        query = suggestion
        onQueryChange()
    }

    private func discoverMovies(query: String) async throws -> [TMDBMovie] {
        var params: [String: String] = ["sort_by": "popularity.desc"]
        if !query.isEmpty { params["with_text_query"] = query }
        if let y = advancedFilters.minYear { params["primary_release_date.gte"] = "\(y)-01-01" }
        if let y = advancedFilters.maxYear { params["primary_release_date.lte"] = "\(y)-12-31" }
        if let r = advancedFilters.minRating { params["vote_average.gte"] = String(format: "%.1f", r) }
        if let g = advancedFilters.genreID { params["with_genres"] = "\(g)" }
        if advancedFilters.minRating != nil { params["vote_count.gte"] = "100" }
        let response: TMDBPagedResponse<TMDBMovie> = try await TMDBClient.shared.discover(path: "movie", params: params)
        return response.results
    }

    private func discoverShows(query: String) async throws -> [TMDBTVShow] {
        var params: [String: String] = ["sort_by": "popularity.desc"]
        if !query.isEmpty { params["with_text_query"] = query }
        if let y = advancedFilters.minYear { params["first_air_date.gte"] = "\(y)-01-01" }
        if let y = advancedFilters.maxYear { params["first_air_date.lte"] = "\(y)-12-31" }
        if let r = advancedFilters.minRating { params["vote_average.gte"] = String(format: "%.1f", r) }
        if let g = advancedFilters.genreID { params["with_genres"] = "\(g)" }
        if advancedFilters.minRating != nil { params["vote_count.gte"] = "100" }
        let response: TMDBPagedResponse<TMDBTVShow> = try await TMDBClient.shared.discover(path: "tv", params: params)
        return response.results
    }

    private func search(query: String) async {
        isLoading = true
        error = nil

        // Kullanıcı içeriklerini her zaman yerel olarak ara
        let userResults: [UnifiedSearchResult] = await MainActor.run {
            UserContentService.shared.search(query: query).map { .userContent($0.toContent()) }
        }

        do {
            switch filter {
            case .all:
                let tmdbResponse = try await TMDBClient.shared.searchMulti(query: query)
                let booksResponse = try? await GoogleBooksClient.shared.search(query: query, maxResults: 5)
                let tmdbResults = tmdbResponse.results.compactMap { result -> UnifiedSearchResult? in
                    switch result {
                    case .movie(let m): return .movie(m)
                    case .tv(let t): return .tv(t)
                    case .unknown: return nil
                    }
                }
                let bookResults = (booksResponse?.items ?? []).map { UnifiedSearchResult.book($0) }
                // Kullanıcı içerikleri önce gelir
                results = userResults + tmdbResults + bookResults

            case .movies:
                let movieUserResults = userResults.filter {
                    if case .userContent(let c) = $0 { return c.contentType == .movie }
                    return false
                }
                if advancedFilters.isActive {
                    let movies = try await discoverMovies(query: query)
                    results = movieUserResults + movies.map { .movie($0) }
                } else {
                    let response = try await TMDBClient.shared.searchMovies(query: query)
                    results = movieUserResults + response.results.map { .movie($0) }
                }

            case .tv:
                let tvUserResults = userResults.filter {
                    if case .userContent(let c) = $0 { return c.contentType == .tv_show }
                    return false
                }
                if advancedFilters.isActive {
                    let shows = try await discoverShows(query: query)
                    results = tvUserResults + shows.map { .tv($0) }
                } else {
                    let response = try await TMDBClient.shared.searchTVShows(query: query)
                    results = tvUserResults + response.results.map { .tv($0) }
                }

            case .books:
                let response = try await GoogleBooksClient.shared.search(query: query, maxResults: 20)
                let bookUserResults = userResults.filter {
                    if case .userContent(let c) = $0 { return c.contentType == .book }
                    return false
                }
                results = bookUserResults + (response.items ?? []).map { .book($0) }

            case .person:
                let response = try await TMDBClient.shared.searchPersons(query: query)
                results = response.results.map { .person($0) }
            }

            // Aramayı geçmişe kaydet
            history.add(query)
            searchHistory = history.history

        } catch {
            if !Task.isCancelled {
                self.error = error.localizedDescription
            }
        }
        isLoading = false
    }
}
