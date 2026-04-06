import Foundation

@Observable
final class TVShowDetailViewModel {

    var show: TMDBTVShow?
    var isLoading = false
    var error: String?

    var isBookmarked = false

    func load(tmdbID: Int) async {
        guard show == nil else { return }
        isLoading = true
        error = nil
        do {
            show = try await TMDBClient.shared.tvShowDetail(id: tmdbID)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    var mainCast: [TMDBCastMember] {
        Array((show?.credits?.cast ?? []).prefix(15))
    }

    var formattedVoteCount: String {
        let count = show?.voteCount ?? 0
        if count >= 1000 { return String(format: "%.0fK", Double(count) / 1000) }
        return "\(count)"
    }

    var seasonSummary: String? {
        guard let show else { return nil }
        let seasonCount = show.mainSeasons.count
        let epCount = show.numberOfEpisodes ?? 0
        if seasonCount == 0 { return nil }
        return "\(seasonCount) sezon · \(epCount) bölüm"
    }
}
