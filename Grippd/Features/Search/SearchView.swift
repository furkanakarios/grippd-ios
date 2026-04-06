import SwiftUI

struct SearchView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = SearchViewModel()

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
            .navigationDestination(for: SearchRoute.self) { route in
                searchDestination(route)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.4))

            TextField("Film, dizi veya kitap ara...", text: $viewModel.query)
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
            ProgressView()
                .tint(GrippdTheme.Colors.accent)
            Spacer()
        } else if viewModel.query.count < 2 {
            emptyPrompt
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

    private var emptyPrompt: some View {
        VStack(spacing: GrippdTheme.Spacing.md) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.25))
            Text("Film, dizi veya kitap ara")
                .font(GrippdTheme.Typography.title)
                .foregroundStyle(.white.opacity(0.6))
            Text("En az 2 karakter gir")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.3))
            Spacer()
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

    @ViewBuilder
    private func resultRow(result: TMDBSearchResult) -> some View {
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
            Divider()
                .background(.white.opacity(0.06))
                .padding(.leading, 86)

        case .tv(let show):
            Button {
                // TV detail comes in Phase 2 Step 2
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
            .opacity(0.7)
            Divider()
                .background(.white.opacity(0.06))
                .padding(.leading, 86)

        case .unknown:
            EmptyView()
        }
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func searchDestination(_ route: SearchRoute) -> some View {
        switch route {
        case .movieDetail(let tmdbID):
            MovieDetailView(tmdbID: tmdbID)
        case .contentDetail:
            Text("İçerik Detay — Phase 3")
                .foregroundStyle(.white)
        case .userProfile:
            Text("Kullanıcı Profil — Phase 4")
                .foregroundStyle(.white)
        }
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

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
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
