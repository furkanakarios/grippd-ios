import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var authVM = AuthViewModel()
    @State private var showSignOutConfirm = false
    @State private var showWrapped = false
    @State private var showNotifications = false
    @State private var showAdminPanel = false
    @State private var selectedTab: ProfileTab = .logs
    @State private var followerCount: Int = 0
    @State private var followingCount: Int = 0

    enum ProfileTab: String, CaseIterable {
        case logs = "Loglar"
        case watchlist = "Listelerim"
        case stats = "İstatistik"
    }

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.profilePath) {
            ZStack {
                GrippdBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                        tabPicker
                        tabContent
                        signOutButton
                    }
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        if LogService.shared.wrappedStats() != nil {
                            Button {
                                showWrapped = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                    Text(verbatim: "\(Calendar.current.component(.year, from: Date()))")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(GrippdTheme.Colors.accent)
                            }
                        }
                        if appState.isAdmin {
                            Button {
                                showAdminPanel = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "shield.fill")
                                    Text("Admin")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(.red.opacity(0.85))
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Bildirim zili
                        Button {
                            showNotifications = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell")
                                    .foregroundStyle(.white.opacity(0.7))
                                if appState.unreadNotificationCount > 0 {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 4, y: -4)
                                }
                            }
                        }
                        // Ayarlar
                        Button {
                            router.profilePath.append(ProfileRoute.settings)
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showWrapped) {
                if let wrapped = LogService.shared.wrappedStats() {
                    WrappedView(stats: wrapped, isPresented: $showWrapped)
                }
            }
            .fullScreenCover(isPresented: $showAdminPanel) {
                AdminPanelView()
                    .environment(appState)
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsView(onNavigate: { route in
                    router.profilePath.append(route)
                })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    appState.unreadNotificationCount = 0
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

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            UserAvatarView(
                url: appState.currentUser?.avatarURL,
                size: 90,
                isPremium: appState.isPremium
            )

            VStack(spacing: 4) {
                Text(appState.currentUser?.displayName ?? "")
                    .font(GrippdTheme.Typography.title)
                    .foregroundStyle(.white)
                Text("@\(appState.currentUser?.username ?? "")")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.45))
            }

            // Stats
            let logCount = LogService.shared.stats().totalLogged
            HStack(spacing: 0) {
                StatItem(value: "\(logCount)", label: "Log")
                Divider().frame(height: 28).background(.white.opacity(0.1))
                Button {
                    if let id = appState.currentUser?.id {
                        router.profilePath.append(ProfileRoute.followers(userID: id))
                    }
                } label: {
                    StatItem(value: "\(followerCount)", label: "Takipçi")
                }
                .buttonStyle(.plain)
                Divider().frame(height: 28).background(.white.opacity(0.1))
                Button {
                    if let id = appState.currentUser?.id {
                        router.profilePath.append(ProfileRoute.following(userID: id))
                    }
                } label: {
                    StatItem(value: "\(followingCount)", label: "Takip")
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 16)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
            .padding(.top, 8)
            .task(id: appState.selectedTab) {
                guard appState.selectedTab == .profile,
                      let id = appState.currentUser?.id else { return }
                async let profileData = SocialService.shared.fetchProfile(userID: id)
                async let count = NotificationService.shared.unreadCount()
                if let data = try? await profileData {
                    followerCount = data.followerCount
                    followingCount = data.followingCount
                }
                appState.unreadNotificationCount = await count
            }
        }
        .padding(.horizontal, GrippdTheme.Spacing.lg)
        .padding(.top, GrippdTheme.Spacing.xl)
        .padding(.bottom, GrippdTheme.Spacing.lg)
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedTab = tab }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)

                        Rectangle()
                            .fill(selectedTab == tab ? GrippdTheme.Colors.accent : Color.clear)
                            .frame(height: 2)
                    }
                }
            }
        }
        .background(.white.opacity(0.04))
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .logs:
            LogsTabView(router: router)
        case .watchlist:
            WatchlistTabView(router: router)
        case .stats:
            StatsTabView()
        }
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
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
        .padding(.top, GrippdTheme.Spacing.xl)
        .padding(.bottom, GrippdTheme.Spacing.xxl)
    }

    // MARK: - Navigation

    @ViewBuilder
    private func profileDestination(_ route: ProfileRoute) -> some View {
        switch route {
        case .movieDetail(let tmdbID): MovieDetailView(tmdbID: tmdbID)
        case .tvShowDetail(let tmdbID):
            TVShowDetailView(tmdbID: tmdbID) { showID, seasonNumber in
                router.profilePath.append(ProfileRoute.seasonDetail(showID: showID, seasonNumber: seasonNumber))
            }
        case .seasonDetail(let showID, let seasonNumber):
            SeasonDetailView(showID: showID, seasonNumber: seasonNumber) { sID, sNum, epNum in
                router.profilePath.append(ProfileRoute.episodeDetail(showID: sID, seasonNumber: sNum, episodeNumber: epNum))
            }
        case .episodeDetail(let showID, let seasonNumber, let episodeNumber):
            EpisodeDetailView(showID: showID, seasonNumber: seasonNumber, episodeNumber: episodeNumber)
        case .bookDetail(let googleBooksID):
            BookDetailView(googleBooksID: googleBooksID)
        case .personDetail: Text("Kişi Detay — Phase 4").foregroundStyle(.white)
        case .settings: SettingsView()
        case .editProfile: Text("Profil Düzenle — Phase 4").foregroundStyle(.white)
        case .followers(let userID): FollowListView(userID: userID, mode: .followers)
        case .following(let userID): FollowListView(userID: userID, mode: .following)
        case .contentDetail: Text("İçerik Detay").foregroundStyle(.white)
        case .userProfile(let userID): UserProfileView(userID: userID)
        case .customList(let listID):
            if let list = CustomListService.shared.allLists().first(where: { $0.id == listID }) {
                CustomListDetailView(list: list)
            }
        case .logComments(let logID):
            LogCommentsView(logID: logID)
        }
    }
}

// MARK: - Logs Tab

private struct LogsTabView: View {
    let router: AppRouter
    @State private var logs: [LogEntry] = []
    @State private var filter: Content.ContentType? = nil

    private var filtered: [LogEntry] {
        guard let f = filter else { return logs }
        return logs.filter { $0.contentType == f }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(label: "Tümü", type: nil)
                    filterChip(label: "Filmler", type: .movie)
                    filterChip(label: "Diziler", type: .tv_show)
                    filterChip(label: "Kitaplar", type: .book)
                }
                .padding(.horizontal, GrippdTheme.Spacing.md)
                .padding(.vertical, GrippdTheme.Spacing.sm)
            }

            if filtered.isEmpty {
                GrippdEmptyStateView(
                    icon: "checkmark.circle",
                    title: filter == nil ? "Henüz log yok" : "Bu kategoride log yok"
                )
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { log in
                        LogRowCell(log: log) {
                            navigate(log: log)
                        }
                        Divider().background(.white.opacity(0.06)).padding(.leading, 80)
                    }
                }
                .padding(.bottom, GrippdTheme.Spacing.xl)
            }
        }
        .onAppear { logs = LogService.shared.allLogs() }
    }

    private func filterChip(label: String, type: Content.ContentType?) -> some View {
        Button {
            withAnimation(.spring(response: 0.25)) { filter = type }
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(filter == type ? GrippdTheme.Colors.background : .white.opacity(0.6))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    filter == type ? GrippdTheme.Colors.accent : Color.white.opacity(0.07),
                    in: Capsule()
                )
        }
    }

    private func navigate(log: LogEntry) {
        let parts = log.contentKey.split(separator: "-", maxSplits: 1)
        guard parts.count == 2 else { return }
        let idStr = String(parts[1])
        switch log.contentType {
        case .movie:
            if let id = Int(idStr) {
                router.profilePath.append(ProfileRoute.movieDetail(tmdbID: id))
            }
        case .tv_show:
            if let id = Int(idStr) {
                router.profilePath.append(ProfileRoute.tvShowDetail(tmdbID: id))
            }
        case .book:
            router.profilePath.append(ProfileRoute.bookDetail(googleBooksID: idStr))
        }
    }
}

// MARK: - Watchlist Tab

private struct WatchlistTabView: View {
    let router: AppRouter
    @Environment(AppState.self) private var appState
    @State private var entries: [WatchlistEntry] = []
    @State private var customLists: [CustomList] = []
    @State private var filter: Content.ContentType? = nil
    @State private var showCreateList = false
    @State private var showPaywall = false

    private func tryCreateList() {
        if !PremiumGate.isAllowed(.createList(currentCount: customLists.count), isPremium: appState.isPremium) {
            showPaywall = true
        } else {
            showCreateList = true
        }
    }

    private var filtered: [WatchlistEntry] {
        guard let f = filter else { return entries }
        return entries.filter { $0.contentType == f }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(label: "Tümü", type: nil)
                    filterChip(label: "Filmler", type: .movie)
                    filterChip(label: "Diziler", type: .tv_show)
                    filterChip(label: "Kitaplar", type: .book)
                }
                .padding(.horizontal, GrippdTheme.Spacing.md)
                .padding(.vertical, GrippdTheme.Spacing.sm)
            }

            if filtered.isEmpty && customLists.isEmpty {
                GrippdEmptyStateView(
                    icon: "bookmark",
                    title: filter == nil ? "Listelenen içerik yok" : "Bu kategoride içerik yok"
                )
            } else {
                LazyVStack(spacing: 0) {
                    // İzleme listesi içerikleri
                    if !filtered.isEmpty {
                        sectionHeader("İzleme Listesi")
                        ForEach(filtered, id: \.contentKey) { entry in
                            WatchlistRowCell(entry: entry) {
                                navigate(entry: entry)
                            } onRemove: {
                                WatchlistService.shared.remove(entry.contentKey)
                                entries = WatchlistService.shared.all()
                            }
                            Divider().background(.white.opacity(0.06)).padding(.leading, 80)
                        }
                    }

                    // Custom listeler
                    sectionHeader("Özel Listeler") {
                        Button {
                            tryCreateList()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(GrippdTheme.Colors.accent)
                        }
                    }

                    if customLists.isEmpty {
                        Button {
                            tryCreateList()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(GrippdTheme.Colors.accent)
                                Text("Yeni Liste Oluştur")
                                    .foregroundStyle(GrippdTheme.Colors.accent)
                            }
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(GrippdTheme.Colors.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, GrippdTheme.Spacing.md)
                        .padding(.vertical, GrippdTheme.Spacing.sm)
                    } else {
                        List {
                            ForEach(customLists) { list in
                                Button {
                                    router.profilePath.append(ProfileRoute.customList(listID: list.id))
                                } label: {
                                    CustomListRow(list: list)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        CustomListService.shared.deleteList(list)
                                        customLists = CustomListService.shared.allLists()
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparatorTint(.white.opacity(0.06))
                                .listRowInsets(EdgeInsets())
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .scrollDisabled(true)
                        .frame(height: CGFloat(customLists.count) * 64)
                    }
                }
                .padding(.bottom, GrippdTheme.Spacing.xxl)
            }
        }
        .onAppear {
            entries = WatchlistService.shared.all()
            customLists = CustomListService.shared.allLists()
        }
        .sheet(isPresented: $showCreateList) {
            CustomListFormSheet(isPresented: $showCreateList) { _ in
                customLists = CustomListService.shared.allLists()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheetView()
        }
    }

    private func filterChip(label: String, type: Content.ContentType?) -> some View {
        Button {
            withAnimation(.spring(response: 0.25)) { filter = type }
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(filter == type ? GrippdTheme.Colors.background : .white.opacity(0.6))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    filter == type ? GrippdTheme.Colors.accent : Color.white.opacity(0.07),
                    in: Capsule()
                )
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(1.0)
            Spacer()
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.top, GrippdTheme.Spacing.md)
        .padding(.bottom, 4)
    }

    private func sectionHeader<T: View>(_ title: String, @ViewBuilder trailing: () -> T) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(1.0)
            Spacer()
            trailing()
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.top, GrippdTheme.Spacing.md)
        .padding(.bottom, 4)
    }

    private func navigate(entry: WatchlistEntry) {
        let parts = entry.contentKey.split(separator: "-", maxSplits: 1)
        guard parts.count == 2 else { return }
        let idStr = String(parts[1])
        switch entry.contentType {
        case .movie:
            if let id = Int(idStr) {
                router.profilePath.append(ProfileRoute.movieDetail(tmdbID: id))
            }
        case .tv_show:
            if let id = Int(idStr) {
                router.profilePath.append(ProfileRoute.tvShowDetail(tmdbID: id))
            }
        case .book:
            router.profilePath.append(ProfileRoute.bookDetail(googleBooksID: idStr))
        }
    }
}

// MARK: - Log Row Cell

private struct LogRowCell: View {
    let log: LogEntry
    let onTap: () -> Void
    @Environment(AppState.self) private var appState

    private var typeIcon: String {
        switch log.contentType {
        case .movie: return "film"
        case .tv_show: return "tv"
        case .book: return "book.closed"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                CachedAsyncImage(url: log.posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(GrippdTheme.Colors.surface)
                            .overlay(Image(systemName: typeIcon).font(.system(size: 16)).foregroundStyle(.white.opacity(0.2)))
                    }
                }
                .frame(width: 48, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(log.contentTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(log.watchedAt.formatted(.dateTime.day().month(.abbreviated).year()))
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))

                    HStack(spacing: 6) {
                        if log.isRewatch {
                            Label("Tekrar", systemImage: "arrow.clockwise")
                                .font(.system(size: 11))
                                .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.8))
                        }
                        if let emoji = log.emoji { Text(emoji).font(.system(size: 13)) }
                        if let rating = log.rating { StarRatingBadge(rating: rating, fontSize: 11) }
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        Task {
                            await ShareService.shared.present(item: ShareItem(
                                contentTitle: log.contentTitle,
                                posterURL: log.posterURL,
                                rating: log.rating,
                                emoji: log.emoji,
                                username: appState.currentUser?.displayName ?? "",
                                isOwnLog: true,
                                contentType: log.contentType
                            ))
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.2))
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Watchlist Row Cell

private struct WatchlistRowCell: View {
    let entry: WatchlistEntry
    let onTap: () -> Void
    let onRemove: () -> Void
    @State private var showRemoveConfirm = false

    private var typeIcon: String {
        switch entry.contentType {
        case .movie: return "film"
        case .tv_show: return "tv"
        case .book: return "book.closed"
        }
    }

    private var typeLabel: String {
        switch entry.contentType {
        case .movie: return "Film"
        case .tv_show: return "Dizi"
        case .book: return "Kitap"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                CachedAsyncImage(url: entry.posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(GrippdTheme.Colors.surface)
                            .overlay(Image(systemName: typeIcon).font(.system(size: 16)).foregroundStyle(.white.opacity(0.2)))
                    }
                }
                .frame(width: 48, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.contentTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        Image(systemName: typeIcon)
                            .font(.system(size: 10))
                        Text(typeLabel)
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.white.opacity(0.4))

                    Text("Eklendi: \(entry.addedAt.formatted(.dateTime.day().month(.abbreviated)))")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.3))
                }

                Spacer()

                Button {
                    showRemoveConfirm = true
                } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.7))
                }
                .confirmationDialog("Listeden çıkar?", isPresented: $showRemoveConfirm, titleVisibility: .visible) {
                    Button("Listeden Çıkar", role: .destructive) { onRemove() }
                    Button("Vazgeç", role: .cancel) {}
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom List Row

private struct CustomListRow: View {
    let list: CustomList

    var body: some View {
        HStack(spacing: 14) {
            Text(list.emoji)
                .font(.system(size: 26))
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(list.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text("\(list.items.count) içerik")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - Stats Tab

private struct StatsTabView: View {
    @State private var stats: LogService.LogStats? = nil

    var body: some View {
        Group {
            if let s = stats {
                if s.totalLogged == 0 {
                    GrippdEmptyStateView(
                        icon: "chart.bar",
                        title: "Henüz istatistik yok",
                        subtitle: "Biraz içerik logla!"
                    )
                    .padding(.top, 40)
                } else {
                    statsContent(s)
                }
            } else {
                GrippdLoadingView()
                    .padding(.top, 80)
            }
        }
        .onAppear {
            stats = LogService.shared.stats()
        }
    }

    private func statsContent(_ s: LogService.LogStats) -> some View {
        VStack(spacing: 16) {
            // Content Type Breakdown
            statsCard {
                VStack(alignment: .leading, spacing: 12) {
                    cardTitle("İçerik Dağılımı")
                    let total = max(s.totalLogged, 1)
                    ContentTypeBar(icon: "film", label: "Filmler", count: s.totalMovies, total: total, color: GrippdTheme.Colors.accent)
                    ContentTypeBar(icon: "tv", label: "Diziler", count: s.totalShows, total: total, color: .blue)
                    ContentTypeBar(icon: "book.closed", label: "Kitaplar", count: s.totalBooks, total: total, color: .green)
                }
            }

            // Activity Row
            HStack(spacing: 12) {
                miniCard(value: "\(s.thisMonthCount)", label: "Bu Ay", icon: "calendar")
                miniCard(value: "\(s.thisYearCount)", label: "Bu Yıl", icon: "chart.line.uptrend.xyaxis")
                miniCard(value: "\(s.longestStreak)g", label: "En Uzun Seri", icon: "flame")
            }

            // Rating Distribution
            if !s.ratingDistribution.isEmpty {
                statsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            cardTitle("Puan Dağılımı")
                            Spacer()
                            if let avg = s.averageRating {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(GrippdTheme.Colors.accent)
                                    Text(String(format: "%.1f", avg))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        RatingDistributionChart(distribution: s.ratingDistribution)
                    }
                }
            }

            // Platforms
            if !s.platformCounts.isEmpty {
                statsCard {
                    VStack(alignment: .leading, spacing: 12) {
                        cardTitle("Platform Dağılımı")
                        let maxCount = s.platformCounts.first?.count ?? 1
                        ForEach(s.platformCounts.prefix(5), id: \.platform) { item in
                            PlatformBar(platform: item.platform, count: item.count, maxCount: maxCount)
                        }
                    }
                }
            }

            // Fun Facts
            HStack(spacing: 12) {
                if s.rewatchCount > 0 {
                    funFactCard(
                        icon: "arrow.clockwise",
                        value: "\(s.rewatchCount)",
                        label: "Tekrar İzleme"
                    )
                }
                if let emoji = s.topEmoji {
                    funFactCard(
                        icon: nil,
                        emoji: emoji,
                        value: emoji,
                        label: "En Çok Kullanılan"
                    )
                }
            }
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.top, GrippdTheme.Spacing.md)
        .padding(.bottom, GrippdTheme.Spacing.xxl)
    }

    private func statsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.lg))
    }

    private func cardTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.5))
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private func miniCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.7))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.lg))
    }

    private func funFactCard(icon: String?, emoji: String? = nil, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            if let e = emoji {
                Text(e).font(.system(size: 28))
            } else if let i = icon {
                Image(systemName: i)
                    .font(.system(size: 20))
                    .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.7))
            }
            Text(value == emoji ? "" : value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.lg))
    }
}

// MARK: - Stats Sub-components

private struct ContentTypeBar: View {
    let icon: String
    let label: String
    let count: Int
    let total: Int
    let color: Color

    private var ratio: Double { Double(count) / Double(max(total, 1)) }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 16)

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.06)).frame(height: 8)
                    Capsule()
                        .fill(color.opacity(0.7))
                        .frame(width: max(geo.size.width * ratio, 4), height: 8)
                }
            }
            .frame(height: 8)

            Text("\(count)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 28, alignment: .trailing)
        }
    }
}

private struct RatingDistributionChart: View {
    let distribution: [Int: Int]

    private var maxCount: Int { distribution.values.max() ?? 1 }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(1...10, id: \.self) { rating in
                let count = distribution[rating] ?? 0
                let ratio = Double(count) / Double(max(maxCount, 1))
                VStack(spacing: 4) {
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    RoundedRectangle(cornerRadius: 3)
                        .fill(count > 0 ? GrippdTheme.Colors.accent.opacity(0.6 + 0.4 * ratio) : Color.white.opacity(0.06))
                        .frame(height: max(CGFloat(ratio) * 60, 6))
                    Text("\(rating)")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 88)
        .animation(.spring(response: 0.4), value: distribution.keys.sorted())
    }
}

private struct PlatformBar: View {
    let platform: LogPlatform
    let count: Int
    let maxCount: Int

    private var ratio: Double { Double(count) / Double(max(maxCount, 1)) }

    var body: some View {
        HStack(spacing: 10) {
            Text(platform.displayName)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 90, alignment: .leading)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.06)).frame(height: 8)
                    Capsule()
                        .fill(GrippdTheme.Colors.accent.opacity(0.7))
                        .frame(width: max(geo.size.width * ratio, 4), height: 8)
                }
            }
            .frame(height: 8)

            Text("\(count)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 28, alignment: .trailing)
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

// MARK: - Settings View

private struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var isPrivate: Bool = false
    @State private var isSavingPrivacy = false
    @State private var showSignOutConfirm = false
    @State private var isSigningOut = false
    @State private var showSubscription = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showKVKK = false

    var body: some View {
        ZStack {
            GrippdBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    accountSection
                    Divider().background(.white.opacity(0.06)).padding(.vertical, 8)
                    privacySection
                    Divider().background(.white.opacity(0.06)).padding(.vertical, 8)
                    legalSection
                    Divider().background(.white.opacity(0.06)).padding(.vertical, 8)
                    dangerSection
                }
                .padding(.top, 12)
                .padding(.bottom, GrippdTheme.Spacing.xxl)
            }
        }
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $showSubscription) {
            SubscriptionManagementView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            LegalView(mode: .privacyPolicy)
        }
        .sheet(isPresented: $showTermsOfService) {
            LegalView(mode: .termsOfService)
        }
        .sheet(isPresented: $showKVKK) {
            LegalView(mode: .kvkk)
        }
        .onAppear { isPrivate = appState.currentUser?.isPrivate ?? false }
        .confirmationDialog("Çıkış yapmak istediğine emin misin?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Çıkış Yap", role: .destructive) {
                Task { await signOut() }
            }
            Button("İptal", role: .cancel) {}
        }
    }

    // MARK: - Sections

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Hesap")
            if let user = appState.currentUser {
                settingsRow(icon: "person.fill", title: "Kullanıcı adı", value: "@\(user.username)")
                Button { showSubscription = true } label: {
                    settingsRow(
                        icon: "crown.fill",
                        title: "Abonelik",
                        value: appState.isPremium ? "Premium ✓" : "Ücretsiz → Yükselt"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Gizlilik")
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(GrippdTheme.Colors.accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: isPrivate ? "lock.fill" : "globe")
                        .font(.system(size: 16))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gizli Profil")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Text(isPrivate ? "Sadece takipçilerin loglarını görebilir" : "Herkes loglarını görebilir")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                if isSavingPrivacy {
                    ProgressView().tint(GrippdTheme.Colors.accent).scaleEffect(0.8)
                } else {
                    Toggle("", isOn: $isPrivate)
                        .labelsHidden()
                        .tint(GrippdTheme.Colors.accent)
                        .onChange(of: isPrivate) { _, newValue in
                            Task { await savePrivacy(newValue) }
                        }
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 12)
        }
    }

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Yasal")
            Button { showPrivacyPolicy = true } label: {
                settingsRow(icon: "hand.raised.fill", title: "Gizlilik Politikası", value: "")
            }
            .buttonStyle(.plain)
            Divider().background(.white.opacity(0.04)).padding(.leading, 66)
            Button { showTermsOfService = true } label: {
                settingsRow(icon: "doc.text.fill", title: "Kullanım Koşulları", value: "")
            }
            .buttonStyle(.plain)
            Divider().background(.white.opacity(0.04)).padding(.leading, 66)
            Button { showKVKK = true } label: {
                settingsRow(icon: "shield.lefthalf.filled", title: "KVKK Aydınlatma Metni", value: "")
            }
            .buttonStyle(.plain)
        }
    }

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Oturum")
            Button {
                showSignOutConfirm = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "arrow.right.square.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.red)
                    }
                    Text("Çıkış Yap")
                        .font(.system(size: 15))
                        .foregroundStyle(.red)
                    Spacer()
                    if isSigningOut {
                        ProgressView().tint(.red).scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, GrippdTheme.Spacing.md)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white.opacity(0.35))
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingsRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(GrippdTheme.Colors.accent.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(GrippdTheme.Colors.accent)
            }
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 12)
    }

    // MARK: - Actions

    private func savePrivacy(_ value: Bool) async {
        isSavingPrivacy = true
        do {
            try await SocialService.shared.updatePrivacy(isPrivate: value)
            appState.currentUser?.isPrivate = value
        } catch {
            isPrivate = !value
        }
        isSavingPrivacy = false
    }

    private func signOut() async {
        isSigningOut = true
        try? await AuthService.shared.signOut()
        await MainActor.run {
            appState.currentUser = nil
            appState.isAuthenticated = false
            appState.needsOnboarding = false
            appState.unreadNotificationCount = 0
        }
    }
}
