import Foundation

// MARK: - Filter

enum SearchFilter: String, CaseIterable {
    case all = "Tümü"
    case movies = "Filmler"
    case tv = "Diziler"
    case books = "Kitaplar"
}

// MARK: - Unified Result

enum UnifiedSearchResult: Identifiable {
    case movie(TMDBMovie)
    case tv(TMDBTVShow)
    case book(GoogleBook)

    var id: String {
        switch self {
        case .movie(let m): return "movie-\(m.id)"
        case .tv(let t): return "tv-\(t.id)"
        case .book(let b): return "book-\(b.id)"
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

    private var searchTask: Task<Void, Never>?

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
            }
        } catch {
            if !Task.isCancelled {
                self.error = error.localizedDescription
            }
        }
        isLoading = false
    }
}
