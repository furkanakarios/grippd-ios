import Foundation
import RevenueCat
import Supabase

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
    private let client = SupabaseClientService.shared.client
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
        if !result.userCancelled {
            await syncPremiumStatus(customerInfo: result.customerInfo)
        }
        return !result.userCancelled
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        let info = try await Purchases.shared.restorePurchases()
        await syncPremiumStatus(customerInfo: info)
    }

    // MARK: - Sync with Supabase

    func syncPremiumStatus(customerInfo: CustomerInfo? = nil) async {
        let info: CustomerInfo?
        if let provided = customerInfo {
            info = provided
        } else {
            info = try? await Purchases.shared.customerInfo()
        }
        guard let info else { return }
        let isPremiumActive = info.entitlements[GrippdProduct.entitlement]?.isActive == true
        let planType = isPremiumActive ? "premium" : "free"

        guard let userID = client.auth.currentUser?.id else { return }
        try? await client
            .from("users")
            .update(["plan_type": planType])
            .eq("id", value: userID.uuidString)
            .execute()
    }

    // MARK: - Login sync (RevenueCat kullanıcıya bağla)

    func login(userID: String) async {
        _ = try? await Purchases.shared.logIn(userID)
    }

    func logout() async {
        _ = try? await Purchases.shared.logOut()
    }
}
