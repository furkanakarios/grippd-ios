import SwiftUI

struct CuratedListDetailView: View {
    @Environment(AppRouter.self) private var router
    let list: CuratedList

    @State private var items: [CuratedItem] = []
    @State private var isLoading = true

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            GrippdBackground()
            if isLoading {
                ProgressView()
                    .tint(GrippdTheme.Colors.accent)
            } else if items.isEmpty {
                ContentUnavailableView("İçerik bulunamadı", systemImage: list.icon)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(items) { item in
                            Button {
                                navigate(item)
                            } label: {
                                CuratedItemCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                    .padding(.vertical, GrippdTheme.Spacing.sm)
                }
            }
        }
        .navigationTitle(list.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        items = await CuratedListService.shared.fetchItems(for: list)
        isLoading = false
    }

    private func navigate(_ item: CuratedItem) {
        switch item {
        case .movie(let m):
            router.discoverPath.append(DiscoverRoute.movieDetail(tmdbID: m.id))
        case .tv(let t):
            router.discoverPath.append(DiscoverRoute.tvShowDetail(tmdbID: t.id))
        case .book(let b):
            router.discoverPath.append(DiscoverRoute.bookDetail(googleBooksID: b.id))
        }
    }
}

// MARK: - Curated Item Card

struct CuratedItemCard: View {
    let item: CuratedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Poster
            Color.clear
                .aspectRatio(2/3, contentMode: .fit)
                .overlay(
                    AsyncImage(url: item.posterURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Rectangle()
                                .fill(GrippdTheme.Colors.surface)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundStyle(.white.opacity(0.2))
                                )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.white.opacity(0.06), lineWidth: 1)
                )

            // Title
            Text(item.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(2)

            // Rating
            if let rating = item.rating {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }
}
