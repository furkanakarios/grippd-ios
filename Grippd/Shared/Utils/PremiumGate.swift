import SwiftUI

// MARK: - Premium Feature Definitions

enum PremiumFeature {
    case createList(currentCount: Int)
    case postComment(monthlyCount: Int)
    case addCustomContent
    case unlimitedDiscover
}

// MARK: - Premium Gate

enum PremiumGate {

    // MARK: - Limits

    static let maxFreeLists = 3
    static let maxFreeCommentsPerMonth = 20
    static let freeDiscoverItemLimit = 12
    static let premiumDiscoverItemLimit = 20

    // MARK: - Gate Check

    /// Returns true if the action is allowed (either free tier allows it, or user is premium).
    static func isAllowed(_ feature: PremiumFeature, isPremium: Bool) -> Bool {
        if isPremium { return true }
        switch feature {
        case .createList(let count):
            return count < maxFreeLists
        case .postComment(let monthlyCount):
            return monthlyCount < maxFreeCommentsPerMonth
        case .addCustomContent:
            return false
        case .unlimitedDiscover:
            return false
        }
    }

    /// Returns remaining free allowance for metered features, nil for binary gates.
    static func remaining(_ feature: PremiumFeature, isPremium: Bool) -> Int? {
        if isPremium { return nil }
        switch feature {
        case .createList(let count):
            return max(0, maxFreeLists - count)
        case .postComment(let monthlyCount):
            return max(0, maxFreeCommentsPerMonth - monthlyCount)
        case .addCustomContent, .unlimitedDiscover:
            return nil
        }
    }
}

