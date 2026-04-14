import SwiftUI

// MARK: - ViewModel

@Observable
private final class AdminStatsViewModel {
    var stats: AppStats?
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        error = nil
        do {
            stats = try await AdminStatsService.shared.fetchStats()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - AdminStatsView

struct AdminStatsView: View {
    @State private var viewModel = AdminStatsViewModel()

    var body: some View {
        ZStack {
            GrippdBackground()
            content
        }
        .navigationTitle("Uygulama İstatistikleri")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                }
            }
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            GrippdLoadingView(label: "İstatistikler yükleniyor...")
        } else if let error = viewModel.error {
            GrippdEmptyStateView(icon: "exclamationmark.triangle", title: "Hata", subtitle: error)
        } else if let stats = viewModel.stats {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Kullanıcılar
                    statsSection(title: "Kullanıcılar", icon: "person.2.fill", color: .blue) {
                        StatRow(label: "Toplam Kullanıcı",   value: stats.totalUsers,    icon: "person.fill",         color: .blue)
                        StatRow(label: "Premium",            value: stats.premiumUsers,  icon: "crown.fill",          color: .yellow)
                        StatRow(label: "Banlı",              value: stats.bannedUsers,   icon: "xmark.circle.fill",   color: .red)
                        StatRow(label: "Son 7 Günde Yeni",   value: stats.newUsers7d,    icon: "person.badge.plus",   color: .green)
                    }

                    // İçerik
                    statsSection(title: "İçerik", icon: "play.rectangle.fill", color: .purple) {
                        StatRow(label: "Toplam Log",         value: stats.totalLogs,     icon: "checkmark.circle.fill", color: .purple)
                        StatRow(label: "Son 7 Günde Log",    value: stats.newLogs7d,     icon: "clock.fill",            color: .indigo)
                        StatRow(label: "Toplam Yorum",       value: stats.totalComments, icon: "bubble.left.fill",      color: .cyan)
                    }

                    // Moderasyon
                    statsSection(title: "Moderasyon", icon: "shield.fill", color: .orange) {
                        StatRow(label: "Bekleyen Rapor",     value: stats.pendingReports,  icon: "exclamationmark.circle.fill", color: .orange)
                        StatRow(label: "Çözülen Rapor",      value: stats.resolvedReports, icon: "checkmark.shield.fill",       color: .green)
                    }

                    // Discover
                    statsSection(title: "Discover", icon: "list.star", color: .mint) {
                        StatRow(label: "Aktif Koleksiyon",   value: stats.activeCollections, icon: "square.grid.2x2.fill", color: .mint)
                    }

                    // Son güncelleme notu
                    Text("Veriler anlık hesaplanır")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.25))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, GrippdTheme.Spacing.xxl)
                }
                .padding(GrippdTheme.Spacing.md)
            }
        }
    }

    private func statsSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder rows: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 10)
            .background(color.opacity(0.08))

            rows()
        }
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                .stroke(.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - StatRow

private struct StatRow: View {
    let label: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color.opacity(0.8))
                .frame(width: 22)

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.65))

            Spacer()

            Text(value.formatted())
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 13)
        .background(.clear)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.05))
                .frame(height: 1)
                .padding(.leading, GrippdTheme.Spacing.md + 22 + 12)
        }
    }
}
