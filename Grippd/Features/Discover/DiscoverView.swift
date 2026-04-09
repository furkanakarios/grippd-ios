import SwiftUI

struct DiscoverView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState
    @State private var viewModel = DiscoverViewModel()

    private var isPremium: Bool { appState.currentUser?.planType == .premium }

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.discoverPath) {
            ZStack {
                GrippdBackground()
                VStack(spacing: 0) {
                    tabFilter
                    tabContent
                }
                .padding(.top, 1)
            }
            .navigationTitle("Keşfet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: DiscoverRoute.self) { route in
                discoverDestination(route)
            }
            .task { await viewModel.loadIfNeeded(isPremium: isPremium) }
            .refreshable { await viewModel.refresh() }
        }
    }

    // MARK: - Tab Filter

    private var tabFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DiscoverTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: viewModel.selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(viewModel.selectedTab == tab ? GrippdTheme.Colors.background : .white.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedTab == tab
                                    ? GrippdTheme.Colors.accent
                                    : Color.white.opacity(0.07),
                                in: Capsule()
                            )
                    }
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, GrippdTheme.Spacing.sm)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .all:     allTabContent
        case .movies:  moviesTabContent
        case .tv:      tvTabContent
        case .books:   booksTabContent
        }
    }

    // MARK: - All Tab

    private var allTabContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Hero banner
                if let hero = viewModel.heroMovie {
                    heroBanner(
                        backdropURL: hero.backdropURL,
                        title: hero.title,
                        rating: hero.voteAverage,
                        onTap: { router.discoverPath.append(DiscoverRoute.movieDetail(tmdbID: hero.id)) }
                    )
                    .padding(.bottom, GrippdTheme.Spacing.lg)
                } else if viewModel.isLoadingTrending {
                    heroBannerSkeleton
                        .padding(.bottom, GrippdTheme.Spacing.lg)
                }

                // Listeler
                sectionHeader(title: "Listeler", icon: "list.star")
                curatedListsCarousel

                // Senin İçin
                let allRecs = viewModel.recommendedMovies.map { CarouselItem.movie($0) }
                    + viewModel.recommendedShows.map { CarouselItem.tv($0) }
                    + viewModel.recommendedBooks.map { CarouselItem.book($0) }
                if viewModel.isLoadingRecommendations || !allRecs.isEmpty {
                    sectionHeader(title: "Senin İçin", icon: "sparkles",
                                  badge: isPremium ? "Premium" : "Öneriler")
                    if viewModel.isLoadingRecommendations {
                        skeletonRow()
                    } else {
                        posterCarousel(allRecs)
                    }
                }

                // Premium upsell — free kullanıcılara
                if !isPremium {
                    premiumUpsellBanner
                        .padding(.horizontal, GrippdTheme.Spacing.md)
                        .padding(.top, GrippdTheme.Spacing.sm)
                }

                // Grippd'de Trend
                if viewModel.isLoadingGrippedTrending || !viewModel.grippedTrending.isEmpty {
                    sectionHeader(title: "Grippd'de Trend", icon: "chart.line.uptrend.xyaxis", badge: "Bu Hafta")
                    if viewModel.isLoadingGrippedTrending {
                        skeletonRow()
                    } else {
                        grippedTrendingCarousel(viewModel.grippedTrending)
                    }
                }

                // Trend Kullanıcılar
                if viewModel.isLoadingTrendingUsers || !viewModel.trendingUsers.isEmpty {
                    sectionHeader(title: "Aktif Kullanıcılar", icon: "person.2.fill", badge: "Bu Hafta")
                        .padding(.top, GrippdTheme.Spacing.lg)
                    if viewModel.isLoadingTrendingUsers {
                        userCarouselSkeleton
                    } else {
                        trendingUsersCarousel(viewModel.trendingUsers)
                    }
                }

                // Benzer Zevkler
                if viewModel.isLoadingSimilarUsers || !viewModel.similarUsers.isEmpty {
                    sectionHeader(title: "Benzer Zevkler", icon: "person.2.fill", badge: "Senin Gibi")
                        .padding(.top, GrippdTheme.Spacing.lg)
                    if viewModel.isLoadingSimilarUsers {
                        userCarouselSkeleton
                    } else {
                        similarUsersCarousel(viewModel.similarUsers)
                    }
                }

                // Trend Filmler
                sectionHeader(title: "Trend Filmler", icon: "flame.fill")
                    .padding(.top, GrippdTheme.Spacing.lg)
                if viewModel.isLoadingTrending {
                    skeletonRow()
                } else {
                    posterCarousel(viewModel.trendingMovies.map { .movie($0) })
                }

                // Trend Diziler
                sectionHeader(title: "Trend Diziler", icon: "tv.fill")
                    .padding(.top, GrippdTheme.Spacing.lg)
                if viewModel.isLoadingTrending {
                    skeletonRow()
                } else {
                    posterCarousel(viewModel.trendingShows.map { .tv($0) })
                }

                // Öne Çıkan Kitaplar
                sectionHeader(title: "Öne Çıkan Kitaplar", icon: "books.vertical.fill")
                    .padding(.top, GrippdTheme.Spacing.lg)
                if viewModel.isLoadingBooks {
                    skeletonRow()
                } else {
                    posterCarousel(viewModel.featuredBooks.prefix(10).map { .book($0) })
                }

                // Vizyondakiler
                sectionHeader(title: "Vizyondakiler", icon: "film.stack.fill")
                    .padding(.top, GrippdTheme.Spacing.lg)
                if viewModel.isLoadingNowPlaying {
                    skeletonRow()
                } else {
                    posterCarousel(viewModel.nowPlayingMovies.map { .movie($0) })
                }

                // Yakında Vizyonda
                if viewModel.isLoadingUpcoming || !viewModel.upcomingMovies.isEmpty {
                    sectionHeader(title: "Yakında Vizyonda", icon: "calendar", badge: "Yeni")
                        .padding(.top, GrippdTheme.Spacing.lg)
                    if viewModel.isLoadingUpcoming {
                        skeletonRow()
                    } else {
                        upcomingCarousel(viewModel.upcomingMovies)
                    }
                }

                // Yayında
                sectionHeader(title: "Yayında", icon: "antenna.radiowaves.left.and.right")
                    .padding(.top, GrippdTheme.Spacing.lg)
                if viewModel.isLoadingOnTheAir {
                    skeletonRow()
                } else {
                    posterCarousel(viewModel.onTheAirShows.map { .tv($0) })
                }

                Spacer(minLength: GrippdTheme.Spacing.xxl)
            }
        }
    }

    // MARK: - Movies Tab

    private var moviesTabContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Senin İçin
                if viewModel.isLoadingRecommendations || !viewModel.recommendedMovies.isEmpty {
                    sectionHeader(title: "Senin İçin", icon: "sparkles", badge: "Öneriler")
                        .padding(.top, GrippdTheme.Spacing.sm)
                    if viewModel.isLoadingRecommendations {
                        skeletonRow()
                    } else {
                        posterCarousel(viewModel.recommendedMovies.map { .movie($0) })
                    }
                }

                // Trending grid
                sectionHeader(title: "Haftalık Trend", icon: "flame.fill")
                    .padding(.top, GrippdTheme.Spacing.sm)

                let trendingItems = viewModel.trendingMovies.map { CarouselItem.movie($0) }
                if viewModel.isLoadingTrending {
                    gridSkeleton()
                } else if !trendingItems.isEmpty {
                    contentGrid(trendingItems)
                }

                // Vizyondakiler carousel
                sectionHeader(title: "Vizyondakiler", icon: "film.stack.fill")
                    .padding(.top, GrippdTheme.Spacing.lg)
                if viewModel.isLoadingNowPlaying {
                    skeletonRow()
                } else {
                    posterCarousel(viewModel.nowPlayingMovies.map { .movie($0) })
                }

                // Yakında Vizyonda
                if !viewModel.upcomingMovies.isEmpty {
                    sectionHeader(title: "Yakında Vizyonda", icon: "calendar", badge: "Yeni")
                        .padding(.top, GrippdTheme.Spacing.lg)
                    upcomingCarousel(viewModel.upcomingMovies)
                }

                // Popüler grid
                sectionHeader(title: "Popüler Filmler", icon: "star.fill")
                    .padding(.top, GrippdTheme.Spacing.lg)
                let popularItems = viewModel.popularMovies.map { CarouselItem.movie($0) }
                if viewModel.isLoadingPopular {
                    gridSkeleton()
                } else if !popularItems.isEmpty {
                    contentGrid(popularItems)
                }

                // Genre chips
                if !viewModel.movieGenres.isEmpty {
                    sectionHeader(title: "Türler", icon: "tag.fill")
                        .padding(.top, GrippdTheme.Spacing.lg)
                    genreChips(genres: viewModel.movieGenres, kind: .movie)
                }

                Spacer(minLength: GrippdTheme.Spacing.xxl)
            }
        }
    }

    // MARK: - TV Tab

    private var tvTabContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Senin İçin
                if viewModel.isLoadingRecommendations || !viewModel.recommendedShows.isEmpty {
                    sectionHeader(title: "Senin İçin", icon: "sparkles", badge: "Öneriler")
                        .padding(.top, GrippdTheme.Spacing.sm)
                    if viewModel.isLoadingRecommendations {
                        skeletonRow()
                    } else {
                        posterCarousel(viewModel.recommendedShows.map { .tv($0) })
                    }
                }

                sectionHeader(title: "Haftalık Trend", icon: "flame.fill")
                    .padding(.top, GrippdTheme.Spacing.sm)

                let trendingItems = viewModel.trendingShows.map { CarouselItem.tv($0) }
                if viewModel.isLoadingTrending {
                    gridSkeleton()
                } else if !trendingItems.isEmpty {
                    contentGrid(trendingItems)
                }

                sectionHeader(title: "Yayında", icon: "antenna.radiowaves.left.and.right")
                    .padding(.top, GrippdTheme.Spacing.lg)
                if viewModel.isLoadingOnTheAir {
                    skeletonRow()
                } else {
                    posterCarousel(viewModel.onTheAirShows.map { .tv($0) })
                }

                sectionHeader(title: "Popüler Diziler", icon: "star.fill")
                    .padding(.top, GrippdTheme.Spacing.lg)
                let popularItems = viewModel.popularShows.map { CarouselItem.tv($0) }
                if viewModel.isLoadingPopular {
                    gridSkeleton()
                } else if !popularItems.isEmpty {
                    contentGrid(popularItems)
                }

                if !viewModel.tvGenres.isEmpty {
                    sectionHeader(title: "Türler", icon: "tag.fill")
                        .padding(.top, GrippdTheme.Spacing.lg)
                    genreChips(genres: viewModel.tvGenres, kind: .tv)
                }

                Spacer(minLength: GrippdTheme.Spacing.xxl)
            }
        }
    }

    // MARK: - Books Tab

    private var booksTabContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Senin İçin
                if viewModel.isLoadingRecommendations || !viewModel.recommendedBooks.isEmpty {
                    sectionHeader(title: "Senin İçin", icon: "sparkles", badge: "Öneriler")
                        .padding(.top, GrippdTheme.Spacing.sm)
                    if viewModel.isLoadingRecommendations {
                        skeletonRow()
                    } else {
                        posterCarousel(viewModel.recommendedBooks.map { .book($0) })
                    }
                }

                sectionHeader(title: "Öne Çıkan Kitaplar", icon: "books.vertical.fill")
                    .padding(.top, GrippdTheme.Spacing.sm)

                let bookItems = Array(viewModel.featuredBooks).map { CarouselItem.book($0) }
                if viewModel.isLoadingBooks {
                    gridSkeleton()
                } else if !bookItems.isEmpty {
                    contentGrid(bookItems)
                }

                sectionHeader(title: "Kategoriler", icon: "tag.fill")
                    .padding(.top, GrippdTheme.Spacing.lg)
                bookCategoryChips()

                Spacer(minLength: GrippdTheme.Spacing.xxl)
            }
        }
    }

    // MARK: - Hero Banner

    private func heroBanner(backdropURL: URL?, title: String, rating: Double, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Backdrop
                AsyncImage(url: backdropURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle().fill(GrippdTheme.Colors.surface)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.85)],
                    startPoint: .center, endPoint: .bottom
                )

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(GrippdTheme.Colors.accent)
                        Text("Bu Haftanın Trendi")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(GrippdTheme.Colors.accent)
                    }
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding(.horizontal, GrippdTheme.Spacing.md)
                .padding(.bottom, GrippdTheme.Spacing.md)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, GrippdTheme.Spacing.md)
        }
        .buttonStyle(.plain)
    }

    private var heroBannerSkeleton: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(GrippdTheme.Colors.surface)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .shimmering()
            .padding(.horizontal, GrippdTheme.Spacing.md)
    }

    // MARK: - 2-Column Grid

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private func contentGrid(_ items: [CarouselItem]) -> some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(items, id: \.id) { item in
                Button {
                    navigate(item)
                } label: {
                    GridPosterCard(
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

    private func gridSkeleton() -> some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                    .fill(GrippdTheme.Colors.surface)
                    .aspectRatio(2/3, contentMode: .fit)
                    .shimmering()
            }
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, GrippdTheme.Spacing.sm)
    }

    // MARK: - Poster Carousel

    private enum CarouselItem {
        case movie(TMDBMovie)
        case tv(TMDBTVShow)
        case book(GoogleBook)

        var id: String {
            switch self {
            case .movie(let m): return "m-\(m.id)"
            case .tv(let t):    return "t-\(t.id)"
            case .book(let b):  return "b-\(b.id)"
            }
        }
        var posterURL: URL? {
            switch self {
            case .movie(let m): return m.posterURL
            case .tv(let t):    return t.posterURL
            case .book(let b):  return b.volumeInfo.imageLinks?.thumbnailURL
            }
        }
        var title: String {
            switch self {
            case .movie(let m): return m.title
            case .tv(let t):    return t.name
            case .book(let b):  return b.volumeInfo.title
            }
        }
        var rating: Double? {
            switch self {
            case .movie(let m): return m.voteAverage > 0 ? m.voteAverage : nil
            case .tv(let t):    return t.voteAverage > 0 ? t.voteAverage : nil
            case .book(let b):  return b.volumeInfo.averageRating
            }
        }
    }

    private func posterCarousel(_ items: [CarouselItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(items, id: \.id) { item in
                    Button { navigate(item) } label: {
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
        case .movie(let m): router.discoverPath.append(DiscoverRoute.movieDetail(tmdbID: m.id))
        case .tv(let t):    router.discoverPath.append(DiscoverRoute.tvShowDetail(tmdbID: t.id))
        case .book(let b):  router.discoverPath.append(DiscoverRoute.bookDetail(googleBooksID: b.id))
        }
    }

    // MARK: - Trending Users Carousel

    private func trendingUsersCarousel(_ users: [TrendingUser]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(users) { user in
                    Button {
                        if let id = user.userUUID {
                            router.discoverPath.append(DiscoverRoute.userProfile(userID: id))
                        }
                    } label: {
                        TrendingUserCard(user: user)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, GrippdTheme.Spacing.sm)
        }
    }

    private func similarUsersCarousel(_ users: [SimilarUser]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(users) { user in
                    Button {
                        if let id = user.userUUID {
                            router.discoverPath.append(DiscoverRoute.userProfile(userID: id))
                        }
                    } label: {
                        SimilarUserCard(user: user)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, GrippdTheme.Spacing.sm)
        }
    }

    private var userCarouselSkeleton: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(GrippdTheme.Colors.surface)
                            .frame(width: 64, height: 64)
                            .shimmering()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(GrippdTheme.Colors.surface)
                            .frame(width: 60, height: 10)
                            .shimmering()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(GrippdTheme.Colors.surface)
                            .frame(width: 44, height: 8)
                            .shimmering()
                    }
                    .frame(width: 80)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, GrippdTheme.Spacing.sm)
        }
    }

    // MARK: - Grippd Trending Carousel

    private func grippedTrendingCarousel(_ items: [TrendingItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(items) { item in
                    Button { navigateTrending(item) } label: {
                        GrippedTrendingCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, GrippdTheme.Spacing.sm)
        }
    }

    private func navigateTrending(_ item: TrendingItem) {
        switch item.resolvedContentType {
        case .movie:
            if let id = item.tmdbId {
                router.discoverPath.append(DiscoverRoute.movieDetail(tmdbID: id))
            }
        case .tv_show:
            if let id = item.tmdbId {
                router.discoverPath.append(DiscoverRoute.tvShowDetail(tmdbID: id))
            }
        case .book:
            if let id = item.googleBooksId {
                router.discoverPath.append(DiscoverRoute.bookDetail(googleBooksID: id))
            }
        }
    }

    // MARK: - Upcoming Carousel

    private func upcomingCarousel(_ movies: [TMDBMovie]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(movies) { movie in
                    Button {
                        router.discoverPath.append(DiscoverRoute.movieDetail(tmdbID: movie.id))
                    } label: {
                        UpcomingMovieCard(movie: movie)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, GrippdTheme.Spacing.sm)
        }
    }

    // MARK: - Curated Lists Carousel

    private var curatedListsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CuratedList.all) { list in
                    Button {
                        router.discoverPath.append(DiscoverRoute.curatedList(list))
                    } label: {
                        CuratedListCard(list: list)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, GrippdTheme.Spacing.sm)
        }
    }

    // MARK: - Premium Upsell Banner

    private var premiumUpsellBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "crown.fill")
                .font(.system(size: 20))
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Daha fazla öneri için Premium'a geç")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Kişiselleştirilmiş öneriler, reklamsız deneyim")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Text("Keşfet")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GrippdTheme.Colors.background)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(GrippdTheme.Colors.accent, in: Capsule())
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.12), GrippdTheme.Colors.accent.opacity(0.08)],
                startPoint: .leading, endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.yellow.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String, badge: String? = nil) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GrippdTheme.Colors.accent)
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            if let badge {
                Text(badge)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(GrippdTheme.Colors.background)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(GrippdTheme.Colors.accent, in: Capsule())
            }
            Spacer()
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.top, GrippdTheme.Spacing.sm)
        .padding(.bottom, 2)
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

    private func bookCategoryChips() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.bookCategories, id: \.query) { category in
                    Button {
                        router.discoverPath.append(DiscoverRoute.bookCategoryBrowse(label: category.label, query: category.query))
                    } label: {
                        Text(category.label)
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
        case .bookCategoryBrowse(let label, let query):
            BookCategoryBrowseView(categoryLabel: label, query: query) { googleBooksID in
                router.discoverPath.append(DiscoverRoute.bookDetail(googleBooksID: googleBooksID))
            }
        case .personDetail: Text("Kişi Detay").foregroundStyle(.white)
        case .contentDetail: Text("İçerik Detay").foregroundStyle(.white)
        case .userProfile(let userID): UserProfileView(userID: userID)
        case .genre(let name): Text("\(name)").foregroundStyle(.white)
        case .genreBrowse(let genre, let kindStr):
            let kind: GenreBrowseViewModel.ContentKind = kindStr == "movie" ? .movie : .tv
            GenreBrowseView(viewModel: GenreBrowseViewModel(genre: genre, kind: kind)) { movieID in
                router.discoverPath.append(DiscoverRoute.movieDetail(tmdbID: movieID))
            } onTVTap: { tvID in
                router.discoverPath.append(DiscoverRoute.tvShowDetail(tmdbID: tvID))
            }
        case .curatedList(let list):
            CuratedListDetailView(list: list)
        }
    }
}

// MARK: - Grippd Trending Card

struct GrippedTrendingCard: View {
    let item: TrendingItem

    private var typeIcon: String {
        switch item.resolvedContentType {
        case .movie:   return "film"
        case .tv_show: return "tv"
        case .book:    return "book.closed"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomLeading) {
                Color.clear
                    .frame(width: 110, height: 165)
                    .overlay(
                        AsyncImage(url: item.posterURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Rectangle()
                                    .fill(GrippdTheme.Colors.surface)
                                    .overlay(
                                        Image(systemName: typeIcon)
                                            .font(.system(size: 22))
                                            .foregroundStyle(.white.opacity(0.15))
                                    )
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))

                // Log count badge
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 9))
                    Text("\(item.logCount)")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(GrippdTheme.Colors.accent.opacity(0.88), in: RoundedRectangle(cornerRadius: 6))
                .padding(5)
            }
            .frame(width: 110, height: 165)

            Text(item.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(2)
                .frame(width: 110, alignment: .leading)
        }
    }
}

// MARK: - Grid Poster Card

struct GridPosterCard: View {
    let posterURL: URL?
    let title: String
    let rating: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                // Sabit 2:3 oranı — genişlik ne olursa olsun yükseklik tutarlı
                Color.clear
                    .aspectRatio(2/3, contentMode: .fit)
                    .overlay(
                        AsyncImage(url: posterURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                Rectangle()
                                    .fill(GrippdTheme.Colors.surface)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundStyle(.white.opacity(0.15))
                                            .font(.system(size: 24))
                                    )
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))

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

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Discover Poster Card (carousel — kept for backward compat)

struct DiscoverPosterCard: View {
    let posterURL: URL?
    let title: String
    let rating: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
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

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(2)
                .frame(width: 110, alignment: .leading)
        }
    }
}

// MARK: - Trending User Card

struct TrendingUserCard: View {
    let user: TrendingUser

    var body: some View {
        VStack(spacing: 8) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: user.avatarURL) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        Circle()
                            .fill(GrippdTheme.Colors.accent.opacity(0.12))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white.opacity(0.3))
                            )
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.08), lineWidth: 1))

                // Log count badge
                Text("\(user.logCount)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(GrippdTheme.Colors.background)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(GrippdTheme.Colors.accent, in: Capsule())
                    .offset(x: 4, y: 4)
            }

            // Name
            Text(user.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("@\(user.username)")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
                .lineLimit(1)
        }
        .frame(width: 80)
    }
}

// MARK: - Similar User Card

struct SimilarUserCard: View {
    let user: SimilarUser

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: user.avatarURL) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        Circle()
                            .fill(GrippdTheme.Colors.accent.opacity(0.12))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white.opacity(0.3))
                            )
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.08), lineWidth: 1))

                // Ortak içerik sayısı badge
                HStack(spacing: 2) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 7, weight: .bold))
                    Text("\(user.commonCount)")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(GrippdTheme.Colors.background)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(GrippdTheme.Colors.accent, in: Capsule())
                .offset(x: 4, y: 4)
            }

            Text(user.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("@\(user.username)")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
                .lineLimit(1)
        }
        .frame(width: 80)
    }
}

// MARK: - Upcoming Movie Card

struct UpcomingMovieCard: View {
    let movie: TMDBMovie

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Poster
            Color.clear
                .aspectRatio(2/3, contentMode: .fit)
                .overlay(
                    AsyncImage(url: movie.posterURL) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFill()
                        default:
                            Rectangle()
                                .fill(GrippdTheme.Colors.surface)
                                .overlay(Image(systemName: "film").foregroundStyle(.white.opacity(0.2)))
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .topLeading) {
                    if let dateLabel = formattedDate {
                        Text(dateLabel)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(6)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.white.opacity(0.06), lineWidth: 1)
                )

            Text(movie.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(2)
        }
        .frame(width: 110)
    }

    private var formattedDate: String? {
        guard let raw = movie.releaseDate else { return nil }
        let parts = raw.split(separator: "-")
        guard parts.count == 3,
              let month = Int(parts[1]),
              let day = Int(parts[2]) else { return nil }
        let months = ["Oca","Şub","Mar","Nis","May","Haz","Tem","Ağu","Eyl","Eki","Kas","Ara"]
        guard month >= 1, month <= 12 else { return nil }
        return "\(day) \(months[month - 1])"
    }
}

// MARK: - Curated List Card

struct CuratedListCard: View {
    let list: CuratedList

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon
            Image(systemName: list.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            Spacer()

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(list.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(list.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(width: 140, height: 130)
        .background(GrippdTheme.Colors.surface.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var accentColor: Color {
        Color(hex: list.accentHex) ?? GrippdTheme.Colors.accent
    }
}

// MARK: - Shimmer

private struct ShimmerView: View {
    @State private var phase: CGFloat = -1.0

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                gradient: Gradient(colors: [.clear, .white.opacity(0.08), .clear]),
                startPoint: .leading, endPoint: .trailing
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
    func shimmering() -> some View { self.overlay(ShimmerView()) }
}

private extension Color {
    init?(hex: String) {
        var str = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasPrefix("#") { str.removeFirst() }
        guard str.count == 6, let value = UInt64(str, radix: 16) else { return nil }
        self.init(
            red:   Double((value >> 16) & 0xFF) / 255,
            green: Double((value >>  8) & 0xFF) / 255,
            blue:  Double( value        & 0xFF) / 255
        )
    }
}
