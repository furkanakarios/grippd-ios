import UIKit
import SwiftUI

// MARK: - Share Item

struct ShareItem {
    let contentTitle: String
    let posterURL: URL?
    let rating: Double?
    let emoji: String?
    let username: String
    let isOwnLog: Bool
    let contentType: Content.ContentType
}

// MARK: - Share Service

@MainActor
final class ShareService {
    static let shared = ShareService()
    private init() {}

    func present(item: ShareItem) async {
        let posterImage = await downloadImage(url: item.posterURL)
        let cardImage = renderCard(item: item, posterImage: posterImage)

        let text = shareText(item: item)
        var activities: [Any] = [text]
        if let cardImage { activities.append(cardImage) }

        let instagramActivity = InstagramStoriesActivity(item: item, cardImage: cardImage)
        let vc = UIActivityViewController(
            activityItems: activities,
            applicationActivities: [instagramActivity]
        )

        guard let presenter = topViewController() else { return }
        if let popover = vc.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        presenter.present(vc, animated: true)
    }

    // MARK: - Helpers

    private func shareText(item: ShareItem) -> String {
        var parts = [String]()
        parts.append(item.isOwnLog
            ? "\"\(item.contentTitle)\" izledim"
            : "\(item.username), \"\(item.contentTitle)\" izledi"
        )
        if let rating = item.rating, rating > 0 {
            parts.append("⭐ \(String(format: "%.1f", rating))/10")
        }
        if let emoji = item.emoji { parts.append(emoji) }
        parts.append("#Grippd")
        return parts.joined(separator: " · ")
    }

    private func renderCard(item: ShareItem, posterImage: UIImage?) -> UIImage? {
        let view = ShareCardView(item: item, posterImage: posterImage)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }

    private func downloadImage(url: URL?) async -> UIImage? {
        guard let url else { return nil }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return UIImage(data: data)
    }

    private func topViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController?
            .topPresented()
    }
}

// MARK: - UIViewController helper

private extension UIViewController {
    func topPresented() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topPresented()
        }
        return self
    }
}

// MARK: - Instagram Stories Activity

private final class InstagramStoriesActivity: UIActivity {
    private let item: ShareItem
    private let cardImage: UIImage?

    init(item: ShareItem, cardImage: UIImage?) {
        self.item = item
        self.cardImage = cardImage
    }

    override var activityTitle: String? { "Instagram Stories" }
    override var activityImage: UIImage? { UIImage(systemName: "camera.fill") }
    override var activityType: UIActivity.ActivityType {
        UIActivity.ActivityType("com.grippd.share.instagramStories")
    }

    override class var activityCategory: UIActivity.Category { .share }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    override func perform() {
        guard let cardImage,
              let imageData = cardImage.pngData(),
              let url = URL(string: "instagram-stories://share?source_application=com.grippd.app") else {
            activityDidFinish(false)
            return
        }

        UIPasteboard.general.setItems(
            [["com.instagram.sharedSticker.backgroundImage": imageData]],
            options: [.expirationDate: Date().addingTimeInterval(60 * 5)]
        )
        UIApplication.shared.open(url, options: [:]) { [weak self] success in
            self?.activityDidFinish(success)
        }
    }
}

// MARK: - Share Card View

private struct ShareCardView: View {
    let item: ShareItem
    let posterImage: UIImage?

    private let W: CGFloat = 320
    private let H: CGFloat = 520
    private let accent = Color(red: 0.47, green: 0.82, blue: 0.64)

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer
            gradientOverlay
            contentLayer
            borderOverlay
        }
        .frame(width: W, height: H)
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }

    // MARK: - Layers

    private var backgroundLayer: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.10)
            if let poster = posterImage {
                Image(uiImage: poster)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: W, height: H)
                    .blur(radius: 30)
                    .opacity(0.55)
            }
        }
        .frame(width: W, height: H)
    }

    private var gradientOverlay: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.15), location: 0),
                .init(color: .black.opacity(0.10), location: 0.35),
                .init(color: .black.opacity(0.55), location: 0.60),
                .init(color: .black.opacity(0.92), location: 1.0),
            ],
            startPoint: .top, endPoint: .bottom
        )
        .frame(width: W, height: H)
    }

    private var contentLayer: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Text("GRIPPD")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(2.5)
                    .foregroundStyle(accent)
                Spacer()
                contentTypeBadge
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)

            Spacer()

            // Poster (centered, floating)
            posterView
                .padding(.bottom, 22)

            // Info panel
            VStack(spacing: 0) {
                // Title
                Text(item.contentTitle)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 12)

                // Rating row
                ratingRow

                Spacer().frame(height: 18)

                // Divider
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.horizontal, 22)

                Spacer().frame(height: 14)

                // Footer
                footerRow
                    .padding(.horizontal, 22)
            }
            .padding(.bottom, 24)
        }
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 26)
            .strokeBorder(
                LinearGradient(
                    colors: [accent.opacity(0.45), .white.opacity(0.04), accent.opacity(0.10)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                lineWidth: 1.2
            )
    }

    // MARK: - Sub-views

    private var contentTypeBadge: some View {
        let (icon, label): (String, String) = switch item.contentType {
        case .movie:   ("film", "FİLM")
        case .tv_show: ("tv", "DİZİ")
        case .book:    ("book.closed", "KİTAP")
        }
        return HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9, weight: .semibold))
            Text(label).font(.system(size: 9, weight: .bold)).tracking(1.2)
        }
        .foregroundStyle(.white.opacity(0.35))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.white.opacity(0.07), in: Capsule())
    }

    private var posterView: some View {
        ZStack {
            // Glow halo
            RoundedRectangle(cornerRadius: 14)
                .fill(accent.opacity(0.18))
                .frame(width: 154, height: 230)
                .blur(radius: 18)

            // Poster image
            Group {
                if let poster = posterImage {
                    Image(uiImage: poster)
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            Image(systemName: "film")
                                .font(.system(size: 34))
                                .foregroundStyle(.white.opacity(0.18))
                        )
                }
            }
            .frame(width: 144, height: 216)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .shadow(color: .black.opacity(0.55), radius: 20, y: 10)
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private var ratingRow: some View {
        HStack(spacing: 10) {
            if let rating = item.rating, rating > 0 {
                starRow(rating: rating)
            }
            if let emoji = item.emoji {
                Text(emoji)
                    .font(.system(size: 24))
                    .shadow(color: .black.opacity(0.4), radius: 4)
            }
        }
    }

    private func starRow(rating: Double) -> some View {
        let fullStars = Int(rating / 2)
        let hasHalf = (rating / 2) - Double(fullStars) >= 0.5
        return HStack(spacing: 0) {
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: i < fullStars ? "star.fill" : (i == fullStars && hasHalf ? "star.leadinghalf.filled" : "star"))
                        .font(.system(size: 12))
                        .foregroundStyle(i < fullStars || (i == fullStars && hasHalf) ? Color.yellow : .white.opacity(0.18))
                }
            }
            Spacer().frame(width: 7)
            Text(String(format: "%.1f", rating))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private var footerRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.isOwnLog ? "izledim" : "\(item.username) izledi")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
                Text("grippd.app")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.25))
            }
            Spacer()
            // Brand pill
            HStack(spacing: 5) {
                Image(systemName: "play.square.stack.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(accent)
                Text("Grippd")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accent.opacity(0.12), in: Capsule())
            .overlay(
                Capsule().strokeBorder(accent.opacity(0.25), lineWidth: 0.8)
            )
        }
    }
}
