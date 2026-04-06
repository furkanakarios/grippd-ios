import SwiftUI

@Observable
private final class SeasonDetailViewModel {
    var season: TMDBSeason?
    var isLoading = false
    var error: String?

    func load(showID: Int, seasonNumber: Int) async {
        guard season == nil else { return }
        isLoading = true
        error = nil
        do {
            season = try await TMDBClient.shared.seasonDetail(showID: showID, seasonNumber: seasonNumber)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct SeasonDetailView: View {
    let showID: Int
    let seasonNumber: Int

    @State private var viewModel = SeasonDetailViewModel()

    var body: some View {
        ZStack {
            GrippdBackground()

            if viewModel.isLoading {
                VStack(spacing: GrippdTheme.Spacing.md) {
                    ProgressView().scaleEffect(1.4).tint(GrippdTheme.Colors.accent)
                    Text("Yükleniyor...").font(.system(size: 14)).foregroundStyle(.white.opacity(0.4))
                }
            } else if let error = viewModel.error {
                VStack(spacing: GrippdTheme.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle").font(.system(size: 40))
                        .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.6))
                    Text(error).font(.system(size: 14)).foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center).padding(.horizontal, 32)
                }
            } else if let season = viewModel.season {
                seasonContent(season: season)
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle(viewModel.season?.name ?? "Sezon \(seasonNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load(showID: showID, seasonNumber: seasonNumber) }
    }

    private func seasonContent(season: TMDBSeason) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Season header
                seasonHeader(season: season)
                    .padding(.bottom, GrippdTheme.Spacing.md)

                // Episodes
                if let episodes = season.episodes, !episodes.isEmpty {
                    ForEach(episodes) { episode in
                        EpisodeRow(episode: episode)
                        Divider()
                            .background(.white.opacity(0.06))
                            .padding(.leading, GrippdTheme.Spacing.md)
                    }
                } else {
                    Text("Bölüm bulunamadı")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                }
            }
            .padding(.bottom, GrippdTheme.Spacing.xxl)
        }
    }

    private func seasonHeader(season: TMDBSeason) -> some View {
        HStack(spacing: GrippdTheme.Spacing.md) {
            AsyncImage(url: season.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Rectangle().fill(GrippdTheme.Colors.surface)
                        .overlay(Image(systemName: "tv").font(.system(size: 20)).foregroundStyle(.white.opacity(0.2)))
                }
            }
            .frame(width: 80, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: GrippdTheme.Radius.sm))
            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 8) {
                Text(season.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if let epCount = season.episodeCount {
                    Label("\(epCount) bölüm", systemImage: "play.rectangle.on.rectangle")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.55))
                }

                if let year = season.airDate?.split(separator: "-").first.map(String.init) {
                    Label(year, systemImage: "calendar")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.45))
                }

                if !season.overview.isEmpty {
                    Text(season.overview)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(3)
                        .lineSpacing(3)
                }
            }
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.top, GrippdTheme.Spacing.md)
    }
}

// MARK: - Episode Row

private struct EpisodeRow: View {
    let episode: TMDBEpisode
    @State private var showOverview = false

    var formattedRuntime: String? {
        guard let runtime = episode.runtime, runtime > 0 else { return nil }
        let h = runtime / 60, m = runtime % 60
        if h == 0 { return "\(m)dk" }
        if m == 0 { return "\(h)s" }
        return "\(h)s \(m)dk"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: GrippdTheme.Spacing.md) {
                // Still image
                AsyncImage(url: episode.stillURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle().fill(GrippdTheme.Colors.surface)
                            .overlay(
                                Text("\(episode.episodeNumber)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.2))
                            )
                    }
                }
                .frame(width: 120, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Episode info
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text("\(episode.episodeNumber).")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GrippdTheme.Colors.accent)
                        Text(episode.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        if let runtime = formattedRuntime {
                            Text(runtime)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.4))
                        }

                        if episode.voteAverage > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(GrippdTheme.Colors.accent)
                                Text(String(format: "%.1f", episode.voteAverage))
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                        }
                    }
                }

                Spacer()
            }

            // Overview (expandable)
            if !episode.overview.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(episode.overview)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineSpacing(4)
                        .lineLimit(showOverview ? nil : 2)

                    if episode.overview.count > 120 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { showOverview.toggle() }
                        } label: {
                            Text(showOverview ? "Daha az" : "Devamı")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GrippdTheme.Colors.accent)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
        .padding(.vertical, 12)
    }
}
