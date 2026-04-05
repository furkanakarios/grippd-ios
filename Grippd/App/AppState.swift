import SwiftUI

@Observable
final class AppState {
    var isAuthenticated: Bool = false
    var currentUser: User?
    var selectedTab: AppTab = .feed

    enum AppTab {
        case feed, search, discover, profile
    }
}
