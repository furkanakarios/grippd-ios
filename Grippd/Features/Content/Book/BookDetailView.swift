import SwiftUI

// MARK: - ViewModel

@Observable
private final class BookDetailViewModel {
    var book: GoogleBook?
    var isLoading = false
    var error: String?
    var isBookmarked = false

    func load(googleBooksID: String) async {
        guard book == nil else { return }
        isLoading = true
        error = nil
        do {
            book = try await GoogleBooksClient.shared.volumeDetail(id: googleBooksID)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    var authorsDisplay: String {
        book?.volumeInfo.authors?.joined(separator: ", ") ?? ""
    }

    var formattedRatingsCount: String {
        guard let count = book?.volumeInfo.ratingsCount else { return "" }
        if count >= 1000 {
            return String(format: "%.1fB değerlendirme", Double(count) / 1000)
        }
        return "\(count) değerlendirme"
    }

    var mainCategory: String? {
        book?.volumeInfo.categories?.first
    }
}

// MARK: - View

struct BookDetailView: View {
    let googleBooksID: String

    @State private var viewModel = BookDetailViewModel()
    @State private var showFullDescription = false
    @State private var showLogSheet = false
    @State private var isLogged = false
    @State private var loggedRating: Double? = nil
    @State private var loggedEmoji: String? = nil

    private var contentKey: String { "book-\(googleBooksID)" }

    var body: some View {
        ZStack {
            GrippdBackground()

            if viewModel.isLoading {
                VStack(spacing: GrippdTheme.Spacing.md) {
                    ProgressView().scaleEffect(1.4).tint(GrippdTheme.Colors.accent)
                    Text("Yükleniyor...").font(.system(size: 14)).foregroundStyle(.white.opacity(0.4))
                }
            } else if let error = viewModel.error {
                VStack(spacing: GrippdTheme.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle").font(.system(size: 40))
                        .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.6))
                    Text(error).font(.system(size: 14)).foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center).padding(.horizontal, 32)
                }
            } else if let book = viewModel.book {
                bookContent(book: book)
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle(viewModel.book?.volumeInfo.title ?? "Kitap")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load(googleBooksID: googleBooksID) }
        .onAppear { refreshLogState() }
        .sheet(isPresented: $showLogSheet) {
            LogEntrySheet(
                contentKey: contentKey,
                contentType: .book,
                contentTitle: viewModel.book?.volumeInfo.title ?? "",
                posterPath: viewModel.book?.volumeInfo.imageLinks?.thumbnail,
                isPresented: $showLogSheet
            ) {
                refreshLogState()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func refreshLogState() {
        let log = LogService.shared.latestLog(for: contentKey)
        isLogged = log != nil
        loggedRating = log?.rating
        loggedEmoji = log?.emoji
    }

    // MARK: - Main Content

    private func bookContent(book: GoogleBook) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                coverHero(book: book)
                infoSection(book: book)
                actionButtons
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                    .padding(.top, GrippdTheme.Spacing.lg)
                CommunityStatsView(contentKey: "book-\(googleBooksID)")
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                    .padding(.top, GrippdTheme.Spacing.sm)

                if let description = book.volumeInfo.description {
                    descriptionSection(description)
                }
                metaSection(book: book)
            }
            .padding(.bottom, GrippdTheme.Spacing.xxl)
        }
    }

    // MARK: - Cover Hero

    private func coverHero(book: GoogleBook) -> some View {
        ZStack {
            // Blurred cover background
            AsyncImage(url: book.volumeInfo.imageLinks?.largeURL) { phase in
                if case .success(let image) = phase {
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 220)
                        .clipped()
                        .blur(radius: 24)
                        .overlay(Color.black.opacity(0.55))
                }
            }
            .frame(height: 220)
            .clipped()

            // Cover image on top
            AsyncImage(url: book.volumeInfo.imageLinks?.largeURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                default:
                    RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                        .fill(GrippdTheme.Colors.surface)
                        .overlay(
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.2))
                        )
                        .frame(width: 110, height: 160)
                }
            }
            .frame(height: 160)
            .cornerRadius(GrippdTheme.Radius.md)
            .shadow(color: .black.opacity(0.6), radius: 16, y: 8)
        }
        .frame(height: 220)
    }

    // MARK: - Info Section

    private func infoSection(book: GoogleBook) -> some View {
        VStack(spacing: 6) {
            Text(book.volumeInfo.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, GrippdTheme.Spacing.lg)

            if let subtitle = book.volumeInfo.subtitle {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, GrippdTheme.Spacing.lg)
            }

            if !viewModel.authorsDisplay.isEmpty {
                Text(viewModel.authorsDisplay)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(GrippdTheme.Colors.accent)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, GrippdTheme.Spacing.lg)
            }

            // Rating + metadata chips
            HStack(spacing: 12) {
                if let rating = book.volumeInfo.averageRating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(GrippdTheme.Colors.accent)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        if !viewModel.formattedRatingsCount.isEmpty {
                            Text("·")
                                .foregroundStyle(.white.opacity(0.3))
                            Text(viewModel.formattedRatingsCount)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }
                }

                if let pages = book.volumeInfo.pageCount {
                    BookMetaChip(icon: "doc.text", label: "\(pages) sayfa")
                }

                if let year = book.volumeInfo.publishYear {
                    BookMetaChip(icon: "calendar", label: year)
                }
            }
            .padding(.top, 4)

            if let category = viewModel.mainCategory {
                Text(category)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.07), in: Capsule())
                    .padding(.top, 4)
            }
        }
        .padding(.top, GrippdTheme.Spacing.lg)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showLogSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isLogged ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 16))
                    Text(isLogged ? "Okundu" : "Okudum")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(isLogged ? GrippdTheme.Colors.background : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    isLogged
                        ? GrippdTheme.Colors.accent
                        : Color.white.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                )
            }
            .overlay(alignment: .topTrailing) {
                if loggedRating != nil || loggedEmoji != nil {
                    LogBadge(emoji: loggedEmoji, rating: loggedRating, fontSize: 12)
                        .offset(x: 4, y: -5)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: loggedRating != nil || loggedEmoji != nil)

            Button {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.isBookmarked.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16))
                    Text(viewModel.isBookmarked ? "Listede" : "Listele")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
            }
        }
    }

    // MARK: - Description

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Özet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Text(description)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(5)
                .lineLimit(showFullDescription ? nil : 5)

            if description.count > 300 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showFullDescription.toggle()
                    }
                } label: {
                    Text(showFullDescription ? "Daha az" : "Devamını oku")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.top, GrippdTheme.Spacing.lg)
    }

    // MARK: - Meta Section

    private func metaSection(book: GoogleBook) -> some View {
        VStack(spacing: 0) {
            if let publisher = book.volumeInfo.publisher {
                BookMetaRow(label: "Yayınevi", value: publisher)
            }
            if let date = book.volumeInfo.publishedDate {
                BookMetaRow(label: "Yayın Tarihi", value: date)
            }
            if let isbn = book.volumeInfo.isbn {
                BookMetaRow(label: "ISBN", value: isbn)
            }
            if let lang = book.volumeInfo.language?.uppercased() {
                BookMetaRow(label: "Dil", value: lang)
            }
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.top, GrippdTheme.Spacing.lg)
    }
}

// MARK: - Supporting Views

private struct BookMetaChip: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.55))
        }
    }
}

private struct BookMetaRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
        .overlay(
            Divider()
                .background(.white.opacity(0.07)),
            alignment: .bottom
        )
    }
}
