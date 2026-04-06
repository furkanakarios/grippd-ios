import SwiftUI

struct DiscoverView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.discoverPath) {
            ZStack {
                GrippdBackground()
                VStack(spacing: GrippdTheme.Spacing.md) {
                    Image(systemName: "compass.drawing")
                        .font(.system(size: 48))
                        .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.3))
                    Text("Keşfet")
                        .font(GrippdTheme.Typography.headline)
                        .foregroundStyle(.white)
                    Text("Phase 5'te geliyor")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .navigationTitle("Keşfet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: DiscoverRoute.self) { route in
                discoverDestination(route)
            }
        }
    }

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
        case .contentDetail: Text("İçerik Detay — Phase 3").foregroundStyle(.white)
        case .userProfile: Text("Kullanıcı Profil — Phase 4").foregroundStyle(.white)
        case .genre(let name): Text("\(name) — Phase 5").foregroundStyle(.white)
        }
    }
}
