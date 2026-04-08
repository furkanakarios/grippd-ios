import Foundation

// MARK: - Tab

enum DiscoverTab: String, CaseIterable {
    case all     = "Tümü"
    case movies  = "Filmler"
    case tv      = "Diziler"
    case books   = "Kitaplar"
}

// MARK: - ViewModel

@Observable
final class DiscoverViewModel {

    // MARK: - Tab State

    var selectedTab: DiscoverTab = .all

    // MARK: - Grippd Trending

    var grippedTrending: [TrendingItem] = []
    var isLoadingGrippedTrending = false

    // MARK: - Content

    var trendingMovies: [TMDBMovie] = []
    var trendingShows: [TMDBTVShow] = []
    var popularMovies: [TMDBMovie] = []
    var popularShows: [TMDBTVShow] = []
    var nowPlayingMovies: [TMDBMovie] = []
    var onTheAirShows: [TMDBTVShow] = []
    var movieGenres: [TMDBGenre] = []
    var tvGenres: [TMDBGenre] = []
    var featuredBooks: [GoogleBook] = []

    // MARK: - Loading

    var isLoadingTrending = false
    var isLoadingPopular = false
    var isLoadingNowPlaying = false
    var isLoadingOnTheAir = false
    var isLoadingBooks = false

    var error: String?

    // MARK: - Static Data

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

    // Hero: first trending movie or show depending on tab
    var heroMovie: TMDBMovie? { trendingMovies.first }
    var heroShow: TMDBTVShow? { trendingShows.first }

    private var didLoad = false

    // MARK: - Load

    func loadIfNeeded() async {
        guard !didLoad else { return }
        didLoad = true
        await load()
    }

    func refresh() async {
        didLoad = false
        grippedTrending = []
        trendingMovies = []
        trendingShows = []
        popularMovies = []
        popularShows = []
        nowPlayingMovies = []
        onTheAirShows = []
        movieGenres = []
        tvGenres = []
        featuredBooks = []
        await load()
    }

    private func load() async {
        async let grippd: Void     = loadGrippedTrending()
        async let trending: Void   = loadTrending()
        async let popular: Void    = loadPopular()
        async let nowPlaying: Void = loadNowPlaying()
        async let onTheAir: Void   = loadOnTheAir()
        async let genres: Void     = loadGenres()
        async let books: Void      = loadFeaturedBooks()
        _ = await (grippd, trending, popular, nowPlaying, onTheAir, genres, books)
    }

    private func loadGrippedTrending() async {
        isLoadingGrippedTrending = true
        grippedTrending = await TrendingService.shared.fetchTrending(limit: 12)
        isLoadingGrippedTrending = false
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

    private func loadPopular() async {
        isLoadingPopular = true
        do {
            async let moviesTask = TMDBClient.shared.popularMovies()
            async let showsTask = TMDBClient.shared.popularTVShows()
            let (movies, shows) = try await (moviesTask, showsTask)
            popularMovies = Array(movies.results.prefix(20))
            popularShows = Array(shows.results.prefix(20))
        } catch {}
        isLoadingPopular = false
    }

    private func loadGenres() async {
        do {
            async let movieTask = TMDBClient.shared.movieGenres()
            async let tvTask = TMDBClient.shared.tvGenres()
            let (movies, tv) = try await (movieTask, tvTask)
            movieGenres = movies
            tvGenres = tv
        } catch {}
    }

    private func loadNowPlaying() async {
        isLoadingNowPlaying = true
        do {
            let response = try await TMDBClient.shared.nowPlayingMovies()
            nowPlayingMovies = Array(response.results.prefix(10))
        } catch {}
        isLoadingNowPlaying = false
    }

    private func loadOnTheAir() async {
        isLoadingOnTheAir = true
        do {
            let response = try await TMDBClient.shared.onTheAirShows()
            onTheAirShows = Array(response.results.prefix(10))
        } catch {}
        isLoadingOnTheAir = false
    }

    private func loadFeaturedBooks() async {
        isLoadingBooks = true
        do {
            let response = try await GoogleBooksClient.shared.searchFeatured(maxResults: 20)
            featuredBooks = (response.items ?? []).filter {
                $0.volumeInfo.imageLinks?.thumbnailURL != nil
            }
        } catch {}
        isLoadingBooks = false
    }
}
