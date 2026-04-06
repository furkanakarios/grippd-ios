import Foundation

@Observable
final class DiscoverViewModel {

    // MARK: - State

    var trendingMovies: [TMDBMovie] = []
    var trendingShows: [TMDBTVShow] = []
    var nowPlayingMovies: [TMDBMovie] = []
    var onTheAirShows: [TMDBTVShow] = []
    var movieGenres: [TMDBGenre] = []
    var tvGenres: [TMDBGenre] = []

    var isLoadingTrending = false
    var isLoadingNowPlaying = false
    var isLoadingOnTheAir = false

    var error: String?

    private var didLoad = false

    // MARK: - Load

    func loadIfNeeded() async {
        guard !didLoad else { return }
        didLoad = true
        await load()
    }

    func refresh() async {
        didLoad = false
        trendingMovies = []
        trendingShows = []
        nowPlayingMovies = []
        onTheAirShows = []
        movieGenres = []
        tvGenres = []
        await load()
    }

    private func load() async {
        async let trending: Void = loadTrending()
        async let nowPlaying: Void = loadNowPlaying()
        async let onTheAir: Void = loadOnTheAir()
        async let genres: Void = loadGenres()
        _ = await (trending, nowPlaying, onTheAir, genres)
    }

    private func loadGenres() async {
        do {
            async let movieTask = TMDBClient.shared.movieGenres()
            async let tvTask = TMDBClient.shared.tvGenres()
            let (movies, tv) = try await (movieTask, tvTask)
            movieGenres = movies
            tvGenres = tv
        } catch {
            // sessizce geç
        }
    }

    private func loadTrending() async {
        isLoadingTrending = true
        do {
            async let moviesTask = TMDBClient.shared.trendingMovies(timeWindow: "week")
            async let showsTask = TMDBClient.shared.trendingTVShows(timeWindow: "week")
            let (movies, shows) = try await (moviesTask, showsTask)
            trendingMovies = Array(movies.results.prefix(10))
            trendingShows = Array(shows.results.prefix(10))
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingTrending = false
    }

    private func loadNowPlaying() async {
        isLoadingNowPlaying = true
        do {
            let response = try await TMDBClient.shared.nowPlayingMovies()
            nowPlayingMovies = Array(response.results.prefix(10))
        } catch {
            // sessizce geç
        }
        isLoadingNowPlaying = false
    }

    private func loadOnTheAir() async {
        isLoadingOnTheAir = true
        do {
            let response = try await TMDBClient.shared.onTheAirShows()
            onTheAirShows = Array(response.results.prefix(10))
        } catch {
            // sessizce geç
        }
        isLoadingOnTheAir = false
    }
}
