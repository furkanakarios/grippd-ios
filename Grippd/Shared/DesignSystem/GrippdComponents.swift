import SwiftUI

// MARK: - Primary Button

struct GrippdPrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(GrippdTheme.Colors.background)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(GrippdTheme.Colors.background)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(GrippdTheme.Colors.accent, in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
        }
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button

struct GrippdSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
        }
    }
}

// MARK: - Glass Text Field

struct GrippdTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 20)
            }

            if isSecure && !isRevealed {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .tint(GrippdTheme.Colors.accent)
                    .textContentType(textContentType)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .tint(GrippdTheme.Colors.accent)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .sentences)
                    .autocorrectionDisabled(keyboardType == .emailAddress)
                    .textContentType(textContentType)
            }

            if isSecure {
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Divider with label

struct GrippdDivider: View {
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(height: 1)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
                .fixedSize()
            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(height: 1)
        }
    }
}

// MARK: - Background

struct GrippdBackground: View {
    var body: some View {
        ZStack {
            GrippdTheme.Colors.background.ignoresSafeArea()
            GrippdTheme.Gradients.background.ignoresSafeArea()
            GrippdTheme.Gradients.accentGlow.ignoresSafeArea()
        }
    }
}

// MARK: - Press Button Style

struct PressButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressButtonStyle {
    static var press: PressButtonStyle { PressButtonStyle() }
    static func press(scale: CGFloat) -> PressButtonStyle { PressButtonStyle(scale: scale) }
}

// MARK: - Empty State View

struct GrippdEmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: GrippdTheme.Spacing.md) {
            Spacer(minLength: 48)

            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.25))

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.28))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, GrippdTheme.Spacing.xl)
                }
            }

            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(GrippdTheme.Colors.accent.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.press)
                .padding(.top, 4)
            }

            Spacer(minLength: 48)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Loading View

struct GrippdLoadingView: View {
    var label: String? = nil

    var body: some View {
        VStack(spacing: GrippdTheme.Spacing.sm) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(GrippdTheme.Colors.accent)
            if let label {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .frame(maxWidth: .infinity)
    }
}
