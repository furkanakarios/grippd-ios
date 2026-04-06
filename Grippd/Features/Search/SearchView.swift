import SwiftUI

struct SearchView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.searchPath) {
            ZStack {
                GrippdBackground()
                VStack(spacing: GrippdTheme.Spacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.3))
                    Text("Arama")
                        .font(GrippdTheme.Typography.headline)
                        .foregroundStyle(.white)
                    Text("Phase 2'de geliyor")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
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

    @ViewBuilder
    private func searchDestination(_ route: SearchRoute) -> some View {
        switch route {
        case .contentDetail: Text("İçerik Detay — Phase 2")
        case .userProfile: Text("Kullanıcı Profil — Phase 4")
        }
    }
}
