import SwiftUI

// MARK: - ViewModel

@Observable
private final class AdminUserManagementViewModel {
    var users: [AdminUserSummary] = []
    var searchQuery = ""
    var isLoading = false
    var error: String?

    private var searchTask: Task<Void, Never>?

    func load() async {
        await fetch(search: nil)
    }

    func onSearchChange() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await fetch(search: searchQuery.isEmpty ? nil : searchQuery)
        }
    }

    private func fetch(search: String?) async {
        isLoading = true
        error = nil
        do {
            users = try await AdminUserService.shared.fetchUsers(search: search)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func toggleBan(_ user: AdminUserSummary) async {
        guard let idx = users.firstIndex(where: { $0.id == user.id }) else { return }
        let newBanned = !users[idx].isBanned
        users[idx].isBanned = newBanned  // optimistic
        do {
            try await AdminUserService.shared.setBanned(userID: user.id, banned: newBanned)
            HapticManager.success()
        } catch {
            users[idx].isBanned = !newBanned  // revert
            HapticManager.error()
        }
    }

    func setPlan(_ user: AdminUserSummary, plan: String) async {
        guard let idx = users.firstIndex(where: { $0.id == user.id }) else { return }
        let old = users[idx].planType
        users[idx] = AdminUserSummary(
            id: users[idx].id, username: users[idx].username,
            displayName: users[idx].displayName, avatarURL: users[idx].avatarURL,
            planType: plan, isBanned: users[idx].isBanned, isAdmin: users[idx].isAdmin,
            logCount: users[idx].logCount, createdAt: users[idx].createdAt
        )
        do {
            try await AdminUserService.shared.setPlan(userID: user.id, plan: plan)
            HapticManager.success()
        } catch {
            users[idx] = AdminUserSummary(
                id: users[idx].id, username: users[idx].username,
                displayName: users[idx].displayName, avatarURL: users[idx].avatarURL,
                planType: old, isBanned: users[idx].isBanned, isAdmin: users[idx].isAdmin,
                logCount: users[idx].logCount, createdAt: users[idx].createdAt
            )
            HapticManager.error()
        }
    }
}

// MARK: - AdminUserManagementView

struct AdminUserManagementView: View {
    @State private var viewModel = AdminUserManagementViewModel()
    @State private var selectedUser: AdminUserSummary?

    var body: some View {
        ZStack {
            GrippdBackground()
            VStack(spacing: 0) {
                searchBar
                content
            }
        }
        .navigationTitle("Kullanıcı Yönetimi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
        .sheet(item: $selectedUser) { user in
            AdminUserDetailSheet(user: user) { updatedUser, action in
                Task {
                    switch action {
                    case .toggleBan:  await viewModel.toggleBan(updatedUser)
                    case .setPremium: await viewModel.setPlan(updatedUser, plan: "premium")
                    case .setFree:    await viewModel.setPlan(updatedUser, plan: "free")
                    }
                }
            }
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
            TextField("Kullanıcı ara...", text: $viewModel.searchQuery)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .tint(GrippdTheme.Colors.accent)
                .autocorrectionDisabled()
                .onChange(of: viewModel.searchQuery) { viewModel.onSearchChange() }
            if !viewModel.searchQuery.isEmpty {
                Button { viewModel.searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, GrippdTheme.Spacing.sm)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.users.isEmpty {
            GrippdLoadingView(label: "Kullanıcılar yükleniyor...")
        } else if let error = viewModel.error {
            GrippdEmptyStateView(icon: "exclamationmark.triangle", title: "Hata", subtitle: error)
        } else if viewModel.users.isEmpty {
            GrippdEmptyStateView(icon: "person.slash", title: "Kullanıcı bulunamadı")
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // Özet satırı
                    HStack {
                        Text("\(viewModel.users.count) kullanıcı")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.35))
                        Spacer()
                        let premiumCount = viewModel.users.filter { $0.isPremium }.count
                        Text("\(premiumCount) premium")
                            .font(.system(size: 12))
                            .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.8))
                        let bannedCount = viewModel.users.filter { $0.isBanned }.count
                        if bannedCount > 0 {
                            Text("· \(bannedCount) banlı")
                                .font(.system(size: 12))
                                .foregroundStyle(.red.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                    .padding(.bottom, GrippdTheme.Spacing.sm)

                    ForEach(viewModel.users) { user in
                        AdminUserRow(user: user) {
                            selectedUser = user
                        }
                        Divider()
                            .background(.white.opacity(0.06))
                            .padding(.leading, 70)
                    }
                }
                .padding(.bottom, GrippdTheme.Spacing.xxl)
            }
        }
    }
}

// MARK: - AdminUserRow

private struct AdminUserRow: View {
    let user: AdminUserSummary
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                CachedAsyncImage(url: user.avatarURL) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .frame(width: 46, height: 46)
                .clipShape(Circle())
                .background(GrippdTheme.Colors.accent.opacity(0.1), in: Circle())

                // Bilgi
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(user.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        if user.isAdmin {
                            adminBadge("Admin", color: .red)
                        }
                        if user.isBanned {
                            adminBadge("Banlı", color: .orange)
                        }
                    }
                    Text("@\(user.username)")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.45))
                }

                Spacer()

                // Sağ taraf
                VStack(alignment: .trailing, spacing: 4) {
                    // Plan badge
                    Text(user.isPremium ? "Premium" : "Free")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(user.isPremium ? GrippdTheme.Colors.accent : .white.opacity(0.4))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            user.isPremium
                                ? GrippdTheme.Colors.accent.opacity(0.15)
                                : Color.white.opacity(0.06),
                            in: Capsule()
                        )
                    // Log sayısı
                    Text("\(user.logCount) log")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.3))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.2))
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func adminBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
    }
}

// MARK: - AdminUserDetailSheet

enum AdminUserAction { case toggleBan, setPremium, setFree }

struct AdminUserDetailSheet: View {
    let user: AdminUserSummary
    let onAction: (AdminUserSummary, AdminUserAction) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showBanConfirm = false
    @State private var showPlanConfirm = false
    @State private var pendingPlan: String?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: "tr_TR")
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                GrippdBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        userHeader
                        statsSection
                        actionsSection
                    }
                    .padding(GrippdTheme.Spacing.md)
                }
            }
            .navigationTitle("Kullanıcı Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(GrippdTheme.Colors.accent)
                }
            }
            .confirmationDialog(
                user.isBanned ? "Kullanıcı banını kaldır?" : "Kullanıcıyı banla?",
                isPresented: $showBanConfirm,
                titleVisibility: .visible
            ) {
                Button(user.isBanned ? "Banı Kaldır" : "Banla", role: user.isBanned ? .none : .destructive) {
                    onAction(user, .toggleBan)
                    dismiss()
                }
                Button("İptal", role: .cancel) {}
            }
            .confirmationDialog(
                "Planı \(pendingPlan == "premium" ? "Premium" : "Free") yap?",
                isPresented: $showPlanConfirm,
                titleVisibility: .visible
            ) {
                Button("Onayla") {
                    if let plan = pendingPlan {
                        onAction(user, plan == "premium" ? .setPremium : .setFree)
                    }
                    dismiss()
                }
                Button("İptal", role: .cancel) {}
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var userHeader: some View {
        HStack(spacing: 14) {
            CachedAsyncImage(url: user.avatarURL) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())
            .background(GrippdTheme.Colors.accent.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text("@\(user.username)")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
                HStack(spacing: 6) {
                    if user.isPremium {
                        statusPill("Premium", color: GrippdTheme.Colors.accent)
                    } else {
                        statusPill("Free", color: .white.opacity(0.4))
                    }
                    if user.isAdmin { statusPill("Admin", color: .red) }
                    if user.isBanned { statusPill("Banlı", color: .orange) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GrippdTheme.Spacing.md)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("İstatistikler")
            detailRow(icon: "checkmark.circle", label: "Toplam Log", value: "\(user.logCount)")
            Divider().background(.white.opacity(0.06)).padding(.leading, 40)
            detailRow(icon: "calendar.badge.plus", label: "Kayıt Tarihi",
                      value: Self.dateFormatter.string(from: user.createdAt))
        }
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Aksiyonlar")

            // Plan değiştir
            HStack(spacing: 10) {
                Button {
                    pendingPlan = user.isPremium ? "free" : "premium"
                    showPlanConfirm = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: user.isPremium ? "crown.slash" : "crown.fill")
                        Text(user.isPremium ? "Free'ye Al" : "Premium Yap")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(GrippdTheme.Colors.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
                    .foregroundStyle(GrippdTheme.Colors.accent)
                }
                .buttonStyle(.plain)

                // Ban
                if !user.isAdmin {
                    Button {
                        showBanConfirm = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: user.isBanned ? "checkmark.shield" : "xmark.shield")
                            Text(user.isBanned ? "Banı Kaldır" : "Banla")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
                        .foregroundStyle(user.isBanned ? .green : .red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white.opacity(0.35))
            .tracking(1.2)
            .padding(.bottom, 8)
    }

    private func statusPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 12)
    }
}
