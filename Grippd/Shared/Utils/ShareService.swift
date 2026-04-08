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
        renderer.scale = UIScreen.main.scale
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

    var body: some View {
        ZStack {
            // Blurred poster background
            if let poster = posterImage {
                Image(uiImage: poster)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 300, height: 450)
                    .blur(radius: 24)
                    .overlay(Color.black.opacity(0.65))
            } else {
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.08, blue: 0.14), Color(red: 0.04, green: 0.04, blue: 0.08)],
                    startPoint: .top, endPoint: .bottom
                )
            }

            VStack(spacing: 0) {
                // Poster
                Group {
                    if let poster = posterImage {
                        Image(uiImage: poster)
                            .resizable()
                            .aspectRatio(2/3, contentMode: .fit)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.06))
                            .aspectRatio(2/3, contentMode: .fit)
                            .overlay(
                                Image(systemName: "film")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.white.opacity(0.2))
                            )
                    }
                }
                .frame(width: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.5), radius: 16, y: 8)

                Spacer().frame(height: 18)

                // Title
                Text(item.contentTitle)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 10)

                // Rating + emoji
                HStack(spacing: 10) {
                    if let rating = item.rating, rating > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.1), in: Capsule())
                    }
                    if let emoji = item.emoji {
                        Text(emoji).font(.system(size: 22))
                    }
                }

                Spacer()

                // Footer
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.isOwnLog ? "izledim" : "\(item.username) izledi")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.55))
                        Text("Grippd")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.47, green: 0.82, blue: 0.64))
                    }
                    Spacer()
                    Image(systemName: "film.stack")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(red: 0.47, green: 0.82, blue: 0.64).opacity(0.6))
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 28)
        }
        .frame(width: 300, height: 450)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
