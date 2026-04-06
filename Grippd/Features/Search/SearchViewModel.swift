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

    var id: String {
        switch self {
        case .movie(let m): return "movie-\(m.id)"
        case .tv(let t): return "tv-\(t.id)"
        case .book(let b): return "book-\(b.id)"
        case .person(let p): return "person-\(p.id)"
        }
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
        guard trimmed.count >= 2 else {
            results = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await search(query: trimmed)
        }
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

    private func search(query: String) async {
        isLoading = true
        error = nil
        do {
            switch filter {
            case .all:
                async let tmdbTask = TMDBClient.shared.searchMulti(query: query)
                async let booksTask = GoogleBooksClient.shared.search(query: query, maxResults: 5)
                let (tmdbResponse, booksResponse) = try await (tmdbTask, booksTask)
                let tmdbResults = tmdbResponse.results.compactMap { result -> UnifiedSearchResult? in
                    switch result {
                    case .movie(let m): return .movie(m)
                    case .tv(let t): return .tv(t)
                    case .unknown: return nil
                    }
                }
                let bookResults = (booksResponse.items ?? []).map { UnifiedSearchResult.book($0) }
                results = tmdbResults + bookResults

            case .movies:
                let response = try await TMDBClient.shared.searchMovies(query: query)
                results = response.results.map { .movie($0) }

            case .tv:
                let response = try await TMDBClient.shared.searchTVShows(query: query)
                results = response.results.map { .tv($0) }

            case .books:
                let response = try await GoogleBooksClient.shared.search(query: query, maxResults: 20)
                results = (response.items ?? []).map { .book($0) }

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
