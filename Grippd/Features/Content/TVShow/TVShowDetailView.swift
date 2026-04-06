import SwiftUI

struct TVShowDetailView: View {
    let tmdbID: Int
    /// Closure called when user taps a season row — pushes onto the caller's NavigationPath
    var onSeasonTap: ((Int, Int) -> Void)?

    @State private var viewModel = TVShowDetailViewModel()
    @State private var showFullOverview = false
    @State private var showLogSheet = false
    @State private var isLogged = false
    @State private var loggedRating: Double? = nil

    private var contentKey: String { "tv-\(tmdbID)" }

    var body: some View {
        ZStack {
            GrippdTheme.Colors.background.ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(message: error)
            } else if let show = viewModel.show {
                contentView(show: show)
            }
        }
        .preferredColorScheme(.dark)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load(tmdbID: tmdbID) }
        .onAppear { refreshLogState() }
        .sheet(isPresented: $showLogSheet) {
            LogEntrySheet(
                contentKey: contentKey,
                contentType: .tv_show,
                contentTitle: viewModel.show?.name ?? "",
                posterPath: viewModel.show?.posterPath,
                isPresented: $showLogSheet
            ) { refreshLogState() }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func refreshLogState() {
        isLogged = LogService.shared.isLogged(contentKey: contentKey)
        loggedRating = LogService.shared.latestLog(for: contentKey)?.rating
    }

    // MARK: - Content

    private func contentView(show: TMDBTVShow) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                backdropSection(show: show)
                mainContent(show: show)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Backdrop

    private func backdropSection(show: TMDBTVShow) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                AsyncImage(url: show.backdropURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: 220)
                    case .failure:
                        Rectangle().fill(GrippdTheme.Colors.surface)
                    default:
                        Rectangle().fill(GrippdTheme.Colors.surface)
                            .overlay(ProgressView().tint(.white.opacity(0.4)))
                    }
                }
                .frame(width: geo.size.width, height: 220)
                .clipped()

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: GrippdTheme.Colors.background.opacity(0.55), location: 0.55),
                        .init(color: GrippdTheme.Colors.background, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geo.size.width, height: 220)
            }
        }
        .frame(height: 220)
    }

    // MARK: - Main Content

    private func mainContent(show: TMDBTVShow) -> some View {
        VStack(spacing: 0) {
            posterTitleRow(show: show)
                .padding(.horizontal, GrippdTheme.Spacing.md)
                .padding(.top, -50)

            VStack(alignment: .leading, spacing: GrippdTheme.Spacing.lg) {
                if let genres = show.genres, !genres.isEmpty {
                    genrePills(genres: genres)
                }

                actionButtons(show: show)

                if !show.overview.isEmpty {
                    overviewSection(text: show.overview)
                }

                if let creators = show.createdBy, !creators.isEmpty {
                    creatorSection(creators: creators)
                }

                // Community stats
                CommunityStatsView(contentKey: "tv-\(tmdbID)")
                    .padding(.horizontal, GrippdTheme.Spacing.md)

                // Streaming platforms
                PlatformAvailabilityView(kind: .tv(tmdbID: tmdbID))

                if !viewModel.mainCast.isEmpty {
                    castSection
                }

                if !show.mainSeasons.isEmpty {
                    seasonsSection(show: show)
                }
            }
            .padding(.top, GrippdTheme.Spacing.lg)
            .padding(.bottom, GrippdTheme.Spacing.xxl)
        }
    }

    // MARK: - Poster + Title

    private func posterTitleRow(show: TMDBTVShow) -> some View {
        HStack(alignment: .bottom, spacing: GrippdTheme.Spacing.md) {
            AsyncImage(url: show.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    posterPlaceholder
                }
            }
            .frame(width: 110, height: 165)
            .clipShape(RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
            .shadow(color: .black.opacity(0.6), radius: 16, y: 8)

            VStack(alignment: .leading, spacing: 6) {
                Text(show.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(3)

                if show.originalName != show.name {
                    Text(show.originalName)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }

                if let yearRange = show.airYearRange {
                    Text(yearRange)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.55))
                }

                if let summary = viewModel.seasonSummary {
                    Text(summary)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.55))
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                    Text(String(format: "%.1f", show.voteAverage))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("(\(viewModel.formattedVoteCount))")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
            .fill(GrippdTheme.Colors.surface)
            .overlay(
                Image(systemName: "tv")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.2))
            )
    }

    // MARK: - Genre Pills

    private func genrePills(genres: [TMDBGenre]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(genres, id: \.id) { genre in
                    Text(genre.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(GrippdTheme.Colors.accent.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(GrippdTheme.Colors.accent.opacity(0.35), lineWidth: 1))
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(show: TMDBTVShow) -> some View {
        HStack(spacing: 10) {
            TVActionButton(
                icon: isLogged ? "checkmark.circle.fill" : "checkmark.circle",
                label: isLogged ? "İzlendi" : "İzledim",
                isActive: isLogged,
                activeColor: Color(red: 0.2, green: 0.8, blue: 0.4),
                badge: loggedRating.map { AnyView(StarRatingBadge(rating: $0, fontSize: 12)) }
            ) { showLogSheet = true }

            TVActionButton(
                icon: viewModel.isBookmarked ? "bookmark.fill" : "bookmark",
                label: "Listele",
                isActive: viewModel.isBookmarked,
                activeColor: GrippdTheme.Colors.accent
            ) { viewModel.isBookmarked.toggle() }

            ShareLink(item: "Grippd'de \(show.name) dizisini keşfet!") {
                VStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: GrippdTheme.Radius.sm)
                            .fill(.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: GrippdTheme.Radius.sm)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(height: 52)

                    Text("Paylaş")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
    }

    // MARK: - Overview

    private func overviewSection(text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Hakkında")
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.75))
                .lineSpacing(5)
                .lineLimit(showFullOverview ? nil : 4)

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

    // MARK: - Creators

    private func creatorSection(creators: [TMDBShowCreator]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(creators.count > 1 ? "Yaratıcılar" : "Yaratıcı")
            HStack(spacing: 8) {
                ForEach(creators) { creator in
                    HStack(spacing: 8) {
                        AsyncImage(url: creator.profileURL) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Circle().fill(GrippdTheme.Colors.surface)
                                    .overlay(Image(systemName: "person.fill").font(.system(size: 14)).foregroundStyle(.white.opacity(0.3)))
                            }
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())

                        Text(creator.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: GrippdTheme.Radius.sm))
                }
            }
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
    }

    // MARK: - Cast

    private var castSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Oyuncular")
                .padding(.horizontal, GrippdTheme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(viewModel.mainCast, id: \.creditID) { member in
                        TVCastCard(member: member)
                    }
                }
                .padding(.horizontal, GrippdTheme.Spacing.md)
            }
        }
    }

    // MARK: - Seasons

    private func seasonsSection(show: TMDBTVShow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Sezonlar")
                .padding(.horizontal, GrippdTheme.Spacing.md)

            VStack(spacing: 1) {
                ForEach(show.mainSeasons) { season in
                    SeasonRow(season: season) {
                        onSeasonTap?(show.id, season.seasonNumber)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
            .padding(.horizontal, GrippdTheme.Spacing.md)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.45))
            .textCase(.uppercase)
            .tracking(1.2)
    }

    // MARK: - Loading & Error

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
                .multilineTextAlignment(.center).padding(.horizontal, GrippdTheme.Spacing.xl)
        }
    }
}

// MARK: - TV Action Button

private struct TVActionButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let activeColor: Color
    var badge: AnyView? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: GrippdTheme.Radius.sm)
                        .fill(isActive ? activeColor.opacity(0.15) : .white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: GrippdTheme.Radius.sm)
                                .stroke(isActive ? activeColor.opacity(0.5) : .white.opacity(0.1), lineWidth: 1)
                        )
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(isActive ? activeColor : .white.opacity(0.7))
                        .animation(.spring(duration: 0.2), value: isActive)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .overlay(alignment: .topTrailing) {
                    if let badge {
                        badge
                            .offset(x: 8, y: -8)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isActive ? activeColor.opacity(0.9) : .white.opacity(0.45))
            }
        }
        .animation(.spring(response: 0.3), value: badge != nil)
    }
}

// MARK: - Cast Card

private struct TVCastCard: View {
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

                Text(member.character)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 80)
    }
}

// MARK: - Season Row

private struct SeasonRow: View {
    let season: TMDBSeason
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: GrippdTheme.Spacing.md) {
                AsyncImage(url: season.posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle().fill(GrippdTheme.Colors.surface)
                            .overlay(Image(systemName: "tv").font(.system(size: 16)).foregroundStyle(.white.opacity(0.2)))
                    }
                }
                .frame(width: 54, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 5) {
                    Text(season.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if let epCount = season.episodeCount {
                        Text("\(epCount) bölüm")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.45))
                    }

                    if let year = season.airDate?.split(separator: "-").first.map(String.init) {
                        Text(year)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 10)
            .background(GrippdTheme.Colors.surface)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
