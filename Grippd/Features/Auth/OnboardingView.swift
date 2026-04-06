import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            GrippdBackground()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    if viewModel.currentStep != .username {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.previousStep()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Geri")
                                    .font(.system(size: 15))
                            }
                            .foregroundStyle(.white.opacity(0.5))
                        }
                    }

                    Spacer()

                    // Step indicator dots
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(stepIndex >= i ? GrippdTheme.Colors.accent : .white.opacity(0.2))
                                .frame(width: stepIndex == i ? 20 : 6, height: 6)
                                .animation(.spring(response: 0.4), value: stepIndex)
                        }
                    }

                    Spacer()

                    // Invisible back button placeholder for balance
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Geri")
                            .font(.system(size: 15))
                    }
                    .opacity(0)
                }
                .padding(.horizontal, GrippdTheme.Spacing.lg)
                .padding(.top, GrippdTheme.Spacing.md)
                .padding(.bottom, GrippdTheme.Spacing.lg)

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
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.currentStep)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var stepIndex: Int {
        switch viewModel.currentStep {
        case .username: return 0
        case .interests: return 1
        case .avatar: return 2
        }
    }
}

// MARK: - Step 1: Username

private struct UsernameStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Nasıl çağrılmak istersin?")
                    .font(GrippdTheme.Typography.headline)
                    .foregroundStyle(.white)
                Text("Kullanıcı adın herkese açık ve benzersiz olmalı.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, GrippdTheme.Spacing.lg)
            .padding(.bottom, GrippdTheme.Spacing.xl)

            VStack(spacing: 12) {
                // Username field
                HStack(spacing: 12) {
                    Text("@")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                        .frame(width: 20)

                    TextField("kullaniciadi", text: $viewModel.username)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .tint(GrippdTheme.Colors.accent)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.username) { viewModel.onUsernameChange() }

                    // Status icon
                    Group {
                        if viewModel.isCheckingUsername {
                            ProgressView().scaleEffect(0.7).tint(GrippdTheme.Colors.accent)
                        } else if let available = viewModel.isUsernameAvailable {
                            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(available ? .green : .red)
                        }
                    }
                    .frame(width: 24)
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                        .stroke(borderColor, lineWidth: 1)
                )

                // Status text
                if let available = viewModel.isUsernameAvailable {
                    HStack(spacing: 4) {
                        Image(systemName: available ? "checkmark.circle" : "xmark.circle")
                        Text(available ? "Kullanılabilir" : "Bu kullanıcı adı alınmış")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(available ? .green : .red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                } else if viewModel.username.count > 0 && viewModel.username.count < 3 {
                    Text("En az 3 karakter olmalı")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }

                GrippdTextField(
                    placeholder: "Görünen ad (opsiyonel)",
                    text: $viewModel.displayName,
                    icon: "person"
                )
            }
            .padding(.horizontal, GrippdTheme.Spacing.lg)

            Spacer()

            GrippdPrimaryButton("Devam Et") {
                withAnimation { viewModel.nextStep() }
            }
            .disabled(!viewModel.canProceedFromUsername)
            .opacity(viewModel.canProceedFromUsername ? 1 : 0.4)
            .padding(.horizontal, GrippdTheme.Spacing.lg)
            .padding(.bottom, GrippdTheme.Spacing.xxl)
        }
    }

    private var borderColor: Color {
        if let available = viewModel.isUsernameAvailable {
            return available ? .green.opacity(0.5) : .red.opacity(0.5)
        }
        return .white.opacity(0.1)
    }
}

// MARK: - Step 2: Interests

private struct InterestsStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Ne izler, ne okursun?")
                    .font(GrippdTheme.Typography.headline)
                    .foregroundStyle(.white)
                HStack(spacing: 0) {
                    Text("En az 3 seç")
                        .foregroundStyle(GrippdTheme.Colors.accent)
                    Text(" — keşif önerilerin buna göre şekillenecek.")
                        .foregroundStyle(.white.opacity(0.45))
                }
                .font(.system(size: 14))
            }
            .padding(.horizontal, GrippdTheme.Spacing.lg)
            .padding(.bottom, GrippdTheme.Spacing.lg)

            // Selected count badge
            HStack {
                Spacer()
                Text("\(viewModel.selectedInterests.count) seçildi")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(viewModel.selectedInterests.count >= 3
                        ? GrippdTheme.Colors.accent
                        : .white.opacity(0.3))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        viewModel.selectedInterests.count >= 3
                        ? GrippdTheme.Colors.accentMuted
                        : Color.white.opacity(0.06),
                        in: Capsule()
                    )
            }
            .padding(.horizontal, GrippdTheme.Spacing.lg)
            .padding(.bottom, GrippdTheme.Spacing.md)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(ContentInterest.allCases) { interest in
                        InterestChip(
                            interest: interest,
                            isSelected: viewModel.selectedInterests.contains(interest)
                        ) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                if viewModel.selectedInterests.contains(interest) {
                                    viewModel.selectedInterests.remove(interest)
                                } else {
                                    viewModel.selectedInterests.insert(interest)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, GrippdTheme.Spacing.lg)
                .padding(.bottom, GrippdTheme.Spacing.lg)
            }

            GrippdPrimaryButton("Devam Et") {
                withAnimation { viewModel.nextStep() }
            }
            .disabled(viewModel.selectedInterests.count < 3)
            .opacity(viewModel.selectedInterests.count >= 3 ? 1 : 0.4)
            .padding(.horizontal, GrippdTheme.Spacing.lg)
            .padding(.bottom, GrippdTheme.Spacing.xxl)
        }
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
                    .font(.system(size: 24))
                Text(interest.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(isSelected ? GrippdTheme.Colors.background : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                isSelected ? AnyShapeStyle(GrippdTheme.Colors.accent) : AnyShapeStyle(Color.white.opacity(0.07)),
                in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                    .stroke(
                        isSelected ? GrippdTheme.Colors.accent.opacity(0) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 3: Avatar

private struct AvatarStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Profil fotoğrafı")
                    .font(GrippdTheme.Typography.headline)
                    .foregroundStyle(.white)
                Text("İstersen atlayabilirsin, sonradan da ekleyebilirsin.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, GrippdTheme.Spacing.lg)
            .padding(.bottom, GrippdTheme.Spacing.xxl)

            // Avatar picker
            PhotosPicker(selection: $viewModel.avatarItem, matching: .images) {
                ZStack {
                    Circle()
                        .fill(GrippdTheme.Colors.accent.opacity(0.1))
                        .frame(width: 140, height: 140)

                    if let image = viewModel.avatarImage {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.white.opacity(0.2))
                    }

                    // Ring
                    Circle()
                        .strokeBorder(GrippdTheme.Colors.accent.opacity(0.4), lineWidth: 2)
                        .frame(width: 130, height: 130)

                    // Camera badge
                    ZStack {
                        Circle()
                            .fill(GrippdTheme.Colors.accent)
                            .frame(width: 34, height: 34)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(GrippdTheme.Colors.background)
                    }
                    .offset(x: 44, y: 44)
                }
            }
            .onChange(of: viewModel.avatarItem) {
                Task { await viewModel.loadAvatar() }
            }

            Spacer()

            if let error = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(error)
                }
                .font(.system(size: 13))
                .foregroundStyle(.red.opacity(0.9))
                .padding(12)
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.sm))
                .padding(.horizontal, GrippdTheme.Spacing.lg)
                .padding(.bottom, GrippdTheme.Spacing.md)
            }

            VStack(spacing: 12) {
                GrippdPrimaryButton(
                    viewModel.avatarImage != nil ? "Başlayalım!" : "Fotoğraf Seç",
                    isLoading: viewModel.isLoading
                ) {
                    if viewModel.avatarImage != nil {
                        Task { await viewModel.complete(appState: appState) }
                    } else {
                        // Trigger PhotosPicker — handled by the PhotosPicker above
                    }
                }

                Button {
                    Task { await viewModel.complete(appState: appState) }
                } label: {
                    Text("Şimdilik atla")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, GrippdTheme.Spacing.lg)
            .padding(.bottom, GrippdTheme.Spacing.xxl)
        }
        .frame(maxWidth: .infinity)
    }
}
