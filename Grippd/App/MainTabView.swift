import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var router = AppRouter.shared

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            FeedView()
                .tabItem { Label("Feed", systemImage: "house.fill") }
                .tag(AppState.AppTab.feed)

            SearchView()
                .tabItem { Label("Ara", systemImage: "magnifyingglass") }
                .tag(AppState.AppTab.search)

            DiscoverView()
                .tabItem { Label("Keşfet", systemImage: "compass.drawing") }
                .tag(AppState.AppTab.discover)

            ProfileView()
                .tabItem { Label("Profil", systemImage: "person.circle.fill") }
                .tag(AppState.AppTab.profile)
        }
        .tint(GrippdTheme.Colors.accent)
        .preferredColorScheme(.dark)
        .environment(router)
        .onAppear {
            // Tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(GrippdTheme.Colors.background).withAlphaComponent(0.95)
            appearance.shadowColor = .clear
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
