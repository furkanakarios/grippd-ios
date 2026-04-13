import SwiftUI

struct CustomListDetailView: View {
    let list: CustomList
    @Environment(AppRouter.self) private var router
    @State private var items: [CustomListItem] = []
    @State private var showEditSheet = false

    var body: some View {
        @Bindable var router = router
        ZStack {
            GrippdBackground()

            if items.isEmpty {
                GrippdEmptyStateView(
                    icon: "list.bullet",
                    title: "Liste boş",
                    subtitle: "İçerik detay sayfalarından bu listeye ekleyebilirsin"
                )
            } else {
                List {
                    ForEach(items) { item in
                        Button {
                            navigate(item: item)
                        } label: {
                            CustomListItemRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                CustomListService.shared.removeItem(from: list, contentKey: item.contentKey)
                                items = list.items.sorted { $0.addedAt > $1.addedAt }
                            } label: {
                                Label("Çıkar", systemImage: "trash")
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(.white.opacity(0.06))
                        .listRowInsets(EdgeInsets())
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("\(list.emoji) \(list.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .onAppear {
            items = list.items.sorted { $0.addedAt > $1.addedAt }
        }
        .sheet(isPresented: $showEditSheet) {
            CustomListFormSheet(isPresented: $showEditSheet, existingList: list) { _ in
                items = list.items.sorted { $0.addedAt > $1.addedAt }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private func navigate(item: CustomListItem) {
        let parts = item.contentKey.split(separator: "-", maxSplits: 1)
        guard parts.count == 2 else { return }
        let idStr = String(parts[1])
        switch item.contentType {
        case .movie:
            if let id = Int(idStr) { router.profilePath.append(ProfileRoute.movieDetail(tmdbID: id)) }
        case .tv_show:
            if let id = Int(idStr) { router.profilePath.append(ProfileRoute.tvShowDetail(tmdbID: id)) }
        case .book:
            router.profilePath.append(ProfileRoute.bookDetail(googleBooksID: idStr))
        }
    }
}

// MARK: - Row

private struct CustomListItemRow: View {
    let item: CustomListItem

    private var typeIcon: String {
        switch item.contentType {
        case .movie: return "film"
        case .tv_show: return "tv"
        case .book: return "book.closed"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(GrippdTheme.Colors.surface)
                        .overlay(Image(systemName: typeIcon).font(.system(size: 16)).foregroundStyle(.white.opacity(0.2)))
                }
            }
            .frame(width: 48, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.contentTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: typeIcon).font(.system(size: 10))
                    Text(item.contentType == .movie ? "Film" : item.contentType == .tv_show ? "Dizi" : "Kitap")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
