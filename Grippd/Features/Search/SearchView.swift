import SwiftUI

struct SearchView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = SearchViewModel()
    @State private var showAddContent = false

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.searchPath) {
            ZStack {
                GrippdBackground()

                VStack(spacing: 0) {
                    searchBar
                    filterBar
                    resultsList
                }
            }
            .navigationTitle("Ara")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddContent = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .sheet(isPresented: $showAddContent) {
                AddCustomContentView {
                    viewModel.onQueryChange()
                }
            }
            .navigationDestination(for: SearchRoute.self) { route in
                searchDestination(route)
            }
            .task { await viewModel.loadTrending() }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.4))

            TextField("Film, dizi, kitap veya kişi ara...", text: $viewModel.query)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .tint(GrippdTheme.Colors.accent)
                .autocorrectionDisabled()
                .onChange(of: viewModel.query) { viewModel.onQueryChange() }

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                    viewModel.results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.top, GrippdTheme.Spacing.md)
        .padding(.bottom, GrippdTheme.Spacing.sm)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchFilter.allCases, id: \.self) { filter in
                    Button {
                        viewModel.filter = filter
                        viewModel.onQueryChange()
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(viewModel.filter == filter ? GrippdTheme.Colors.background : .white.opacity(0.6))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                viewModel.filter == filter
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

    // MARK: - Results

    @ViewBuilder
    private var resultsList: some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView().tint(GrippdTheme.Colors.accent)
            Spacer()
        } else if viewModel.query.count < 2 {
            emptyState
        } else if viewModel.results.isEmpty {
            noResults
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.results) { result in
                        resultRow(result: result)
                    }
                }
                .padding(.bottom, GrippdTheme.Spacing.xl)
            }
        }
    }

    // MARK: - Empty State (geçmiş + trend)

    private var emptyState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GrippdTheme.Spacing.xl) {

                // Son Aramalar
                if !viewModel.searchHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Son Aramalar")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.45))
                                .textCase(.uppercase)
                                .tracking(1.2)
                            Spacer()
                            Button("Temizle") {
                                withAnimation { viewModel.clearHistory() }
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(GrippdTheme.Colors.accent)
                        }

                        ForEach(viewModel.searchHistory, id: \.self) { item in
                            Button {
                                viewModel.selectSuggestion(item)
                            } label: {
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.3))
                                    Text(item)
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white.opacity(0.8))
                                    Spacer()
                                    Button {
                                        withAnimation { viewModel.removeHistory(item) }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(.white.opacity(0.25))
                                    }
                                }
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Divider().background(.white.opacity(0.06))
                        }
                    }
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                }

                // Trend İçerikler
                if !viewModel.trendingSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trend İçerikler")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.45))
                            .textCase(.uppercase)
                            .tracking(1.2)
                            .padding(.horizontal, GrippdTheme.Spacing.md)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.trendingSuggestions, id: \.self) { suggestion in
                                    Button {
                                        viewModel.selectSuggestion(suggestion)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "flame")
                                                .font(.system(size: 11))
                                                .foregroundStyle(GrippdTheme.Colors.accent)
                                            Text(suggestion)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.white.opacity(0.8))
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(.white.opacity(0.07), in: Capsule())
                                        .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.horizontal, GrippdTheme.Spacing.md)
                        }
                    }
                }

                // İpucu (geçmiş ve trend yoksa)
                if viewModel.searchHistory.isEmpty && viewModel.trendingSuggestions.isEmpty {
                    VStack(spacing: GrippdTheme.Spacing.md) {
                        Spacer(minLength: 60)
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.25))
                        Text("Film, dizi, kitap veya kişi ara")
                            .font(GrippdTheme.Typography.title)
                            .foregroundStyle(.white.opacity(0.6))
                        Text("En az 2 karakter gir")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, GrippdTheme.Spacing.lg)
            .padding(.bottom, GrippdTheme.Spacing.xxl)
        }
    }

    private var noResults: some View {
        VStack(spacing: GrippdTheme.Spacing.md) {
            Spacer()
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.2))
            Text("Sonuç bulunamadı")
                .font(GrippdTheme.Typography.title)
                .foregroundStyle(.white.opacity(0.6))
            Text("\"\(viewModel.query)\" için eşleşme yok")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.35))
            Spacer()
        }
    }

    // MARK: - Result Rows

    @ViewBuilder
    private func resultRow(result: UnifiedSearchResult) -> some View {
        switch result {
        case .movie(let movie):
            Button {
                router.searchPath.append(SearchRoute.movieDetail(tmdbID: movie.id))
            } label: {
                SearchResultCell(
                    posterURL: movie.posterURL,
                    title: movie.title,
                    subtitle: [movie.releaseYear, "Film"].compactMap { $0 }.joined(separator: " · "),
                    rating: movie.voteAverage,
                    typeIcon: "film"
                )
            }
            .buttonStyle(.plain)
            Divider().background(.white.opacity(0.06)).padding(.leading, 86)

        case .tv(let show):
            Button {
                router.searchPath.append(SearchRoute.tvShowDetail(tmdbID: show.id))
            } label: {
                SearchResultCell(
                    posterURL: show.posterURL,
                    title: show.name,
                    subtitle: [show.firstAirYear, "Dizi"].compactMap { $0 }.joined(separator: " · "),
                    rating: show.voteAverage,
                    typeIcon: "tv"
                )
            }
            .buttonStyle(.plain)
            Divider().background(.white.opacity(0.06)).padding(.leading, 86)

        case .book(let book):
            Button {
                router.searchPath.append(SearchRoute.bookDetail(googleBooksID: book.id))
            } label: {
                SearchResultCell(
                    posterURL: book.volumeInfo.imageLinks?.thumbnailURL,
                    title: book.volumeInfo.title,
                    subtitle: [
                        book.volumeInfo.authors?.first,
                        book.volumeInfo.publishYear,
                        "Kitap"
                    ].compactMap { $0 }.joined(separator: " · "),
                    rating: book.volumeInfo.averageRating ?? 0,
                    typeIcon: "book.closed"
                )
            }
            .buttonStyle(.plain)
            Divider().background(.white.opacity(0.06)).padding(.leading, 86)

        case .person(let person):
            Button {
                router.searchPath.append(SearchRoute.personDetail(tmdbID: person.id))
            } label: {
                PersonResultCell(person: person)
            }
            .buttonStyle(.plain)
            Divider().background(.white.opacity(0.06)).padding(.leading, 86)

        case .userContent(let content):
            Button {
                router.searchPath.append(SearchRoute.contentDetail(contentID: content.id))
            } label: {
                UserContentResultCell(content: content)
            }
            .buttonStyle(.plain)
            Divider().background(.white.opacity(0.06)).padding(.leading, 86)
        }
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func searchDestination(_ route: SearchRoute) -> some View {
        switch route {
        case .movieDetail(let tmdbID):
            MovieDetailView(tmdbID: tmdbID)
        case .tvShowDetail(let tmdbID):
            TVShowDetailView(tmdbID: tmdbID) { showID, seasonNumber in
                router.searchPath.append(SearchRoute.seasonDetail(showID: showID, seasonNumber: seasonNumber))
            }
        case .seasonDetail(let showID, let seasonNumber):
            SeasonDetailView(showID: showID, seasonNumber: seasonNumber) { sID, sNum, epNum in
                router.searchPath.append(SearchRoute.episodeDetail(showID: sID, seasonNumber: sNum, episodeNumber: epNum))
            }
        case .episodeDetail(let showID, let seasonNumber, let episodeNumber):
            EpisodeDetailView(showID: showID, seasonNumber: seasonNumber, episodeNumber: episodeNumber)
        case .bookDetail(let googleBooksID):
            BookDetailView(googleBooksID: googleBooksID)
        case .personDetail(let tmdbID):
            PersonDetailPlaceholderView(tmdbID: tmdbID)
        case .contentDetail(let contentID):
            CustomContentDetailView(contentID: contentID)
        case .userProfile:
            Text("Kullanıcı Profil — Phase 4").foregroundStyle(.white)
        }
    }
}

// MARK: - Person Result Cell

struct PersonResultCell: View {
    let person: TMDBPerson

    var body: some View {
        HStack(spacing: GrippdTheme.Spacing.md) {
            AsyncImage(url: person.profileURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Circle()
                        .fill(GrippdTheme.Colors.surface)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.2))
                        )
                }
            }
            .frame(width: 54, height: 54)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white.opacity(0.08), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(person.departmentDisplay)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Search Result Cell

struct SearchResultCell: View {
    let posterURL: URL?
    let title: String
    let subtitle: String
    let rating: Double
    let typeIcon: String

    var body: some View {
        HStack(spacing: GrippdTheme.Spacing.md) {
            AsyncImage(url: posterURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(GrippdTheme.Colors.surface)
                        .overlay(
                            Image(systemName: typeIcon)
                                .font(.system(size: 18))
                                .foregroundStyle(.white.opacity(0.2))
                        )
                }
            }
            .frame(width: 54, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.45))

                if rating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(GrippdTheme.Colors.accent)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - User Content Result Cell

struct UserContentResultCell: View {
    let content: Content

    private var typeIcon: String {
        switch content.contentType {
        case .movie: return "film"
        case .tv_show: return "tv"
        case .book: return "book.closed"
        }
    }

    private var typeLabel: String {
        switch content.contentType {
        case .movie: return "Film"
        case .tv_show: return "Dizi"
        case .book: return "Kitap"
        }
    }

    var body: some View {
        HStack(spacing: GrippdTheme.Spacing.md) {
            AsyncImage(url: content.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(GrippdTheme.Colors.accent.opacity(0.12))
                        .overlay(
                            Image(systemName: typeIcon)
                                .font(.system(size: 18))
                                .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.6))
                        )
                }
            }
            .frame(width: 54, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(GrippdTheme.Colors.accent.opacity(0.3), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(content.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text([content.releaseYear.map { "\($0)" }, typeLabel].compactMap { $0 }.joined(separator: " · "))
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.45))
                }

                // "Senin eklediğin" badge
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                    Text("Senin eklediğin")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(GrippdTheme.Colors.accent)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Person Detail Placeholder

private struct PersonDetailPlaceholderView: View {
    let tmdbID: Int

    var body: some View {
        ZStack {
            GrippdBackground()
            VStack(spacing: GrippdTheme.Spacing.md) {
                Image(systemName: "person.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.3))
                Text("Kişi Detay")
                    .font(GrippdTheme.Typography.headline)
                    .foregroundStyle(.white)
                Text("Phase 3'te geliyor")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .navigationTitle("Kişi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
