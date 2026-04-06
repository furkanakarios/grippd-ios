import SwiftUI

@main
struct GrippdApp: App {

    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onOpenURL { url in
                    Task {
                        // Supabase auth deep link handler (password reset, email confirm vs.)
                        try? await SupabaseClientService.shared.client.auth.session(from: url)
                    }
                }
        }
    }
}
