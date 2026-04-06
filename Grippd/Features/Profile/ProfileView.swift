import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var authVM = AuthViewModel()
    @State private var showSignOutConfirm = false

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.profilePath) {
            ZStack {
                GrippdBackground()

                ScrollView {
                    VStack(spacing: 0) {
                        // Avatar + name
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(GrippdTheme.Colors.accent.opacity(0.1))
                                    .frame(width: 90, height: 90)

                                if let url = appState.currentUser?.avatarURL {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 36))
                                            .foregroundStyle(.white.opacity(0.3))
                                    }
                                    .frame(width: 84, height: 84)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.white.opacity(0.3))
                                }

                                Circle()
                                    .strokeBorder(GrippdTheme.Colors.accent.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 84, height: 84)
                            }

                            VStack(spacing: 4) {
                                Text(appState.currentUser?.displayName ?? "")
                                    .font(GrippdTheme.Typography.title)
                                    .foregroundStyle(.white)
                                Text("@\(appState.currentUser?.username ?? "")")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.45))
                            }

                            // Stats row — Phase 3-4'te gerçek verilerle dolacak
                            HStack(spacing: 0) {
                                StatItem(value: "0", label: "Log")
                                Divider().frame(height: 28).background(.white.opacity(0.1))
                                StatItem(value: "0", label: "Takipçi")
                                Divider().frame(height: 28).background(.white.opacity(0.1))
                                StatItem(value: "0", label: "Takip")
                            }
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, GrippdTheme.Spacing.lg)
                        .padding(.top, GrippdTheme.Spacing.xl)
                        .padding(.bottom, GrippdTheme.Spacing.xl)

                        // Log grid placeholder
                        VStack(spacing: GrippdTheme.Spacing.md) {
                            HStack {
                                Text("Loglar")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding(.horizontal, GrippdTheme.Spacing.lg)

                            Text("Henüz log yok — Phase 3'te geliyor")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.25))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, GrippdTheme.Spacing.xxl)
                        }

                        Spacer(minLength: GrippdTheme.Spacing.xxl)

                        // Sign out
                        Button {
                            showSignOutConfirm = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Oturumu Kapat")
                            }
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.4))
                        }
                        .padding(.bottom, GrippdTheme.Spacing.xxl)
                    }
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        router.profilePath.append(ProfileRoute.settings)
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .navigationDestination(for: ProfileRoute.self) { route in
                profileDestination(route)
            }
            .confirmationDialog("Oturumu kapat", isPresented: $showSignOutConfirm) {
                Button("Oturumu Kapat", role: .destructive) {
                    Task { await authVM.signOut(appState: appState) }
                }
                Button("İptal", role: .cancel) {}
            }
        }
    }

    @ViewBuilder
    private func profileDestination(_ route: ProfileRoute) -> some View {
        switch route {
        case .movieDetail(let tmdbID): MovieDetailView(tmdbID: tmdbID)
        case .tvShowDetail(let tmdbID):
            TVShowDetailView(tmdbID: tmdbID) { showID, seasonNumber in
                router.profilePath.append(ProfileRoute.seasonDetail(showID: showID, seasonNumber: seasonNumber))
            }
        case .seasonDetail(let showID, let seasonNumber): SeasonDetailView(showID: showID, seasonNumber: seasonNumber)
        case .settings: SettingsPlaceholderView()
        case .editProfile: Text("Profil Düzenle — Phase 4").foregroundStyle(.white)
        case .followers: Text("Takipçiler — Phase 4").foregroundStyle(.white)
        case .following: Text("Takip Edilenler — Phase 4").foregroundStyle(.white)
        case .contentDetail: Text("İçerik Detay — Phase 3").foregroundStyle(.white)
        case .userProfile: Text("Kullanıcı Profil — Phase 4").foregroundStyle(.white)
        }
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Settings Placeholder

private struct SettingsPlaceholderView: View {
    @Environment(AppState.self) private var appState
    @State private var authVM = AuthViewModel()

    var body: some View {
        ZStack {
            GrippdBackground()
            VStack(spacing: GrippdTheme.Spacing.lg) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.3))
                Text("Ayarlar")
                    .font(GrippdTheme.Typography.headline)
                    .foregroundStyle(.white)
                Text("Phase 4'te geliyor")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .navigationTitle("Ayarlar")
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
