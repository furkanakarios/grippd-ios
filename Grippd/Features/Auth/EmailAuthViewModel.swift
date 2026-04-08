import Foundation
import Supabase

@Observable
final class EmailAuthViewModel {

    // MARK: - State
    var email = ""
    var password = ""
    var confirmPassword = ""
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?

    private let client = SupabaseClientService.shared.client

    // MARK: - Sign Up

    func signUp(appState: AppState) async {
        guard validate(mode: .signUp) else { return }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await client.auth.signUp(email: email, password: password)

            if response.session != nil {
                // Auto-confirmed (email confirmation disabled in Supabase)
                let user = try await fetchProfile(id: response.user.id)
                await MainActor.run {
                    appState.currentUser = user
                    appState.needsOnboarding = true  // new signup always needs onboarding
                    appState.isAuthenticated = true
                    isLoading = false
                }
            } else {
                // Email confirmation required
                await MainActor.run {
                    successMessage = "Kayıt başarılı! E-postanı kontrol et ve hesabını onayla."
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = mapError(error)
                isLoading = false
            }
        }
    }

    // MARK: - Sign In

    func signIn(appState: AppState) async {
        guard validate(mode: .signIn) else { return }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await client.auth.signIn(email: email, password: password)
            let user = try await fetchProfile(id: session.user.id)
            async let needsOnboarding = OnboardingService.shared.needsOnboarding(userID: user.id)
            async let unreadCount = NotificationService.shared.unreadCount()
            let (onboarding, count) = await ((try? needsOnboarding) ?? false, unreadCount)
            await MainActor.run {
                appState.currentUser = user
                appState.needsOnboarding = onboarding
                appState.isAuthenticated = true
                appState.unreadNotificationCount = count
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = mapError(error)
                isLoading = false
            }
        }
    }

    // MARK: - Password Reset

    func sendPasswordReset() async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "E-posta adresi gir."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await client.auth.resetPasswordForEmail(
                email,
                redirectTo: URL(string: "grippd://auth/recovery")
            )
            await MainActor.run {
                successMessage = "Şifre sıfırlama bağlantısı \(email) adresine gönderildi."
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = mapError(error)
                isLoading = false
            }
        }
    }

    // MARK: - Validation

    private enum Mode { case signIn, signUp }

    private func validate(mode: Mode) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        guard !trimmedEmail.isEmpty, trimmedEmail.contains("@") else {
            errorMessage = "Geçerli bir e-posta adresi gir."
            return false
        }
        guard password.count >= 6 else {
            errorMessage = "Şifre en az 6 karakter olmalı."
            return false
        }
        if mode == .signUp {
            guard password == confirmPassword else {
                errorMessage = "Şifreler eşleşmiyor."
                return false
            }
        }
        return true
    }

    // MARK: - Profile Fetch

    private func fetchProfile(id: UUID) async throws -> User {
        // DB trigger creates profile; retry once if not yet available
        for attempt in 0...1 {
            if attempt == 1 { try await Task.sleep(for: .milliseconds(600)) }
            let rows: [UserRow] = try await client
                .from("users")
                .select()
                .eq("id", value: id.uuidString)
                .limit(1)
                .execute()
                .value
            if let row = rows.first {
                return row.toDomain()
            }
        }
        throw AuthError.profileCreationFailed
    }

    // MARK: - Error Mapping

    private func mapError(_ error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("invalid login") || message.contains("invalid credentials") {
            return "E-posta veya şifre hatalı."
        }
        if message.contains("already registered") || message.contains("already exists") {
            return "Bu e-posta adresi zaten kayıtlı."
        }
        if message.contains("network") || message.contains("internet") {
            return "İnternet bağlantını kontrol et."
        }
        return error.localizedDescription
    }
}
