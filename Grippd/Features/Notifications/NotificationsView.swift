import SwiftUI

// MARK: - ViewModel

@Observable
private final class NotificationsViewModel {
    var notifications: [AppNotification] = []
    var isLoading = false

    func load() async {
        isLoading = true
        notifications = (try? await NotificationService.shared.fetchNotifications()) ?? []
        isLoading = false
        await NotificationService.shared.markAllRead()
    }
}

// MARK: - View

struct NotificationsView: View {
    var onNavigate: ((ProfileRoute) -> Void)? = nil
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = NotificationsViewModel()

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.profilePath) {
            ZStack {
                GrippdBackground()
                content
            }
            .navigationTitle("Bildirimler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: ProfileRoute.self) { route in
                profileDestination(route)
            }
        }
        .task { await viewModel.load() }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView().tint(GrippdTheme.Colors.accent)
        } else if viewModel.notifications.isEmpty {
            emptyState
        } else {
            notificationList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.15))
            Text("Henüz bildirim yok")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
            Text("Biri seni takip ettiğinde, loguna\nyorum veya beğeni yaptığında burada görünür.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }

    private var notificationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.notifications) { notification in
                    NotificationRow(notification: notification) {
                        navigateTo(notification)
                    }
                    Divider().background(.white.opacity(0.06))
                }
            }
            .padding(.bottom, GrippdTheme.Spacing.xxl)
        }
    }

    // MARK: - Navigation

    private func navigateTo(_ notification: AppNotification) {
        switch notification.type {
        case .follow:
            router.profilePath.append(ProfileRoute.userProfile(userID: notification.actor.id))
        case .comment:
            if let logID = notification.logID {
                router.profilePath.append(ProfileRoute.logComments(logID: logID))
            } else {
                router.profilePath.append(ProfileRoute.userProfile(userID: notification.actor.id))
            }
        case .like:
            guard let logID = notification.logID else {
                router.profilePath.append(ProfileRoute.userProfile(userID: notification.actor.id))
                return
            }
            Task {
                guard let info = await NotificationService.shared.fetchLogContent(logID: logID) else { return }
                let route: ProfileRoute? = switch info.contentType {
                case .movie:   info.tmdbID.map { .movieDetail(tmdbID: $0) }
                case .tv_show: info.tmdbID.map { .tvShowDetail(tmdbID: $0) }
                case .book:    info.googleBooksID.map { .bookDetail(googleBooksID: $0) }
                }
                guard let route else { return }
                dismiss()
                try? await Task.sleep(for: .milliseconds(350))
                onNavigate?(route)
            }
        }
    }

    @ViewBuilder
    private func profileDestination(_ route: ProfileRoute) -> some View {
        switch route {
        case .userProfile(let userID):
            UserProfileView(userID: userID)
        case .logComments(let logID):
            LogCommentsView(logID: logID)
        default:
            EmptyView()
        }
    }
}

// MARK: - Notification Row

private struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void

    private var message: String {
        switch notification.type {
        case .follow:  return "\(notification.actor.displayName) seni takip etmeye başladı."
        case .like:    return "\(notification.actor.displayName) logunu beğendi."
        case .comment: return "\(notification.actor.displayName) loguna yorum yaptı."
        }
    }

    private var icon: String {
        switch notification.type {
        case .follow:  return "person.fill.badge.plus"
        case .like:    return "heart.fill"
        case .comment: return "bubble.left.fill"
        }
    }

    private var iconColor: Color {
        switch notification.type {
        case .follow:  return GrippdTheme.Colors.accent
        case .like:    return .red
        case .comment: return .blue
        }
    }

    private var relativeTime: String {
        let diff = Date().timeIntervalSince(notification.createdAt)
        switch diff {
        case ..<60:     return "az önce"
        case ..<3600:   return "\(Int(diff/60))d önce"
        case ..<86400:  return "\(Int(diff/3600))s önce"
        case ..<604800: return "\(Int(diff/86400))g önce"
        default:
            return notification.createdAt.formatted(.dateTime.day().month(.abbreviated))
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar + icon badge
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: notification.actor.avatarURL) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            Circle()
                                .fill(GrippdTheme.Colors.accent.opacity(0.12))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white.opacity(0.3))
                                )
                        }
                    }
                    .frame(width: 46, height: 46)
                    .clipShape(Circle())

                    Circle()
                        .fill(GrippdTheme.Colors.background)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 10))
                                .foregroundStyle(iconColor)
                        )
                        .offset(x: 2, y: 2)
                }

                // Mesaj
                VStack(alignment: .leading, spacing: 3) {
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(notification.isRead ? 0.65 : 0.95))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(relativeTime)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.3))
                }

                Spacer()

                // Okunmamış göstergesi
                if !notification.isRead {
                    Circle()
                        .fill(GrippdTheme.Colors.accent)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 12)
            .background(
                notification.isRead
                ? Color.clear
                : GrippdTheme.Colors.accent.opacity(0.04)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
