import SwiftUI

@Observable
@MainActor
final class AppState {
    var isCheckingAuth: Bool = true   // splash gösterim için
    var isAuthenticated: Bool = false
    var currentUser: User? {
        didSet {
            if let user = currentUser {
                LogService.shared.setOwner(user.id.uuidString)
            } else {
                LogService.shared.clearOwner()
            }
        }
    }
    var needsOnboarding: Bool = false
    var selectedTab: AppTab = .feed
    var pendingDeepLink: DeepLink?

    enum AppTab {
        case feed, search, discover, profile
    }

    enum DeepLink {
        case passwordReset
    }
}
