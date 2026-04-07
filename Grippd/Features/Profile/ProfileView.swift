import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var authVM = AuthViewModel()
    @State private var showSignOutConfirm = false
    @State private var selectedTab: ProfileTab = .logs

    enum ProfileTab: String, CaseIterable {
        case logs = "Loglar"
        case watchlist = "Listelerim"
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

    // MARK: - Header

    private var headerSection: some View {
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

            // Stats
            let stats = LogService.shared.stats()
            let watchlistCount = WatchlistService.shared.all().count
            HStack(spacing: 0) {
                StatItem(value: "\(stats.totalMovies + stats.totalShows + stats.totalBooks)", label: "Log")
                Divider().frame(height: 28).background(.white.opacity(0.1))
                StatItem(value: "\(watchlistCount)", label: "Listede")
                Divider().frame(height: 28).background(.white.opacity(0.1))
                if let avg = stats.averageRating {
                    StatItem(value: String(format: "%.1f", avg), label: "Ort. Puan")
                } else {
                    StatItem(value: "—", label: "Ort. Puan")
                }
            }
            .padding(.vertical, 16)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
            .padding(.top, 8)
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
        case .settings: SettingsPlaceholderView()
        case .editProfile: Text("Profil Düzenle — Phase 4").foregroundStyle(.white)
        case .followers: Text("Takipçiler — Phase 4").foregroundStyle(.white)
        case .following: Text("Takip Edilenler — Phase 4").foregroundStyle(.white)
        case .contentDetail: Text("İçerik Detay").foregroundStyle(.white)
        case .userProfile: Text("Kullanıcı Profil — Phase 4").foregroundStyle(.white)
        case .customList(let listID):
            if let list = CustomListService.shared.allLists().first(where: { $0.id == listID }) {
                CustomListDetailView(list: list)
            }
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
                emptyState(
                    icon: "checkmark.circle",
                    message: filter == nil ? "Henüz log yok" : "Bu kategoride log yok"
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
    @State private var entries: [WatchlistEntry] = []
    @State private var customLists: [CustomList] = []
    @State private var filter: Content.ContentType? = nil
    @State private var showCreateList = false

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
                emptyState(
                    icon: "bookmark",
                    message: filter == nil ? "Listelenen içerik yok" : "Bu kategoride içerik yok"
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
                            showCreateList = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(GrippdTheme.Colors.accent)
                        }
                    }

                    if customLists.isEmpty {
                        Button {
                            showCreateList = true
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
                        ForEach(customLists) { list in
                            Button {
                                router.profilePath.append(ProfileRoute.customList(listID: list.id))
                            } label: {
                                CustomListRow(list: list)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    CustomListService.shared.deleteList(list)
                                    customLists = CustomListService.shared.allLists()
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                            Divider().background(.white.opacity(0.06)).padding(.leading, 72)
                        }
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
                AsyncImage(url: log.posterURL) { phase in
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

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.2))
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
                AsyncImage(url: entry.posterURL) { phase in
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

// MARK: - Empty State

private func emptyState(icon: String, message: String) -> some View {
    VStack(spacing: GrippdTheme.Spacing.md) {
        Spacer(minLength: 60)
        Image(systemName: icon)
            .font(.system(size: 44))
            .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.2))
        Text(message)
            .font(.system(size: 14))
            .foregroundStyle(.white.opacity(0.35))
        Spacer(minLength: 60)
    }
    .frame(maxWidth: .infinity)
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
