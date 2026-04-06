import SwiftUI

enum EmailAuthMode {
    case signIn, signUp, forgotPassword
}

struct EmailAuthView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = EmailAuthViewModel()
    @State private var mode: EmailAuthMode = .signIn
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            GrippdBackground()

            VStack(spacing: 0) {
                // Handle bar
                Capsule()
                    .fill(.white.opacity(0.15))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // Header
                HStack {
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.08), in: Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, GrippdTheme.Spacing.lg)
                .padding(.bottom, GrippdTheme.Spacing.md)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: GrippdTheme.Spacing.xl) {

                        // Title
                        VStack(alignment: .leading, spacing: 6) {
                            Text(navigationTitle)
                                .font(GrippdTheme.Typography.headline)
                                .foregroundStyle(.white)
                            Text(navigationSubtitle)
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        .padding(.horizontal, GrippdTheme.Spacing.lg)

                        // Mode switcher (signIn / signUp)
                        if mode != .forgotPassword {
                            HStack(spacing: 0) {
                                ForEach([EmailAuthMode.signIn, .signUp], id: \.self) { tab in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) { mode = tab }
                                    } label: {
                                        Text(tab == .signIn ? "Giriş Yap" : "Kayıt Ol")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(mode == tab ? GrippdTheme.Colors.background : .white.opacity(0.5))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 40)
                                            .background(
                                                mode == tab
                                                ? AnyShapeStyle(GrippdTheme.Colors.accent)
                                                : AnyShapeStyle(Color.clear),
                                                in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.sm)
                                            )
                                    }
                                }
                            }
                            .padding(4)
                            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
                            .padding(.horizontal, GrippdTheme.Spacing.lg)
                        }

                        // Fields
                        VStack(spacing: 10) {
                            GrippdTextField(
                                placeholder: "E-posta adresi",
                                text: $viewModel.email,
                                icon: "envelope",
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress
                            )

                            if mode != .forgotPassword {
                                GrippdTextField(
                                    placeholder: "Şifre",
                                    text: $viewModel.password,
                                    icon: "lock",
                                    isSecure: true,
                                    textContentType: mode == .signUp ? .newPassword : .password
                                )
                            }

                            if mode == .signUp {
                                GrippdTextField(
                                    placeholder: "Şifre tekrar",
                                    text: $viewModel.confirmPassword,
                                    icon: "lock.fill",
                                    isSecure: true,
                                    textContentType: .newPassword
                                )
                            }
                        }
                        .padding(.horizontal, GrippdTheme.Spacing.lg)

                        // Messages
                        VStack(spacing: 8) {
                            if let error = viewModel.errorMessage {
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

                            if let success = viewModel.successMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text(success)
                                }
                                .font(.system(size: 13))
                                .foregroundStyle(.green.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.sm))
                            }
                        }
                        .padding(.horizontal, GrippdTheme.Spacing.lg)

                        // Primary CTA
                        GrippdPrimaryButton(primaryLabel, isLoading: viewModel.isLoading) {
                            Task { await primaryAction() }
                        }
                        .padding(.horizontal, GrippdTheme.Spacing.lg)

                        // Secondary links
                        VStack(spacing: 16) {
                            if mode == .signIn {
                                Button {
                                    withAnimation { mode = .forgotPassword }
                                } label: {
                                    Text("Şifremi unuttum")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.45))
                                        .underline()
                                }
                            }

                            if mode == .forgotPassword {
                                Button {
                                    withAnimation { mode = .signIn }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 12, weight: .semibold))
                                        Text("Giriş ekranına dön")
                                            .font(.system(size: 14))
                                    }
                                    .foregroundStyle(.white.opacity(0.45))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, GrippdTheme.Spacing.xxl)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: mode) {
            viewModel.errorMessage = nil
            viewModel.successMessage = nil
        }
    }

    // MARK: - Helpers

    private var primaryLabel: String {
        switch mode {
        case .signIn: return "Giriş Yap"
        case .signUp: return "Hesap Oluştur"
        case .forgotPassword: return "Sıfırlama Bağlantısı Gönder"
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .signIn: return "Hoş geldin"
        case .signUp: return "Hesap oluştur"
        case .forgotPassword: return "Şifreni mi unuttun?"
        }
    }

    private var navigationSubtitle: String {
        switch mode {
        case .signIn: return "Hesabına giriş yap"
        case .signUp: return "Grippd'a katılmak için birkaç adım"
        case .forgotPassword: return "E-postana sıfırlama bağlantısı göndereceğiz"
        }
    }

    private func primaryAction() async {
        switch mode {
        case .signIn: await viewModel.signIn(appState: appState)
        case .signUp: await viewModel.signUp(appState: appState)
        case .forgotPassword: await viewModel.sendPasswordReset()
        }
    }
}
