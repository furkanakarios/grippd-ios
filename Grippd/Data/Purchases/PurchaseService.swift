import Foundation
import RevenueCat

// MARK: - Product IDs

enum GrippdProduct {
    static let monthly = "monthly"
    static let yearly = "yearly"
    static let lifetime = "lifetime"
    static let entitlement = "grippd Pro"
}

// MARK: - Purchase Service

@MainActor
final class PurchaseService {
    static let shared = PurchaseService()
    private init() {}

    // MARK: - Setup

    static func configure() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatApiKey") as? String,
              !apiKey.isEmpty else {
            print("[PurchaseService] RevenueCat API key missing")
            return
        }
        Purchases.configure(withAPIKey: apiKey)
        Purchases.logLevel = .warn
    }

    // MARK: - Current Entitlement

    func isPremium() async -> Bool {
        guard let info = try? await Purchases.shared.customerInfo() else { return false }
        return info.entitlements[GrippdProduct.entitlement]?.isActive == true
    }

    // MARK: - Fetch Offerings

    func fetchOfferings() async throws -> Offerings {
        try await Purchases.shared.offerings()
    }

    // MARK: - Purchase

    func purchase(package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)
        return !result.userCancelled
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        _ = try await Purchases.shared.restorePurchases()
    }

    // MARK: - Login sync (RevenueCat kullanıcıya bağla)

    func login(userID: String) async {
        _ = try? await Purchases.shared.logIn(userID)
    }

    func logout() async {
        _ = try? await Purchases.shared.logOut()
    }
}
