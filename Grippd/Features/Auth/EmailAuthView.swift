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
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Mode Picker (only for signIn/signUp)
                    if mode != .forgotPassword {
                        Picker("", selection: $mode) {
                            Text("Giriş Yap").tag(EmailAuthMode.signIn)
                            Text("Kayıt Ol").tag(EmailAuthMode.signUp)
                        }
                        .pickerStyle(.segmented)
                        .padding(.top, 8)
                    }

                    // Fields
                    VStack(spacing: 12) {
                        TextField("E-posta", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .textFieldStyle(.roundedBorder)

                        if mode != .forgotPassword {
                            SecureField("Şifre", text: $viewModel.password)
                                .textContentType(mode == .signUp ? .newPassword : .password)
                                .textFieldStyle(.roundedBorder)
                        }

                        if mode == .signUp {
                            SecureField("Şifre tekrar", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    // Messages
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let success = viewModel.successMessage {
                        Text(success)
                            .font(.caption)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Primary Action
                    Button {
                        Task { await primaryAction() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        } else {
                            Text(primaryLabel)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)

                    // Secondary
                    if mode == .signIn {
                        Button("Şifremi unuttum") {
                            withAnimation { mode = .forgotPassword }
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }

                    if mode == .forgotPassword {
                        Button("Giriş ekranına dön") {
                            withAnimation { mode = .signIn }
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { isPresented = false }
                }
            }
            .onChange(of: mode) {
                viewModel.errorMessage = nil
                viewModel.successMessage = nil
            }
        }
    }

    // MARK: - Helpers

    private var primaryLabel: String {
        switch mode {
        case .signIn: "Giriş Yap"
        case .signUp: "Kayıt Ol"
        case .forgotPassword: "Sıfırlama Bağlantısı Gönder"
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .signIn: "E-posta ile Giriş"
        case .signUp: "Hesap Oluştur"
        case .forgotPassword: "Şifremi Unuttum"
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
