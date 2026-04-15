import Foundation
import AuthenticationServices
import CryptoKit

@Observable
final class AuthViewModel {

    var isLoading = false
    var errorMessage: String?

    private let authService = AuthService.shared
    private var currentNonce: String?

    // Called by AppState on launch to restore session
    func restoreSession(appState: AppState) async {
        guard let user = try? await authService.restoreSession() else { return }
        async let needsOnboarding = OnboardingService.shared.needsOnboarding(userID: user.id)
        async let unreadCount = NotificationService.shared.unreadCount()
        async let premium = PurchaseService.shared.isPremium()
        let (onboarding, count, rcPremium) = await ((try? needsOnboarding) ?? false, unreadCount, premium)
        await MainActor.run {
            appState.currentUser = user
            appState.needsOnboarding = onboarding
            appState.isAuthenticated = true
            appState.unreadNotificationCount = count
            appState.isPremium = rcPremium || user.planType == .premium
            LogService.shared.setOwner(user.id.uuidString)
        }
        Task { await LogSyncService.shared.syncPending() }
        Task { await PurchaseService.shared.login(userID: user.id.uuidString) }
    }

    // MARK: - Sign in with Apple

    func handleAppleSignIn(
        result: Result<ASAuthorization, Error>,
        appState: AppState
    ) async {
        switch result {
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                errorMessage = "Apple kimlik bilgileri alınamadı."
                return
            }

            isLoading = true
            errorMessage = nil

            do {
                let user = try await authService.signInWithApple(idToken: idToken, nonce: nonce)
                async let needsOnboarding = OnboardingService.shared.needsOnboarding(userID: user.id)
                async let unreadCount = NotificationService.shared.unreadCount()
                async let premium = PurchaseService.shared.isPremium()
                let (onboarding, count, rcPremium) = await ((try? needsOnboarding) ?? false, unreadCount, premium)
                await MainActor.run {
                    appState.currentUser = user
                    appState.needsOnboarding = onboarding
                    appState.isAuthenticated = true
                    appState.unreadNotificationCount = count
                    appState.isPremium = rcPremium || user.planType == .premium
                    isLoading = false
                    LogService.shared.setOwner(user.id.uuidString)
                }
                Task { await LogSyncService.shared.syncPending() }
                Task { await PurchaseService.shared.login(userID: user.id.uuidString) }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }

        case .failure(let error as ASAuthorizationError) where error.code == .canceled:
            break // User dismissed — no error shown

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    func signOut(appState: AppState) async {
        try? await authService.signOut()
        await MainActor.run {
            appState.currentUser = nil
            appState.isAuthenticated = false
            LogService.shared.clearOwner()
        }
    }

    // MARK: - Nonce

    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
