import SwiftUI

// MARK: - Genre Browse ViewModel

@Observable
final class GenreBrowseViewModel {
    enum ContentKind { case movie, tv }

    let genre: TMDBGenre
    let kind: ContentKind

    var movies: [TMDBMovie] = []
    var shows: [TMDBTVShow] = []
    var isLoading = false
    var isLoadingMore = false
    var currentPage = 1
    var totalPages = 1
    var error: String?

    init(genre: TMDBGenre, kind: ContentKind) {
        self.genre = genre
        self.kind = kind
    }

    var hasMore: Bool { currentPage < totalPages }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        currentPage = 1
        do {
            switch kind {
            case .movie:
                let r = try await TMDBClient.shared.discoverMovies(genreID: genre.id, page: 1)
                movies = r.results
                totalPages = r.totalPages
            case .tv:
                let r = try await TMDBClient.shared.discoverTVShows(genreID: genre.id, page: 1)
                shows = r.results
                totalPages = r.totalPages
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore else { return }
        isLoadingMore = true
        let nextPage = currentPage + 1
        do {
            switch kind {
            case .movie:
                let r = try await TMDBClient.shared.discoverMovies(genreID: genre.id, page: nextPage)
                movies.append(contentsOf: r.results)
                currentPage = nextPage
                totalPages = r.totalPages
            case .tv:
                let r = try await TMDBClient.shared.discoverTVShows(genreID: genre.id, page: nextPage)
                shows.append(contentsOf: r.results)
                currentPage = nextPage
                totalPages = r.totalPages
            }
        } catch {
            // sessizce geç
        }
        isLoadingMore = false
    }
}

// MARK: - Genre Browse View

struct GenreBrowseView: View {
    @State var viewModel: GenreBrowseViewModel
    var onMovieTap: ((Int) -> Void)?
    var onTVTap: ((Int) -> Void)?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            GrippdBackground()

            if viewModel.isLoading {
                loadingGrid
            } else if let error = viewModel.error {
                errorView(error)
            } else {
                contentGrid
            }
        }
        .navigationTitle(viewModel.genre.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
    }

    // MARK: - Content Grid

    private var contentGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 12) {
                switch viewModel.kind {
                case .movie:
                    ForEach(viewModel.movies) { movie in
                        Button {
                            onMovieTap?(movie.id)
                        } label: {
                            GenrePosterCell(posterURL: movie.posterURL, title: movie.title, rating: movie.voteAverage)
                        }
                        .buttonStyle(.plain)
                        .task {
                            if movie.id == viewModel.movies.last?.id {
                                await viewModel.loadMore()
                            }
                        }
                    }
                case .tv:
                    ForEach(viewModel.shows) { show in
                        Button {
                            onTVTap?(show.id)
                        } label: {
                            GenrePosterCell(posterURL: show.posterURL, title: show.name, rating: show.voteAverage)
                        }
                        .buttonStyle(.plain)
                        .task {
                            if show.id == viewModel.shows.last?.id {
                                await viewModel.loadMore()
                            }
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(GrippdTheme.Colors.accent)
                        .frame(maxWidth: .infinity)
                        .gridCellColumns(3)
                        .padding(.vertical, GrippdTheme.Spacing.md)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, GrippdTheme.Spacing.md)
            .padding(.bottom, GrippdTheme.Spacing.xxl)
        }
    }

    // MARK: - Loading Skeleton

    private var loadingGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<12, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                        .fill(GrippdTheme.Colors.surface)
                        .aspectRatio(2/3, contentMode: .fit)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, GrippdTheme.Spacing.md)
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: GrippdTheme.Spacing.md) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.2))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, GrippdTheme.Spacing.lg)
        }
    }
}

// MARK: - Book Category Browse

@Observable
private final class BookCategoryBrowseViewModel {
    let categoryLabel: String
    let query: String

    var books: [GoogleBook] = []
    var isLoading = false
    var isLoadingMore = false
    var currentStartIndex = 0
    var totalItems = 0
    var error: String?

    private let pageSize = 20

    init(categoryLabel: String, query: String) {
        self.categoryLabel = categoryLabel
        self.query = query
    }

    var hasMore: Bool { books.count < totalItems }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        do {
            let response = try await GoogleBooksClient.shared.search(query: query, startIndex: 0, maxResults: pageSize)
            books = response.items ?? []
            totalItems = response.totalItems
            currentStartIndex = pageSize
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore else { return }
        isLoadingMore = true
        do {
            let response = try await GoogleBooksClient.shared.search(query: query, startIndex: currentStartIndex, maxResults: pageSize)
            books.append(contentsOf: response.items ?? [])
            currentStartIndex += pageSize
        } catch { }
        isLoadingMore = false
    }
}

struct BookCategoryBrowseView: View {
    let categoryLabel: String
    let query: String
    let onBookTap: (String) -> Void

    @State private var viewModel: BookCategoryBrowseViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(categoryLabel: String, query: String, onBookTap: @escaping (String) -> Void) {
        self.categoryLabel = categoryLabel
        self.query = query
        self.onBookTap = onBookTap
        self._viewModel = State(initialValue: BookCategoryBrowseViewModel(categoryLabel: categoryLabel, query: query))
    }

    var body: some View {
        ZStack {
            GrippdBackground()

            if viewModel.isLoading {
                loadingGrid
            } else if let error = viewModel.error {
                errorView(error)
            } else {
                contentGrid
            }
        }
        .navigationTitle(categoryLabel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
    }

    private var contentGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.books) { book in
                    Button {
                        onBookTap(book.id)
                    } label: {
                        GenrePosterCell(
                            posterURL: book.volumeInfo.imageLinks?.thumbnailURL,
                            title: book.volumeInfo.title,
                            rating: book.volumeInfo.averageRating ?? 0
                        )
                    }
                    .buttonStyle(.plain)
                    .task {
                        if book.id == viewModel.books.last?.id {
                            await viewModel.loadMore()
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(GrippdTheme.Colors.accent)
                        .frame(maxWidth: .infinity)
                        .gridCellColumns(3)
                        .padding(.vertical, GrippdTheme.Spacing.md)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, GrippdTheme.Spacing.md)
            .padding(.bottom, GrippdTheme.Spacing.xxl)
        }
    }

    private var loadingGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<12, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: GrippdTheme.Radius.sm)
                        .fill(GrippdTheme.Colors.surface)
                        .aspectRatio(2/3, contentMode: .fit)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, GrippdTheme.Spacing.md)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: GrippdTheme.Spacing.md) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.2))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, GrippdTheme.Spacing.lg)
        }
    }
}

// MARK: - Genre Poster Cell

struct GenrePosterCell: View {
    let posterURL: URL?
    let title: String
    let rating: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Görsel: her zaman 2:3 oranında, kaynak boyutundan bağımsız
            Color.clear
                .aspectRatio(2/3, contentMode: .fit)
                .overlay(
                    CachedAsyncImage(url: posterURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            Rectangle()
                                .fill(GrippdTheme.Colors.surface)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundStyle(.white.opacity(0.12))
                                        .font(.system(size: 18))
                                )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: GrippdTheme.Radius.sm))

            // Sabit yükseklikli metin alanı
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                HStack(spacing: 3) {
                    if rating > 0 {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(GrippdTheme.Colors.accent)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                .frame(height: 12)
            }
            .frame(height: 46)
        }
    }
}
