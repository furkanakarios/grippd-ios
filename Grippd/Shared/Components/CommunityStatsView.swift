import SwiftUI

struct CommunityStatsView: View {
    let contentKey: String

    @State private var stats: CommunityStats?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let stats, stats.reviewCount > 0 {
                statsView(stats)
            }
            // Veri yoksa hiçbir şey gösterme
        }
        .task { await load() }
    }

    // MARK: - Loading

    private var loadingView: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(GrippdTheme.Colors.surface)
                .frame(width: 80, height: 20)
            RoundedRectangle(cornerRadius: 6)
                .fill(GrippdTheme.Colors.surface)
                .frame(width: 60, height: 20)
        }
    }

    // MARK: - Stats

    private func statsView(_ stats: CommunityStats) -> some View {
        VStack(alignment: .leading, spacing: GrippdTheme.Spacing.sm) {
            Text("Topluluk Puanı")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
                .textCase(.uppercase)
                .tracking(1.2)

            HStack(spacing: GrippdTheme.Spacing.md) {
                // Yıldız + puan
                HStack(spacing: 6) {
                    starRow(rating: stats.avgRating)
                    Text(String(format: "%.1f", stats.avgRating))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                    Text("/ 10")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.35))
                }

                Spacer()

                // Yorum sayısı
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stats.reviewCount)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("değerlendirme")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .padding(GrippdTheme.Spacing.md)
        .background(GrippdTheme.Colors.surface, in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
    }

    private func starRow(rating: Double) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                let filled = Double(i + 1) * 2 <= rating
                let half = !filled && Double(i) * 2 < rating
                Image(systemName: filled ? "star.fill" : half ? "star.leadinghalf.filled" : "star")
                    .font(.system(size: 12))
                    .foregroundStyle(filled || half ? GrippdTheme.Colors.accent : .white.opacity(0.2))
            }
        }
    }

    private func load() async {
        stats = await CommunityService.shared.stats(for: contentKey)
        isLoading = false
    }
}
