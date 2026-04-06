import SwiftUI

struct DiscoverView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = DiscoverViewModel()

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.discoverPath) {
            ZStack {
                GrippdBackground()
                scrollContent
            }
            .navigationTitle("Keşfet")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: DiscoverRoute.self) { route in
                discoverDestination(route)
            }
            .task { await viewModel.loadIfNeeded() }
            .refreshable { await viewModel.refresh() }
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Trending Filmler
                sectionHeader(title: "Trend Filmler", icon: "flame.fill")
                    .padding(.top, GrippdTheme.Spacing.md)

                if viewModel.isLoadingTrending {
                    skeletonRow()
                } else if !viewModel.trendingMovies.isEmpty {
                    posterCarousel(items: viewModel.trendingMovies.map { .movie($0) })
                }

                // Trend Diziler
                sectionHeader(title: "Trend Diziler", icon: "tv.fill")
                    .padding(.top, GrippdTheme.Spacing.lg)

                if viewModel.isLoadingTrending {
                    skeletonRow()
                } else if !viewModel.trendingShows.isEmpty {
                    posterCarousel(items: viewModel.trendingShows.map { .tv($0) })
                }

                // Vizyondakiler
                sectionHeader(title: "Vizyondakiler", icon: "film.stack.fill")
                    .padding(.top, GrippdTheme.Spacing.lg)

                if viewModel.isLoadingNowPlaying {
                    skeletonRow()
                } else if !viewModel.nowPlayingMovies.isEmpty {
                    posterCarousel(items: viewModel.nowPlayingMovies.map { .movie($0) })
                }

                // Yayında Olan Diziler
                sectionHeader(title: "Yayında", icon: "antenna.radiowaves.left.and.right")
                    .padding(.top, GrippdTheme.Spacing.lg)

                if viewModel.isLoadingOnTheAir {
                    skeletonRow()
                } else if !viewModel.onTheAirShows.isEmpty {
                    posterCarousel(items: viewModel.onTheAirShows.map { .tv($0) })
                }

                // Film Türleri
                if !viewModel.movieGenres.isEmpty {
                    sectionHeader(title: "Film Türleri", icon: "film")
                        .padding(.top, GrippdTheme.Spacing.lg)
                    genreChips(genres: viewModel.movieGenres, kind: .movie)
                }

                // Dizi Türleri
                if !viewModel.tvGenres.isEmpty {
                    sectionHeader(title: "Dizi Türleri", icon: "tv")
                        .padding(.top, GrippdTheme.Spacing.lg)
                    genreChips(genres: viewModel.tvGenres, kind: .tv)
                }

                Spacer(minLength: GrippdTheme.Spacing.xxl)
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GrippdTheme.Colors.accent)
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
    }

    // MARK: - Poster Carousel

    private enum CarouselItem {
        case movie(TMDBMovie)
        case tv(TMDBTVShow)

        var id: String {
            switch self {
            case .movie(let m): return "m-\(m.id)"
            case .tv(let t): return "t-\(t.id)"
            }
        }
        var posterURL: URL? {
            switch self {
            case .movie(let m): return m.posterURL
            case .tv(let t): return t.posterURL
            }
        }
        var title: String {
            switch self {
            case .movie(let m): return m.title
            case .tv(let t): return t.name
            }
        }
        var rating: Double? {
            switch self {
            case .movie(let m): return m.voteAverage > 0 ? m.voteAverage : nil
            case .tv(let t): return t.voteAverage > 0 ? t.voteAverage : nil
            }
        }
    }

    private func posterCarousel(items: [CarouselItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(items, id: \.id) { item in
                    Button {
                        navigate(item)
                    } label: {
                        DiscoverPosterCard(
                            posterURL: item.posterURL,
                            title: item.title,
                            rating: item.rating
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, GrippdTheme.Spacing.sm)
        }
    }

    private func navigate(_ item: CarouselItem) {
        switch item {
        case .movie(let m):
            router.discoverPath.append(DiscoverRoute.movieDetail(tmdbID: m.id))
        case .tv(let t):
            router.discoverPath.append(DiscoverRoute.tvShowDetail(tmdbID: t.id))
        }
    }

    // MARK: - Genre Chips

    private func genreChips(genres: [TMDBGenre], kind: GenreBrowseViewModel.ContentKind) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(genres) { genre in
                    Button {
                        router.discoverPath.append(DiscoverRoute.genreBrowse(genre: genre, kind: kind == .movie ? "movie" : "tv"))
                    } label: {
                        Text(genre.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(GrippdTheme.Colors.surface, in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, GrippdTheme.Spacing.sm)
        }
    }

    // MARK: - Skeleton

    private func skeletonRow() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                        .fill(GrippdTheme.Colors.surface)
                        .frame(width: 110, height: 165)
                        .shimmering()
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, GrippdTheme.Spacing.sm)
        }
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func discoverDestination(_ route: DiscoverRoute) -> some View {
        switch route {
        case .movieDetail(let tmdbID): MovieDetailView(tmdbID: tmdbID)
        case .tvShowDetail(let tmdbID):
            TVShowDetailView(tmdbID: tmdbID) { showID, seasonNumber in
                router.discoverPath.append(DiscoverRoute.seasonDetail(showID: showID, seasonNumber: seasonNumber))
            }
        case .seasonDetail(let showID, let seasonNumber):
            SeasonDetailView(showID: showID, seasonNumber: seasonNumber) { sID, sNum, epNum in
                router.discoverPath.append(DiscoverRoute.episodeDetail(showID: sID, seasonNumber: sNum, episodeNumber: epNum))
            }
        case .episodeDetail(let showID, let seasonNumber, let episodeNumber):
            EpisodeDetailView(showID: showID, seasonNumber: seasonNumber, episodeNumber: episodeNumber)
        case .bookDetail(let googleBooksID):
            BookDetailView(googleBooksID: googleBooksID)
        case .personDetail: Text("Kişi Detay — Phase 3").foregroundStyle(.white)
        case .contentDetail: Text("İçerik Detay — Phase 3").foregroundStyle(.white)
        case .userProfile: Text("Kullanıcı Profil — Phase 4").foregroundStyle(.white)
        case .genre(let name): Text("\(name)").foregroundStyle(.white)
        case .genreBrowse(let genre, let kindStr):
            let kind: GenreBrowseViewModel.ContentKind = kindStr == "movie" ? .movie : .tv
            GenreBrowseView(viewModel: GenreBrowseViewModel(genre: genre, kind: kind)) { movieID in
                router.discoverPath.append(DiscoverRoute.movieDetail(tmdbID: movieID))
            } onTVTap: { tvID in
                router.discoverPath.append(DiscoverRoute.tvShowDetail(tmdbID: tvID))
            }
        }
    }
}

// MARK: - Discover Poster Card

struct DiscoverPosterCard: View {
    let posterURL: URL?
    let title: String
    let rating: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Poster
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(GrippdTheme.Colors.surface)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundStyle(.white.opacity(0.15))
                                    .font(.system(size: 22))
                            )
                    }
                }
                .frame(width: 110, height: 165)
                .clipShape(RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))

                // Rating badge
                if let rating {
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 6))
                        .padding(5)
                }
            }

            // Title
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(2)
                .frame(width: 110, alignment: .leading)
        }
    }
}

// MARK: - Shimmer View

private struct ShimmerView: View {
    @State private var phase: CGFloat = -1.0

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                gradient: Gradient(colors: [.clear, .white.opacity(0.08), .clear]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 2)
            .offset(x: geo.size.width * phase)
            .animation(.linear(duration: 1.4).repeatForever(autoreverses: false), value: phase)
            .onAppear { phase = 1.0 }
        }
        .clipped()
    }
}

private extension View {
    func shimmering() -> some View {
        self.overlay(ShimmerView())
    }
}
