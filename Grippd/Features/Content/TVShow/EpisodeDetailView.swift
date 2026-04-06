import SwiftUI

// MARK: - ViewModel

@Observable
private final class EpisodeDetailViewModel {
    var episode: TMDBEpisode?
    var isLoading = false
    var error: String?
    var isWatched = false

    func load(showID: Int, seasonNumber: Int, episodeNumber: Int) async {
        guard episode == nil else { return }
        isLoading = true
        error = nil
        do {
            episode = try await TMDBClient.shared.episodeDetail(
                showID: showID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            )
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    var formattedVoteCount: String {
        let count = episode?.voteCount ?? 0
        if count >= 1000 { return String(format: "%.0fK", Double(count) / 1000) }
        return "\(count)"
    }
}

// MARK: - View

struct EpisodeDetailView: View {
    let showID: Int
    let seasonNumber: Int
    let episodeNumber: Int

    @State private var viewModel = EpisodeDetailViewModel()
    @State private var showFullOverview = false

    var body: some View {
        ZStack {
            GrippdTheme.Colors.background.ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(message: error)
            } else if let episode = viewModel.episode {
                contentView(episode: episode)
            }
        }
        .preferredColorScheme(.dark)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.load(
                showID: showID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            )
        }
    }

    // MARK: - Content

    private func contentView(episode: TMDBEpisode) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                stillSection(episode: episode)
                mainContent(episode: episode)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Still Hero

    private func stillSection(episode: TMDBEpisode) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                if let url = episode.stillURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: 230)
                        default:
                            stillPlaceholder(width: geo.size.width)
                        }
                    }
                    .frame(width: geo.size.width, height: 230)
                    .clipped()
                } else {
                    stillPlaceholder(width: geo.size.width)
                }

                // Gradient
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: GrippdTheme.Colors.background.opacity(0.6), location: 0.6),
                        .init(color: GrippdTheme.Colors.background, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geo.size.width, height: 230)

                // Episode badge (bottom-left of hero)
                HStack {
                    Text("S\(seasonNumber) · B\(episodeNumber)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GrippdTheme.Colors.background)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(GrippdTheme.Colors.accent, in: Capsule())
                    Spacer()
                }
                .padding(.horizontal, GrippdTheme.Spacing.md)
                .padding(.bottom, GrippdTheme.Spacing.lg)
            }
        }
        .frame(height: 230)
    }

    private func stillPlaceholder(width: CGFloat) -> some View {
        Rectangle()
            .fill(GrippdTheme.Colors.surface)
            .frame(width: width, height: 230)
            .overlay(
                Image(systemName: "play.rectangle")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.15))
            )
    }

    // MARK: - Main Content

    private func mainContent(episode: TMDBEpisode) -> some View {
        VStack(alignment: .leading, spacing: GrippdTheme.Spacing.lg) {
            // Title + Metadata
            titleSection(episode: episode)

            // Action button
            watchedButton

            // Overview
            if !episode.overview.isEmpty {
                overviewSection(text: episode.overview)
            }

            // Director / Writer
            if !episode.directors.isEmpty || !episode.writers.isEmpty {
                crewSection(episode: episode)
            }

            // Guest Stars
            let guests = episode.guestStars ?? []
            if !guests.isEmpty {
                guestStarsSection(guests: guests)
            }
        }
        .padding(.top, GrippdTheme.Spacing.md)
        .padding(.bottom, GrippdTheme.Spacing.xxl)
    }

    // MARK: - Title Section

    private func titleSection(episode: TMDBEpisode) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(episode.name)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(3)
                .padding(.horizontal, GrippdTheme.Spacing.md)

            // Metadata chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if let date = episode.formattedAirDate {
                        MetaChip(icon: "calendar", text: date)
                    }
                    if let runtime = episode.formattedRuntime {
                        MetaChip(icon: "clock", text: runtime)
                    }
                    if episode.voteAverage > 0 {
                        MetaChip(
                            icon: "star.fill",
                            text: String(format: "%.1f", episode.voteAverage),
                            iconColor: GrippdTheme.Colors.accent
                        )
                    }
                }
                .padding(.horizontal, GrippdTheme.Spacing.md)
            }
        }
    }

    // MARK: - Watched Button

    private var watchedButton: some View {
        Button {
            withAnimation(.spring(duration: 0.25)) {
                viewModel.isWatched.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: viewModel.isWatched ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(viewModel.isWatched ? Color(red: 0.2, green: 0.8, blue: 0.4) : .white.opacity(0.5))
                Text(viewModel.isWatched ? "İzlendi" : "İzledim olarak işaretle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(viewModel.isWatched ? Color(red: 0.2, green: 0.8, blue: 0.4) : .white.opacity(0.7))
                Spacer()
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 14)
            .background(
                viewModel.isWatched
                    ? Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.1)
                    : Color.white.opacity(0.05),
                in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                    .stroke(
                        viewModel.isWatched
                            ? Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.4)
                            : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
    }

    // MARK: - Overview

    private func overviewSection(text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Özet")
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.75))
                .lineSpacing(5)
                .lineLimit(showFullOverview ? nil : 5)

            if text.count > 200 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showFullOverview.toggle() }
                } label: {
                    Text(showFullOverview ? "Daha az göster" : "Devamını oku")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                }
            }
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
    }

    // MARK: - Crew Section

    private func crewSection(episode: TMDBEpisode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !episode.directors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("Yönetmen")
                    crewNames(episode.directors)
                }
            }
            if !episode.writers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("Senarist")
                    crewNames(episode.writers)
                }
            }
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
    }

    private func crewNames(_ members: [TMDBCrewMember]) -> some View {
        HStack(spacing: 8) {
            ForEach(members.prefix(3), id: \.creditID) { member in
                Text(member.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.sm))
            }
        }
    }

    // MARK: - Guest Stars

    private func guestStarsSection(guests: [TMDBCastMember]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Konuk Oyuncular")
                .padding(.horizontal, GrippdTheme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(guests.prefix(12), id: \.creditID) { guest in
                        EpisodeCastCard(member: guest)
                    }
                }
                .padding(.horizontal, GrippdTheme.Spacing.md)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.45))
            .textCase(.uppercase)
            .tracking(1.2)
    }

    private var loadingView: some View {
        VStack(spacing: GrippdTheme.Spacing.md) {
            ProgressView().scaleEffect(1.4).tint(GrippdTheme.Colors.accent)
            Text("Yükleniyor...").font(.system(size: 14)).foregroundStyle(.white.opacity(0.4))
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: GrippdTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40)).foregroundStyle(GrippdTheme.Colors.accent.opacity(0.6))
            Text("Yüklenemedi").font(GrippdTheme.Typography.title).foregroundStyle(.white)
            Text(message).font(.system(size: 14)).foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center).padding(.horizontal, 32)
        }
    }
}

// MARK: - Meta Chip

private struct MetaChip: View {
    let icon: String
    let text: String
    var iconColor: Color = .white.opacity(0.5)

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(iconColor)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.white.opacity(0.07), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Episode Cast Card

private struct EpisodeCastCard: View {
    let member: TMDBCastMember

    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: member.profileURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Circle().fill(GrippdTheme.Colors.surface)
                        .overlay(Image(systemName: "person.fill").font(.system(size: 22)).foregroundStyle(.white.opacity(0.25)))
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white.opacity(0.08), lineWidth: 1))

            VStack(spacing: 2) {
                Text(member.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                if !member.character.isEmpty {
                    Text(member.character)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(width: 80)
    }
}
