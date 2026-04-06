import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: stepProgress)
                    .tint(.primary)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .animation(.easeInOut, value: viewModel.currentStep)

                // Step content
                Group {
                    switch viewModel.currentStep {
                    case .username:
                        UsernameStepView(viewModel: viewModel)
                    case .interests:
                        InterestsStepView(viewModel: viewModel)
                    case .avatar:
                        AvatarStepView(viewModel: viewModel)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.currentStep != .username {
                        Button {
                            withAnimation { viewModel.previousStep() }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
            }
        }
    }

    private var stepProgress: Double {
        switch viewModel.currentStep {
        case .username: return 1/3
        case .interests: return 2/3
        case .avatar: return 1.0
        }
    }
}

// MARK: - Step 1: Username

private struct UsernameStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Kullanıcı adın ne olsun?")
                    .font(.title.bold())
                Text("Başkaları seni bu isimle bulacak.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("@")
                        .foregroundStyle(.secondary)
                    TextField("kullaniciadi", text: $viewModel.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.username) { viewModel.onUsernameChange() }
                }
                .padding(12)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))

                // Status indicator
                Group {
                    if viewModel.isCheckingUsername {
                        HStack(spacing: 6) {
                            ProgressView().scaleEffect(0.7)
                            Text("Kontrol ediliyor...")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    } else if let available = viewModel.isUsernameAvailable {
                        HStack(spacing: 6) {
                            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(available ? "Kullanılabilir" : "Bu kullanıcı adı alınmış")
                        }
                        .font(.caption)
                        .foregroundStyle(available ? .green : .red)
                    } else if viewModel.username.count > 0 && viewModel.username.count < 3 {
                        Text("En az 3 karakter olmalı")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 20)

                TextField("Görünen ad (opsiyonel)", text: $viewModel.displayName)
                    .padding(12)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
            }

            Spacer()

            Button {
                withAnimation { viewModel.nextStep() }
            } label: {
                Text("Devam Et")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canProceedFromUsername)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }
}

// MARK: - Step 2: Interests

private struct InterestsStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ne izler/okursun?")
                    .font(.title.bold())
                Text("En az 3 tane seç — keşif önerilerin buna göre şekillenecek.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ContentInterest.allCases) { interest in
                        InterestChip(
                            interest: interest,
                            isSelected: viewModel.selectedInterests.contains(interest)
                        ) {
                            if viewModel.selectedInterests.contains(interest) {
                                viewModel.selectedInterests.remove(interest)
                            } else {
                                viewModel.selectedInterests.insert(interest)
                            }
                        }
                    }
                }
            }

            Button {
                withAnimation { viewModel.nextStep() }
            } label: {
                Text("Devam Et")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedInterests.count < 3)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }
}

private struct InterestChip: View {
    let interest: ContentInterest
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(interest.emoji)
                    .font(.title2)
                Text(interest.rawValue)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(in: RoundedRectangle(cornerRadius: 12))
            .backgroundStyle(isSelected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.quaternary))
            .foregroundStyle(isSelected ? Color(uiColor: .systemBackground) : Color.primary)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 3: Avatar

private struct AvatarStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Profil fotoğrafı ekle")
                    .font(.title.bold())
                Text("İstersen atlayabilirsin, sonradan da ekleyebilirsin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Avatar preview
            PhotosPicker(selection: $viewModel.avatarItem, matching: .images) {
                ZStack {
                    if let image = viewModel.avatarImage {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(uiColor: .quaternarySystemFill))
                            .frame(width: 120, height: 120)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                            }
                    }

                    Circle()
                        .strokeBorder(.primary.opacity(0.2), lineWidth: 1)
                        .frame(width: 120, height: 120)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.black.opacity(0.6), in: Circle())
                        .offset(x: 40, y: 40)
                }
            }
            .onChange(of: viewModel.avatarItem) {
                Task { await viewModel.loadAvatar() }
            }

            Spacer()

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    Task { await viewModel.complete(appState: appState) }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("Başlayalım!")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)

                Button {
                    Task { await viewModel.complete(appState: appState) }
                } label: {
                    Text("Şimdilik atla")
                        .foregroundStyle(.secondary)
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }
}
