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
    var featuredBooks: [GoogleBook] = []

    var isLoadingTrending = false
    var isLoadingNowPlaying = false
    var isLoadingOnTheAir = false
    var isLoadingBooks = false

    let bookCategories: [(label: String, query: String)] = [
        ("Kurgu", "subject:fiction"),
        ("Bilim Kurgu", "subject:science+fiction"),
        ("Tarih", "subject:history"),
        ("Biyografi", "subject:biography"),
        ("Psikoloji", "subject:psychology"),
        ("Felsefe", "subject:philosophy"),
        ("Polisiye", "subject:crime+thriller"),
        ("Kişisel Gelişim", "subject:self+help"),
        ("Bilim", "subject:science"),
        ("Ekonomi", "subject:economics")
    ]

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
        featuredBooks = []
        await load()
    }

    private func load() async {
        async let trending: Void = loadTrending()
        async let nowPlaying: Void = loadNowPlaying()
        async let onTheAir: Void = loadOnTheAir()
        async let genres: Void = loadGenres()
        async let books: Void = loadFeaturedBooks()
        _ = await (trending, nowPlaying, onTheAir, genres, books)
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

    private func loadFeaturedBooks() async {
        isLoadingBooks = true
        do {
            let response = try await GoogleBooksClient.shared.searchFeatured(maxResults: 15)
            featuredBooks = (response.items ?? []).filter {
                $0.volumeInfo.imageLinks?.thumbnailURL != nil
            }
        } catch {
            // sessizce geç
        }
        isLoadingBooks = false
    }
}
