import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AuthViewModel()
    @State private var showEmailAuth = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 16) {
                    Image(systemName: "film.stack.fill")
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(.primary)

                    Text("Grippd")
                        .font(.system(size: 42, weight: .bold, design: .rounded))

                    Text("Film, dizi ve kitap günlüğün")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(height: 50)
                    } else {
                        // Apple
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = viewModel.generateNonce()
                        } onCompletion: { result in
                            Task { await viewModel.handleAppleSignIn(result: result, appState: appState) }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(12)

                        // Divider
                        HStack {
                            Rectangle().frame(height: 1).foregroundStyle(.separator)
                            Text("veya").font(.caption).foregroundStyle(.secondary)
                            Rectangle().frame(height: 1).foregroundStyle(.separator)
                        }

                        // Email
                        Button {
                            showEmailAuth = true
                        } label: {
                            Label("E-posta ile devam et", systemImage: "envelope")
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .buttonStyle(.bordered)
                        .cornerRadius(12)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .task {
            await viewModel.restoreSession(appState: appState)
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView(isPresented: $showEmailAuth)
                .environment(appState)
        }
    }
}

#Preview {
    SignInView()
        .environment(AppState())
}
