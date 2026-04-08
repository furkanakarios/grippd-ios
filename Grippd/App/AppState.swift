import SwiftUI

@Observable
final class AppState {
    var isCheckingAuth: Bool = true   // splash gösterim için
    var isAuthenticated: Bool = false
    var currentUser: User?
    var needsOnboarding: Bool = false
    var selectedTab: AppTab = .feed
    var pendingDeepLink: DeepLink?
    var unreadNotificationCount: Int = 0

    enum AppTab {
        case feed, search, discover, profile
    }

    enum DeepLink {
        case passwordReset
    }
}
