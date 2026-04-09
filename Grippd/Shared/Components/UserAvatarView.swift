import SwiftUI

struct UserAvatarView: View {
    let url: URL?
    let size: CGFloat
    var isPremium: Bool = false

    private var badgeSize: CGFloat { size * 0.24 }
    private var ringWidth: CGFloat { size * 0.055 }

    var body: some View {
        ZStack {
            avatarCircle

            if isPremium {
                // Outer glow ring
                Circle()
                    .stroke(
                        Color(red: 1.0, green: 0.80, blue: 0.0).opacity(0.35),
                        lineWidth: ringWidth + 6
                    )
                    .frame(width: size, height: size)
                    .blur(radius: 5)

                // Main gold ring
                Circle()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 1.00, green: 0.95, blue: 0.50), location: 0.0),
                                .init(color: Color(red: 0.98, green: 0.78, blue: 0.08), location: 0.35),
                                .init(color: Color(red: 0.88, green: 0.60, blue: 0.00), location: 0.65),
                                .init(color: Color(red: 1.00, green: 0.92, blue: 0.40), location: 1.0),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: ringWidth
                    )
                    .frame(width: size, height: size)

                // Crown badge at bottom center
                ZStack {
                    Circle()
                        .fill(Color(red: 0.10, green: 0.08, blue: 0.04))
                        .frame(width: badgeSize, height: badgeSize)
                        .shadow(color: Color(red: 1.0, green: 0.78, blue: 0.0).opacity(0.5), radius: 5)

                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.00, green: 0.95, blue: 0.50),
                                    Color(red: 0.88, green: 0.60, blue: 0.00),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: ringWidth * 0.7
                        )
                        .frame(width: badgeSize, height: badgeSize)

                    Text("👑")
                        .font(.system(size: badgeSize * 0.52))
                }
                .offset(y: size * 0.44)
            }
        }
        .frame(width: size, height: isPremium ? size + badgeSize * 0.5 : size)
    }

    private var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(GrippdTheme.Colors.accent.opacity(0.1))
                .frame(width: size, height: size)

            if let url {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        placeholderIcon
                    }
                }
                .frame(width: size - 6, height: size - 6)
                .clipShape(Circle())
            } else {
                placeholderIcon
            }
        }
        .frame(width: size, height: size)
    }

    private var placeholderIcon: some View {
        Image(systemName: "person.fill")
            .font(.system(size: size * 0.4))
            .foregroundStyle(.white.opacity(0.3))
    }
}
