import SwiftUI

// MARK: - ViewModel

@Observable
private final class UserProfileViewModel {
    var profileData: UserProfileData?
    var isLoading = false
    var error: String?
    var isFollowing = false
    var isFollowLoading = false

    func load(userID: UUID) async {
        guard profileData == nil else { return }
        isLoading = true
        error = nil
        do {
            async let profile = SocialService.shared.fetchProfile(userID: userID)
            async let following = FollowService.shared.isFollowing(targetUserID: userID)
            let (p, f) = try await (profile, following)
            profileData = p
            isFollowing = f
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func toggleFollow(targetUserID: UUID) async {
        isFollowLoading = true
        HapticManager.medium()
        do {
            if isFollowing {
                try await FollowService.shared.unfollow(targetUserID: targetUserID)
                isFollowing = false
                if let d = profileData {
                    profileData = UserProfileData(user: d.user, followerCount: max(0, d.followerCount - 1),
                                                  followingCount: d.followingCount, logCount: d.logCount,
                                                  recentLogs: d.recentLogs)
                }
            } else {
                try await FollowService.shared.follow(targetUserID: targetUserID)
                isFollowing = true
                if let d = profileData {
                    profileData = UserProfileData(user: d.user, followerCount: d.followerCount + 1,
                                                  followingCount: d.followingCount, logCount: d.logCount,
                                                  recentLogs: d.recentLogs)
                }
            }
        } catch {}
        isFollowLoading = false
    }
}

// MARK: - View

struct UserProfileView: View {
    let userID: UUID

    @Environment(AppState.self) private var appState
    @State private var viewModel = UserProfileViewModel()

    private var isOwnProfile: Bool {
        appState.currentUser?.id == userID
    }

    var body: some View {
        ZStack {
            GrippdBackground()

            if viewModel.isLoading {
                ProgressView()
                    .tint(GrippdTheme.Colors.accent)
            } else if let error = viewModel.error {
                VStack(spacing: GrippdTheme.Spacing.md) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.2))
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else if let data = viewModel.profileData {
                profileContent(data: data)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load(userID: userID) }
    }

    // MARK: - Profile Content

    private func profileContent(data: UserProfileData) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection(data: data)
                statsRow(data: data)
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                    .padding(.top, GrippdTheme.Spacing.md)

                if let bio = data.user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, GrippdTheme.Spacing.lg)
                        .padding(.top, GrippdTheme.Spacing.sm)
                }

                if !isOwnProfile {
                    followButton
                        .padding(.horizontal, GrippdTheme.Spacing.md)
                        .padding(.top, GrippdTheme.Spacing.md)
                }

                recentLogsSection(logs: localRecentLogs(fallback: data.recentLogs))
                    .padding(.top, GrippdTheme.Spacing.lg)
            }
            .padding(.bottom, GrippdTheme.Spacing.xxl)
        }
    }

    // MARK: - Header

    private func headerSection(data: UserProfileData) -> some View {
        VStack(spacing: 0) {
            // Banner + avatar
            ZStack(alignment: .bottom) {
                if let bannerURL = data.user.bannerURL {
                    AsyncImage(url: bannerURL) { phase in
                        if case .success(let image) = phase {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            bannerPlaceholder
                        }
                    }
                    .frame(height: 120)
                    .clipped()
                } else {
                    bannerPlaceholder.frame(height: 120)
                }

                avatarView(url: data.user.avatarURL, isPremium: data.user.planType == .premium)
                    .offset(y: 45)
            }
            .frame(height: 120)

            // İsim + username — avatar için boşluk bırak
            VStack(spacing: 4) {
                Text(data.user.displayName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("@\(data.user.username)")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.top, 52)
            .padding(.bottom, 8)
        }
    }

    private var bannerPlaceholder: some View {
        LinearGradient(
            colors: [GrippdTheme.Colors.accent.opacity(0.15), GrippdTheme.Colors.background],
            startPoint: .top, endPoint: .bottom
        )
    }

    private func avatarView(url: URL?, isPremium: Bool = false) -> some View {
        UserAvatarView(
            url: url,
            size: 90,
            isPremium: isPremium
        )
    }

    private var defaultAvatar: some View {
        Circle()
            .fill(GrippdTheme.Colors.accent.opacity(0.1))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white.opacity(0.3))
            )
    }

    // MARK: - Stats Row

    private func statsRow(data: UserProfileData) -> some View {
        // Kendi profilinde yerel SwiftData, başkasında Supabase logCount
        let displayLogCount = isOwnProfile
            ? LogService.shared.stats().totalLogged
            : data.logCount
        return HStack(spacing: 0) {
            profileStat(value: "\(displayLogCount)", label: "Log")
            Divider().frame(height: 28).background(.white.opacity(0.1))
            NavigationLink {
                FollowListView(userID: userID, mode: .followers)
            } label: {
                profileStat(value: "\(data.followerCount)", label: "Takipçi")
            }
            .buttonStyle(.plain)
            Divider().frame(height: 28).background(.white.opacity(0.1))
            NavigationLink {
                FollowListView(userID: userID, mode: .following)
            } label: {
                profileStat(value: "\(data.followingCount)", label: "Takip")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
    }

    private func profileStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Follow Button

    private var followButton: some View {
        Button {
            Task { await viewModel.toggleFollow(targetUserID: userID) }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isFollowLoading {
                    ProgressView().tint(viewModel.isFollowing ? GrippdTheme.Colors.background : .white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: viewModel.isFollowing ? "person.badge.minus" : "person.badge.plus")
                        .font(.system(size: 15))
                    Text(viewModel.isFollowing ? "Takibi Bırak" : "Takip Et")
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .foregroundStyle(viewModel.isFollowing ? GrippdTheme.Colors.background : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                viewModel.isFollowing ? GrippdTheme.Colors.accent : Color.white.opacity(0.12),
                in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
            )
        }
        .disabled(viewModel.isFollowLoading)
        .buttonStyle(.press)
        .accessibilityLabel(viewModel.isFollowing ? "Takibi bırak" : "Takip et")
        .animation(.spring(response: 0.3), value: viewModel.isFollowing)
    }

    // Kendi profili için SwiftData'dan, değilse Supabase verisinden
    private func localRecentLogs(fallback: [PublicLog]) -> [PublicLog] {
        guard isOwnProfile else { return fallback }
        return LogService.shared.allLogs().prefix(12).compactMap { entry in
            guard let uuid = UUID(uuidString: entry.id) else { return nil }
            return PublicLog(
                id: uuid,
                contentTitle: entry.contentTitle,
                posterURL: entry.posterURL,
                contentType: entry.contentType,
                watchedAt: entry.watchedAt,
                rating: entry.rating,
                emoji: entry.emoji
            )
        }
    }

    // MARK: - Recent Logs Grid

    private func recentLogsSection(logs: [PublicLog]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Son Loglar")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)

            if logs.isEmpty {
                GrippdEmptyStateView(icon: "checkmark.circle", title: "Henüz log yok")
                    .padding(.vertical, GrippdTheme.Spacing.sm)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 4),
                        GridItem(.flexible(), spacing: 4),
                        GridItem(.flexible(), spacing: 4),
                    ],
                    spacing: 4
                ) {
                    ForEach(logs) { log in
                        PublicLogCell(log: log)
                    }
                }
                .padding(.horizontal, GrippdTheme.Spacing.md)
            }
        }
    }
}

// MARK: - Public Log Cell

private struct PublicLogCell: View {
    let log: PublicLog

    private var typeIcon: String {
        switch log.contentType {
        case .movie:   return "film"
        case .tv_show: return "tv"
        case .book:    return "book.closed"
        }
    }

    var body: some View {
        Color.clear
            .aspectRatio(2/3, contentMode: .fit)
            .overlay(
                AsyncImage(url: log.posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(GrippdTheme.Colors.surface)
                            .overlay(
                                Image(systemName: typeIcon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white.opacity(0.2))
                            )
                    }
                }
            )
            .overlay(alignment: .bottomLeading) {
                if let rating = log.rating, rating > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.6))
                    .padding(4)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Follower / Following List View

struct FollowListView: View {
    let userID: UUID
    let mode: Mode

    enum Mode { case followers, following }

    @State private var users: [User] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            GrippdBackground()

            if isLoading {
                GrippdLoadingView()
            } else if users.isEmpty {
                GrippdEmptyStateView(
                    icon: "person.2",
                    title: mode == .followers ? "Henüz takipçi yok" : "Henüz kimseyi takip etmiyor"
                )
            } else {
                List {
                    ForEach(users) { user in
                        NavigationLink {
                            UserProfileView(userID: user.id)
                        } label: {
                            UserRowCell(user: user)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(.white.opacity(0.06))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(mode == .followers ? "Takipçiler" : "Takip Edilenler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            do {
                users = mode == .followers
                    ? try await SocialService.shared.fetchFollowers(userID: userID)
                    : try await SocialService.shared.fetchFollowing(userID: userID)
            } catch {}
            isLoading = false
        }
    }
}

// MARK: - User Row Cell

struct UserRowCell: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(
                url: user.avatarURL,
                size: 44,
                isPremium: user.planType == .premium
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text("@\(user.username)")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

