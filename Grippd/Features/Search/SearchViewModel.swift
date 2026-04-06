import Foundation

enum SearchFilter: String, CaseIterable {
    case all = "Tümü"
    case movies = "Filmler"
    case tv = "Diziler"
}

@Observable
final class SearchViewModel {

    var query = ""
    var filter: SearchFilter = .all
    var results: [TMDBSearchResult] = []
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
                let response = try await TMDBClient.shared.searchMulti(query: query)
                results = response.results.filter {
                    if case .unknown = $0 { return false }
                    return true
                }
            case .movies:
                let response = try await TMDBClient.shared.searchMovies(query: query)
                results = response.results.map { .movie($0) }
            case .tv:
                let response = try await TMDBClient.shared.searchTVShows(query: query)
                results = response.results.map { .tv($0) }
            }
        } catch {
            if !Task.isCancelled {
                self.error = error.localizedDescription
            }
        }
        isLoading = false
    }
}
