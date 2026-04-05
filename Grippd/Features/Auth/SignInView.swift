import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AuthViewModel()

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
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = viewModel.generateNonce()
                        } onCompletion: { result in
                            Task { await viewModel.handleAppleSignIn(result: result, appState: appState) }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
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
    }
}

#Preview {
    SignInView()
        .environment(AppState())
}
