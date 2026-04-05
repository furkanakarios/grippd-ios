import SwiftUI

struct ContentView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                // Auth flow — Faz 1 Step 4-5'te implementte edilecek
                AuthPlaceholderView()
            }
        }
    }
}

// MARK: - Placeholder — Auth ekranı Faz 1 Step 4-5'te gelecek
private struct AuthPlaceholderView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "film.stack")
                .font(.system(size: 64))
                .foregroundStyle(.primary)
            Text("Grippd")
                .font(.largeTitle.bold())
            Text("Film, dizi ve kitap günlüğün")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Devam Et (Dev)") {
                appState.isAuthenticated = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Placeholder — MainTabView Faz 1 Step 7'de gelecek
private struct MainTabView: View {
    var body: some View {
        TabView {
            Text("Feed")
                .tabItem { Label("Feed", systemImage: "house") }
            Text("Search")
                .tabItem { Label("Ara", systemImage: "magnifyingglass") }
            Text("Discover")
                .tabItem { Label("Keşfet", systemImage: "compass.drawing") }
            Text("Profile")
                .tabItem { Label("Profil", systemImage: "person.circle") }
        }
    }
}
