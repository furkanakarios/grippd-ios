import SwiftUI

struct FeedView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.feedPath) {
            ZStack {
                GrippdBackground()
                VStack(spacing: GrippdTheme.Spacing.md) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.3))
                    Text("Feed")
                        .font(GrippdTheme.Typography.headline)
                        .foregroundStyle(.white)
                    Text("Phase 2'de geliyor")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: FeedRoute.self) { route in
                feedDestination(route)
            }
        }
    }

    @ViewBuilder
    private func feedDestination(_ route: FeedRoute) -> some View {
        switch route {
        case .movieDetail(let tmdbID): MovieDetailView(tmdbID: tmdbID)
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
        case .personDetail: Text("Kişi Detay — Phase 3").foregroundStyle(.white)
        case .contentDetail: Text("İçerik Detay — Phase 3").foregroundStyle(.white)
        case .userProfile(let userID): UserProfileView(userID: userID)
        }
    }
}
