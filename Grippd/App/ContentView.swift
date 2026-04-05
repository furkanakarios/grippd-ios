import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                SignInView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
    }
}

// MARK: - Placeholder — Step 7'de NavigationRouter ile değiştirilecek
private struct MainTabView: View {
    var body: some View {
        TabView {
            Text("Feed")
                .tabItem { Label("Feed", systemImage: "house") }
            Text("Search")
                .tabItem { Label("Ara", systemImage: "magnifyingglass") }
            Text("Discover")
                .tabItem { Label("Keşfet", systemImage: "compass.drawing") }
            Text("Profil")
                .tabItem { Label("Profil", systemImage: "person.circle") }
        }
    }
}
