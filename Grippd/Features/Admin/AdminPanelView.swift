import SwiftUI

// MARK: - AdminPanelView
/// Sadece is_admin = true kullanıcılar için erişilebilir.
/// Her Phase 8 step'i bu view'a kendi section'ını ekler.

struct AdminPanelView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ZStack {
                GrippdBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        adminHeader
                        menuSections
                    }
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                    .padding(.top, GrippdTheme.Spacing.lg)
                    .padding(.bottom, GrippdTheme.Spacing.xxl)
                }
            }
            .navigationTitle("Admin Paneli")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(GrippdTheme.Colors.accent)
                }
            }
        }
    }

    // MARK: - Header

    private var adminHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "shield.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.red.opacity(0.85))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Admin Paneli")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Text("@\(appState.currentUser?.username ?? "")")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
        }
        .padding(GrippdTheme.Spacing.md)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Menu Sections

    private var menuSections: some View {
        VStack(spacing: 12) {
            // Step 2 — Kullanıcı Yönetimi
            AdminMenuSection(
                icon: "person.2.fill",
                title: "Kullanıcı Yönetimi",
                subtitle: "Listele, ara, ban/unban, plan değiştir",
                color: .blue,
                destination: AnyView(AdminUserManagementView())
            )

            // Step 3 — İçerik Moderasyonu
            AdminMenuSection(
                icon: "flag.fill",
                title: "İçerik Moderasyonu",
                subtitle: "Raporlanan yorumlar, içerik kaldırma",
                color: .orange,
                destination: AnyView(AdminContentModerationView())
            )

            // Step 4 — Curated Listeler
            AdminMenuSection(
                icon: "list.star",
                title: "Küratör Listeler",
                subtitle: "Discover'daki koleksiyonları yönet",
                color: .purple,
                destination: AnyView(AdminCuratedListsView())
            )

            // Step 5 — Uygulama İstatistikleri
            AdminMenuSection(
                icon: "chart.bar.fill",
                title: "Uygulama İstatistikleri",
                subtitle: "Kullanıcı, log, aktif oturum sayıları",
                color: .green,
                destination: AnyView(AdminComingSoonView(title: "Uygulama İstatistikleri"))
            )

            // Step 6 — Push Bildirim
            AdminMenuSection(
                icon: "bell.badge.fill",
                title: "Push Bildirim Gönder",
                subtitle: "Tüm kullanıcılara veya segmente duyuru",
                color: .yellow,
                destination: AnyView(AdminComingSoonView(title: "Push Bildirim"))
            )

            // Step 7 — A/B Test
            AdminMenuSection(
                icon: "arrow.triangle.branch",
                title: "A/B Test",
                subtitle: "Kullanıcı gruplama, varyant atama",
                color: .cyan,
                destination: AnyView(AdminComingSoonView(title: "A/B Test"))
            )

            // Step 8 — Feature Flags
            AdminMenuSection(
                icon: "switch.2",
                title: "Feature Flags",
                subtitle: "Özellikleri canlıda açıp kapat",
                color: .mint,
                destination: AnyView(AdminComingSoonView(title: "Feature Flags"))
            )
        }
    }
}

// MARK: - AdminMenuSection

private struct AdminMenuSection: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let destination: AnyView

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.2))
            }
            .padding(GrippdTheme.Spacing.md)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder (Sonraki step'ler dolduracak)

struct AdminComingSoonView: View {
    let title: String

    var body: some View {
        ZStack {
            GrippdBackground()
            VStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 40))
                    .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.4))
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text("Yakında eklenecek")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
