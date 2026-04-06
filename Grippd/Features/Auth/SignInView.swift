import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AuthViewModel()
    @State private var showEmailAuth = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            GrippdBackground()

            VStack(spacing: 0) {
                Spacer()

                // MARK: Logo
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GrippdTheme.Colors.accent.opacity(0.15))
                            .frame(width: 90, height: 90)
                            .blur(radius: 20)

                        Image(systemName: "film.stack.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(GrippdTheme.Colors.accent)
                    }

                    Text("Grippd")
                        .font(GrippdTheme.Typography.appName)
                        .foregroundStyle(.white)

                    Text("Film, dizi ve kitap günlüğün")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.white.opacity(0.45))
                        .tracking(0.3)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Spacer()

                // MARK: Auth Buttons
                VStack(spacing: 12) {
                    // Apple
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(GrippdTheme.Colors.accent)
                            .frame(height: 54)
                    } else {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = viewModel.generateNonce()
                        } onCompletion: { result in
                            Task { await viewModel.handleAppleSignIn(result: result, appState: appState) }
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
                    }

                    GrippdDivider(label: "veya")

                    // Email
                    GrippdSecondaryButton("E-posta ile devam et", icon: "envelope") {
                        showEmailAuth = true
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }

                    // Terms
                    Text("Devam ederek [Kullanım Koşulları](https://grippd.app/terms) ve [Gizlilik Politikası](https://grippd.app/privacy)'nı kabul etmiş olursun.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.25))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .tint(GrippdTheme.Colors.accent)
                }
                .padding(.horizontal, GrippdTheme.Spacing.xl)
                .padding(.bottom, GrippdTheme.Spacing.xxl)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.restoreSession(appState: appState)
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView(isPresented: $showEmailAuth)
                .environment(appState)
        }
    }
}

#Preview {
    SignInView().environment(AppState())
}
