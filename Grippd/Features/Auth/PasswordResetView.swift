import SwiftUI
import Auth

struct PasswordResetView: View {
    @Environment(AppState.self) private var appState
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isSuccess = false

    var body: some View {
        ZStack {
            GrippdBackground()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: GrippdTheme.Spacing.xl) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(GrippdTheme.Colors.accent.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: isSuccess ? "checkmark.circle.fill" : "lock.rotation")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(GrippdTheme.Colors.accent)
                    }

                    VStack(spacing: 8) {
                        Text(isSuccess ? "Şifre güncellendi!" : "Yeni şifreni belirle")
                            .font(GrippdTheme.Typography.headline)
                            .foregroundStyle(.white)
                        Text(isSuccess
                             ? "Artık yeni şifrenle giriş yapabilirsin."
                             : "En az 6 karakter olmalı.")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.45))
                            .multilineTextAlignment(.center)
                    }

                    if !isSuccess {
                        VStack(spacing: 10) {
                            GrippdTextField(
                                placeholder: "Yeni şifre",
                                text: $newPassword,
                                icon: "lock",
                                isSecure: true
                            )

                            GrippdTextField(
                                placeholder: "Yeni şifre tekrar",
                                text: $confirmPassword,
                                icon: "lock.fill",
                                isSecure: true
                            )

                            if let error = errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text(error)
                                }
                                .font(.system(size: 13))
                                .foregroundStyle(.red.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.sm))
                            }
                        }

                        GrippdPrimaryButton("Şifreyi Güncelle", isLoading: isLoading) {
                            Task { await updatePassword() }
                        }
                    } else {
                        GrippdPrimaryButton("Giriş Yap") {
                            appState.pendingDeepLink = nil
                        }
                    }
                }
                .padding(.horizontal, GrippdTheme.Spacing.xl)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func updatePassword() async {
        guard newPassword.count >= 6 else {
            errorMessage = "Şifre en az 6 karakter olmalı."
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Şifreler eşleşmiyor."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await SupabaseClientService.shared.client.auth.update(
                user: UserAttributes(password: newPassword)
            )
            await MainActor.run {
                isSuccess = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Şifre güncellenemedi. Lütfen tekrar dene."
                isLoading = false
            }
        }
    }
}
