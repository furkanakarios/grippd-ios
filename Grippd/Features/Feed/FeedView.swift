import SwiftUI

// MARK: - ViewModel

@Observable
private final class FeedViewModel {
    var activities: [FeedActivity] = []
    var suggestions: [FeedSuggestionService.SuggestionSection] = []
    var isLoading = false
    var isLoadingMore = false
    var isLoadingSuggestions = false
    var error: String?
    var hasMore = true
    private var currentPage = 0

    func load(userInterests: [String]) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        currentPage = 0
        hasMore = true
        do {
            let result = try await FeedService.shared.fetchFeed(page: 0)
            activities = result
            hasMore = result.count == 20
            if result.isEmpty {
                await loadSuggestions(interests: userInterests)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        currentPage += 1
        do {
            let result = try await FeedService.shared.fetchFeed(page: currentPage)
            activities.append(contentsOf: result)
            hasMore = result.count == 20
        } catch {}
        isLoadingMore = false
    }

    func refresh(userInterests: [String]) async {
        await load(userInterests: userInterests)
    }

    func toggleLike(activityID: UUID) async {
        guard let idx = activities.firstIndex(where: { $0.id == activityID }) else { return }
        let wasLiked = activities[idx].isLiked
        HapticManager.light()
        // Optimistic update
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            activities[idx].isLiked = !wasLiked
            activities[idx].likeCount += wasLiked ? -1 : 1
        }
        if wasLiked {
            await LikeService.shared.unlike(logID: activityID)
        } else {
            await LikeService.shared.like(logID: activityID)
        }
    }

    private func loadSuggestions(interests: [String]) async {
        isLoadingSuggestions = true
        suggestions = await FeedSuggestionService.shared.fetchSuggestions(interests: interests)
        isLoadingSuggestions = false
    }
}

// MARK: - FeedView

struct FeedView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = FeedViewModel()
    @State private var selectedActivityForComments: FeedActivity?

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.feedPath) {
            ZStack {
                GrippdBackground()
                content
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: FeedRoute.self) { route in
                feedDestination(route)
            }
            .task { await viewModel.load(userInterests: appState.currentUser?.interests ?? []) }
            .refreshable { await viewModel.refresh(userInterests: appState.currentUser?.interests ?? []) }
            .sheet(item: $selectedActivityForComments) { activity in
                CommentsSheetView(
                    logID: activity.id,
                    contentTitle: activity.contentTitle,
                    isPremium: appState.isPremium,
                    commentCount: commentCountBinding(for: activity.id)
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.activities.isEmpty {
            loadingView
        } else if let error = viewModel.error, viewModel.activities.isEmpty {
            errorView(error)
        } else if viewModel.activities.isEmpty {
            emptyFeedView
        } else {
            feedList
        }
    }

    // MARK: - Feed List

    private var feedList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.activities) { activity in
                    FeedActivityCard(activity: activity) {
                        navigateToContent(activity)
                    } onUserTap: {
                        router.feedPath.append(FeedRoute.userProfile(userID: activity.user.id))
                    } onLike: {
                        Task { await viewModel.toggleLike(activityID: activity.id) }
                    } onComment: {
                        selectedActivityForComments = activity
                    } onShare: {
                        Task {
                            await ShareService.shared.present(item: ShareItem(
                                contentTitle: activity.contentTitle,
                                posterURL: activity.posterURL,
                                rating: activity.rating,
                                emoji: activity.emoji,
                                username: activity.user.displayName,
                                isOwnLog: false,
                                contentType: activity.contentType
                            ))
                        }
                    }
                    Divider()
                        .background(.white.opacity(0.06))

                    // Sonsuz scroll tetikleyici
                    if activity.id == viewModel.activities.last?.id {
                        Color.clear.frame(height: 1)
                            .onAppear { Task { await viewModel.loadMore() } }
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(GrippdTheme.Colors.accent)
                        .padding(.vertical, GrippdTheme.Spacing.lg)
                }
            }
            .padding(.bottom, GrippdTheme.Spacing.xxl)
        }
    }

    // MARK: - States

    private var loadingView: some View {
        GrippdLoadingView(label: "Yükleniyor...")
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: GrippdTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.5))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Tekrar Dene") {
                Task { await viewModel.load(userInterests: appState.currentUser?.interests ?? []) }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(GrippdTheme.Colors.accent)
            .buttonStyle(.press)
        }
    }

    private var emptyFeedView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Başlık
                VStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .font(.system(size: 48))
                        .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.25))
                    Text("Feed boş")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Takip ettiğin kişilerin aktiviteleri\nburada görünecek.")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                    Button {
                        appState.selectedTab = .search
                    } label: {
                        Text("Kullanıcı Ara")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(GrippdTheme.Colors.background)
                            .frame(height: 44)
                            .padding(.horizontal, 28)
                            .background(GrippdTheme.Colors.accent, in: Capsule())
                    }
                }
                .padding(.top, 40)

                // Öneriler
                if viewModel.isLoadingSuggestions {
                    ProgressView().tint(GrippdTheme.Colors.accent)
                } else if !viewModel.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Senin İçin Öneriler")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, GrippdTheme.Spacing.md)

                        ForEach(viewModel.suggestions) { section in
                            SuggestionSectionRow(section: section) { content in
                                navigateToSuggestion(content)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, GrippdTheme.Spacing.xxl)
        }
    }

    private func commentCountBinding(for activityID: UUID) -> Binding<Int> {
        Binding(
            get: { viewModel.activities.first(where: { $0.id == activityID })?.commentCount ?? 0 },
            set: { newCount in
                if let idx = viewModel.activities.firstIndex(where: { $0.id == activityID }) {
                    viewModel.activities[idx].commentCount = newCount
                }
            }
        )
    }

    private func navigateToSuggestion(_ content: Content) {
        if let tmdbID = content.tmdbID {
            switch content.contentType {
            case .movie:
                router.feedPath.append(FeedRoute.movieDetail(tmdbID: tmdbID))
            case .tv_show:
                router.feedPath.append(FeedRoute.tvShowDetail(tmdbID: tmdbID))
            case .book:
                break
            }
        } else if let booksID = content.googleBooksID {
            router.feedPath.append(FeedRoute.bookDetail(googleBooksID: booksID))
        }
    }

    // MARK: - Navigation

    private func navigateToContent(_ activity: FeedActivity) {
        let parts = activity.contentKey.split(separator: "-", maxSplits: 1)
        guard parts.count == 2 else { return }
        let idStr = String(parts[1])
        switch activity.contentType {
        case .movie:
            if let id = Int(idStr) { router.feedPath.append(FeedRoute.movieDetail(tmdbID: id)) }
        case .tv_show:
            if let id = Int(idStr) { router.feedPath.append(FeedRoute.tvShowDetail(tmdbID: id)) }
        case .book:
            router.feedPath.append(FeedRoute.bookDetail(googleBooksID: idStr))
        }
    }

    @ViewBuilder
    private func feedDestination(_ route: FeedRoute) -> some View {
        switch route {
        case .movieDetail(let tmdbID):
            MovieDetailView(tmdbID: tmdbID)
        case .tvShowDetail(let tmdbID):
            TVShowDetailView(tmdbID: tmdbID) { showID, seasonNumber in
                router.feedPath.append(FeedRoute.seasonDetail(showID: showID, seasonNumber: seasonNumber))
            }
        case .seasonDetail(let showID, let seasonNumber):
            SeasonDetailView(showID: showID, seasonNumber: seasonNumber) { sID, sNum, epNum in
                router.feedPath.append(FeedRoute.episodeDetail(showID: sID, seasonNumber: sNum, episodeNumber: epNum))
            }
        case .episodeDetail(let showID, let seasonNumber, let episodeNumber):
            EpisodeDetailView(showID: showID, seasonNumber: seasonNumber, episodeNumber: episodeNumber)
        case .bookDetail(let googleBooksID):
            BookDetailView(googleBooksID: googleBooksID)
        case .personDetail: Text("Kişi Detay — Phase 4").foregroundStyle(.white)
        case .contentDetail: Text("İçerik Detay").foregroundStyle(.white)
        case .userProfile(let userID): UserProfileView(userID: userID)
        }
    }
}

// MARK: - Suggestion Section

private struct SuggestionSectionRow: View {
    let section: FeedSuggestionService.SuggestionSection
    let onTap: (Content) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(section.emoji)
                Text(section.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(section.items) { content in
                        Button { onTap(content) } label: {
                            SuggestionCard(content: content)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, GrippdTheme.Spacing.md)
            }
        }
    }
}

private struct SuggestionCard: View {
    let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.clear
                .aspectRatio(2/3, contentMode: .fit)
                .frame(width: 90)
                .overlay(
                    Group {
                        if let url = content.posterURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fill)
                                default:
                                    posterPlaceholder
                                }
                            }
                        } else {
                            posterPlaceholder
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(content.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(2)
                .frame(width: 90, alignment: .leading)

            if let rating = content.averageRating, rating > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow.opacity(0.8))
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .frame(width: 90)
    }

    private var posterPlaceholder: some View {
        Rectangle()
            .fill(GrippdTheme.Colors.surface)
            .overlay(
                Image(systemName: content.contentType == .book ? "book.closed" : "film")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.15))
            )
    }
}

// MARK: - Activity Card

struct FeedActivityCard: View {
    let activity: FeedActivity
    let onContentTap: () -> Void
    let onUserTap: () -> Void
    let onLike: () -> Void
    let onComment: () -> Void
    var onShare: (() -> Void)? = nil

    private var typeIcon: String {
        switch activity.contentType {
        case .movie:   return "film"
        case .tv_show: return "tv"
        case .book:    return "book.closed"
        }
    }

    private var relativeTime: String {
        let diff = Date().timeIntervalSince(activity.watchedAt)
        switch diff {
        case ..<60:           return "az önce"
        case ..<3600:         return "\(Int(diff/60))d önce"
        case ..<86400:        return "\(Int(diff/3600))s önce"
        case ..<604800:       return "\(Int(diff/86400))g önce"
        default:
            return activity.watchedAt.formatted(.dateTime.day().month(.abbreviated))
        }
    }

    var body: some View {
        Button(action: onContentTap) {
            HStack(alignment: .top, spacing: 12) {
                // Avatar
                Button(action: onUserTap) {
                    UserAvatarView(
                        url: activity.user.avatarURL,
                        size: 42
                    )
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    // Başlık satırı
                    HStack(spacing: 4) {
                        Text(activity.user.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(activity.isRewatch ? "tekrar izledi" : "izledi")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.45))
                        Spacer()
                        Text(relativeTime)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    // İçerik satırı
                    HStack(spacing: 10) {
                        // Poster
                        Color.clear
                            .aspectRatio(2/3, contentMode: .fit)
                            .frame(width: 52)
                            .overlay(
                                AsyncImage(url: activity.posterURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    default:
                                        Rectangle()
                                            .fill(GrippdTheme.Colors.surface)
                                            .overlay(
                                                Image(systemName: typeIcon)
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(.white.opacity(0.2))
                                            )
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.contentTitle)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(2)

                            HStack(spacing: 8) {
                                if let rating = activity.rating, rating > 0 {
                                    StarRatingBadge(rating: rating, fontSize: 12)
                                }
                                if let emoji = activity.emoji {
                                    Text(emoji).font(.system(size: 16))
                                }
                            }

                            HStack(spacing: 4) {
                                Image(systemName: typeIcon)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.3))
                                if activity.isRewatch {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 10))
                                        .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.7))
                                }
                            }
                        }
                        Spacer()

                        // Aksiyon butonları
                        HStack(spacing: 14) {
                            // Yorum butonu
                            Button(action: onComment) {
                                HStack(spacing: 4) {
                                    Image(systemName: "bubble.left")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.35))
                                    if activity.commentCount > 0 {
                                        Text(verbatim: "\(activity.commentCount)")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(0.35))
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            // Like butonu
                            Button(action: onLike) {
                                HStack(spacing: 4) {
                                    Image(systemName: activity.isLiked ? "heart.fill" : "heart")
                                        .font(.system(size: 15))
                                        .foregroundStyle(activity.isLiked ? .red : .white.opacity(0.35))
                                    if activity.likeCount > 0 {
                                        Text(verbatim: "\(activity.likeCount)")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(0.35))
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            // Paylaş butonu
                            if let onShare {
                                Button(action: onShare) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.35))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
