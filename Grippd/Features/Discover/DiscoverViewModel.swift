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

    var trendingUsers: [TrendingUser] = []
    var isLoadingTrendingUsers = false

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

    // MARK: - Personalized Recommendations

    var recommendedMovies: [TMDBMovie] = []
    var recommendedShows: [TMDBTVShow] = []
    var recommendedBooks: [GoogleBook] = []
    var isLoadingRecommendations = false
    var hasRecommendations: Bool { !recommendedMovies.isEmpty || !recommendedShows.isEmpty }

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
        trendingUsers = []
        trendingMovies = []
        trendingShows = []
        popularMovies = []
        popularShows = []
        nowPlayingMovies = []
        onTheAirShows = []
        movieGenres = []
        tvGenres = []
        featuredBooks = []
        recommendedMovies = []
        recommendedShows = []
        recommendedBooks = []
        await load()
    }

    private func load() async {
        async let grippd: Void     = loadGrippedTrending()
        async let users: Void      = loadTrendingUsers()
        async let trending: Void   = loadTrending()
        async let popular: Void    = loadPopular()
        async let nowPlaying: Void = loadNowPlaying()
        async let onTheAir: Void   = loadOnTheAir()
        async let genres: Void     = loadGenres()
        async let books: Void      = loadFeaturedBooks()
        async let recs: Void       = loadRecommendations()
        _ = await (grippd, users, trending, popular, nowPlaying, onTheAir, genres, books, recs)
    }

    private func loadTrendingUsers() async {
        isLoadingTrendingUsers = true
        trendingUsers = await TrendingService.shared.fetchTrendingUsers(limit: 10)
        isLoadingTrendingUsers = false
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

    @MainActor
    private func loadRecommendations() async {
        isLoadingRecommendations = true
        defer { isLoadingRecommendations = false }

        // Son 90 günde izlenen film ve dizi loglarını al (max 5 adet)
        let allLogs = LogService.shared.allLogs()
        let cutoff = Date().addingTimeInterval(-90 * 24 * 3600)
        let recentLogs = allLogs
            .filter { $0.watchedAt >= cutoff }
            .prefix(5)

        var movieIDs: [Int] = []
        var showIDs: [Int] = []

        for log in recentLogs {
            // contentKey format: "movie-12345" veya "tv_show-67890"
            let parts = log.contentKey.split(separator: "-", maxSplits: 1)
            guard parts.count == 2, let tmdbID = Int(parts[1]) else { continue }
            if log.contentKey.hasPrefix("movie") {
                movieIDs.append(tmdbID)
            } else if log.contentKey.hasPrefix("tv") {
                showIDs.append(tmdbID)
            }
        }

        // Her kaynak için similar içerik çek, sonuçları birleştir
        var movies: [TMDBMovie] = []
        var shows: [TMDBTVShow] = []
        let loggedKeys = Set(allLogs.map { $0.contentKey })

        await withTaskGroup(of: [TMDBMovie].self) { group in
            for id in movieIDs.prefix(3) {
                group.addTask {
                    (try? await TMDBClient.shared.similarMovies(id: id))?.results ?? []
                }
            }
            for await result in group { movies.append(contentsOf: result) }
        }

        await withTaskGroup(of: [TMDBTVShow].self) { group in
            for id in showIDs.prefix(3) {
                group.addTask {
                    (try? await TMDBClient.shared.similarTVShows(id: id))?.results ?? []
                }
            }
            for await result in group { shows.append(contentsOf: result) }
        }

        // Tekrarları kaldır, zaten izlenenleri filtrele
        var seenMovieIDs = Set(movieIDs)
        var seenShowIDs = Set(showIDs)

        let filteredMovies = movies.filter { movie in
            let key = "movie-\(movie.id)"
            guard !loggedKeys.contains(key), !seenMovieIDs.contains(movie.id) else { return false }
            seenMovieIDs.insert(movie.id)
            return true
        }

        let filteredShows = shows.filter { show in
            let key = "tv_show-\(show.id)"
            guard !loggedKeys.contains(key), !seenShowIDs.contains(show.id) else { return false }
            seenShowIDs.insert(show.id)
            return true
        }

        // Popülerliğe göre sırala
        recommendedMovies = Array(
            filteredMovies.sorted { $0.popularity > $1.popularity }.prefix(12)
        )
        recommendedShows = Array(
            filteredShows.sorted { $0.popularity > $1.popularity }.prefix(12)
        )

        // Kitap önerileri: loglanmış kitapların kategorilerinden arama yap
        let bookLogs = allLogs
            .filter { $0.contentKey.hasPrefix("book") }
            .prefix(5)

        if !bookLogs.isEmpty {
            var categoryCounts: [String: Int] = [:]
            for log in bookLogs {
                let bookID = String(log.contentKey.split(separator: "-", maxSplits: 1).last ?? "")
                guard !bookID.isEmpty,
                      let detail = try? await GoogleBooksClient.shared.volumeDetail(id: bookID),
                      let cats = detail.volumeInfo.categories else { continue }
                for cat in cats {
                    categoryCounts[cat, default: 0] += 1
                }
            }
            if let topCategory = categoryCounts.max(by: { $0.value < $1.value })?.key {
                let query = "subject:\(topCategory.lowercased().replacingOccurrences(of: " ", with: "+"))"
                let response = try? await GoogleBooksClient.shared.search(query: query, maxResults: 20)
                let loggedBookKeys = Set(allLogs.filter { $0.contentKey.hasPrefix("book") }.map { $0.contentKey })
                recommendedBooks = (response?.items ?? []).filter {
                    let key = "book-\($0.id)"
                    return !loggedBookKeys.contains(key) && $0.volumeInfo.imageLinks?.thumbnailURL != nil
                }.prefix(12).map { $0 }
            }
        }
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
