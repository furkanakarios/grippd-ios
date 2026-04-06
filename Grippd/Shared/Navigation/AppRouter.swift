import SwiftUI

// MARK: - Route Definitions

enum FeedRoute: Hashable {
    case userProfile(userID: UUID)
    case contentDetail(contentID: UUID)
}

enum SearchRoute: Hashable {
    case contentDetail(contentID: UUID)
    case userProfile(userID: UUID)
}

enum DiscoverRoute: Hashable {
    case contentDetail(contentID: UUID)
    case userProfile(userID: UUID)
    case genre(String)
}

enum ProfileRoute: Hashable {
    case editProfile
    case settings
    case followers(userID: UUID)
    case following(userID: UUID)
    case contentDetail(contentID: UUID)
    case userProfile(userID: UUID)
}

// MARK: - Router

@Observable
final class AppRouter {
    static let shared = AppRouter()

    var feedPath = NavigationPath()
    var searchPath = NavigationPath()
    var discoverPath = NavigationPath()
    var profilePath = NavigationPath()

    private init() {}

    func resetToRoot(tab: AppState.AppTab) {
        switch tab {
        case .feed:     feedPath = NavigationPath()
        case .search:   searchPath = NavigationPath()
        case .discover: discoverPath = NavigationPath()
        case .profile:  profilePath = NavigationPath()
        }
    }

    func resetAll() {
        feedPath = NavigationPath()
        searchPath = NavigationPath()
        discoverPath = NavigationPath()
        profilePath = NavigationPath()
    }
}
