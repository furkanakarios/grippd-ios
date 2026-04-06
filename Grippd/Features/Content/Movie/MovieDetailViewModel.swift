import Foundation

@Observable
final class MovieDetailViewModel {

    var movie: TMDBMovie?
    var isLoading = false
    var error: String?

    var isBookmarked = false

    func load(tmdbID: Int) async {
        guard movie == nil else { return }
        isLoading = true
        error = nil
        do {
            movie = try await TMDBClient.shared.movieDetail(id: tmdbID)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    var directors: [TMDBCrewMember] {
        movie?.credits?.crew.filter { $0.job == "Director" } ?? []
    }

    var mainCast: [TMDBCastMember] {
        Array((movie?.credits?.cast ?? []).prefix(15))
    }

    var formattedRuntime: String? {
        guard let runtime = movie?.runtime, runtime > 0 else { return nil }
        let hours = runtime / 60
        let minutes = runtime % 60
        if hours == 0 { return "\(minutes)dk" }
        if minutes == 0 { return "\(hours)s" }
        return "\(hours)s \(minutes)dk"
    }

    var formattedVoteCount: String {
        let count = movie?.voteCount ?? 0
        if count >= 1000 {
            return String(format: "%.0fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}
