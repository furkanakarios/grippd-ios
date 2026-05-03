import SwiftUI

/// Full-screen avatar viewer with smooth appear/dismiss animation.
struct AvatarZoomView: View {
    let url: URL?
    @Binding var isPresented: Bool

    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(opacity * 0.85)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            if let url {
                CachedAsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 280, height: 280)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
                    } else {
                        avatarPlaceholder
                    }
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if abs(value.translation.height) > 60 { dismiss() }
                        }
                )
            } else {
                avatarPlaceholder
                    .scaleEffect(scale)
                    .opacity(opacity)
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.15), in: Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                    .opacity(opacity)
                }
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(GrippdTheme.Colors.accent.opacity(0.12))
            .frame(width: 280, height: 280)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.3))
            )
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            scale = 0.6
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            isPresented = false
        }
    }
}
