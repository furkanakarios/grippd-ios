import SwiftUI

struct MovieDetailView: View {
    let tmdbID: Int

    @State private var viewModel = MovieDetailViewModel()
    @State private var showFullOverview = false

    var body: some View {
        ZStack {
            GrippdTheme.Colors.background.ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(message: error)
            } else if let movie = viewModel.movie {
                contentView(movie: movie)
            }
        }
        .preferredColorScheme(.dark)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load(tmdbID: tmdbID) }
    }

    // MARK: - Content

    private func contentView(movie: TMDBMovie) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                backdropSection(movie: movie)
                mainContent(movie: movie)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Backdrop

    private func backdropSection(movie: TMDBMovie) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                AsyncImage(url: movie.backdropURL) { phase in
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

    private func mainContent(movie: TMDBMovie) -> some View {
        VStack(spacing: 0) {
            // Poster + Title row (pulls up 50pt into the backdrop area)
            posterTitleRow(movie: movie)
                .padding(.horizontal, GrippdTheme.Spacing.md)
                .padding(.top, -50)

            VStack(alignment: .leading, spacing: GrippdTheme.Spacing.lg) {
                // Genre pills
                if let genres = movie.genres, !genres.isEmpty {
                    genrePills(genres: genres)
                }

                // Action buttons
                actionButtons(movie: movie)

                // Overview
                if !movie.overview.isEmpty {
                    overviewSection(text: movie.overview)
                }

                // Streaming platforms
                PlatformAvailabilityView(kind: .movie(tmdbID: tmdbID))

                // Director
                if !viewModel.directors.isEmpty {
                    directorSection
                }

                // Cast
                if !viewModel.mainCast.isEmpty {
                    castSection
                }
            }
            .padding(.top, GrippdTheme.Spacing.lg)
            .padding(.bottom, GrippdTheme.Spacing.xxl)
        }
    }

    // MARK: - Poster + Title

    private func posterTitleRow(movie: TMDBMovie) -> some View {
        HStack(alignment: .bottom, spacing: GrippdTheme.Spacing.md) {
            // Poster
            AsyncImage(url: movie.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    posterPlaceholder
                default:
                    posterPlaceholder
                        .overlay(ProgressView().tint(.white.opacity(0.3)))
                }
            }
            .frame(width: 110, height: 165)
            .clipShape(RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
            .shadow(color: .black.opacity(0.6), radius: 16, y: 8)

            // Title + Meta
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(3)

                // Original title (if different)
                if movie.originalTitle != movie.title {
                    Text(movie.originalTitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }

                // Year + Runtime
                HStack(spacing: 6) {
                    if let year = movie.releaseYear {
                        Text(year)
                    }
                    if let runtime = viewModel.formattedRuntime {
                        Text("·")
                        Text(runtime)
                    }
                }
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.55))

                // Rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                    Text(String(format: "%.1f", movie.voteAverage))
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
                Image(systemName: "film")
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
                        .overlay(
                            Capsule().stroke(GrippdTheme.Colors.accent.opacity(0.35), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(movie: TMDBMovie) -> some View {
        HStack(spacing: 10) {
            MovieActionButton(
                icon: viewModel.isWatched ? "checkmark.circle.fill" : "checkmark.circle",
                label: "İzledim",
                isActive: viewModel.isWatched,
                activeColor: Color(red: 0.2, green: 0.8, blue: 0.4)
            ) {
                viewModel.isWatched.toggle()
            }

            MovieActionButton(
                icon: viewModel.isBookmarked ? "bookmark.fill" : "bookmark",
                label: "Listele",
                isActive: viewModel.isBookmarked,
                activeColor: GrippdTheme.Colors.accent
            ) {
                viewModel.isBookmarked.toggle()
            }

            ShareLink(item: "Grippd'de \(movie.title) filmini keşfet!") {
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
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showFullOverview.toggle()
                    }
                } label: {
                    Text(showFullOverview ? "Daha az göster" : "Devamını oku")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                }
            }
        }
        .padding(.horizontal, GrippdTheme.Spacing.md)
    }

    // MARK: - Director

    private var directorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Yönetmen")

            HStack(spacing: 8) {
                ForEach(viewModel.directors, id: \.creditID) { crew in
                    HStack(spacing: 8) {
                        AsyncImage(url: crew.profileURL) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Circle().fill(GrippdTheme.Colors.surface)
                                    .overlay(Image(systemName: "person.fill").font(.system(size: 14)).foregroundStyle(.white.opacity(0.3)))
                            }
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())

                        Text(crew.name)
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
                        CastCard(member: member)
                    }
                }
                .padding(.horizontal, GrippdTheme.Spacing.md)
            }
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
            ProgressView()
                .scaleEffect(1.4)
                .tint(GrippdTheme.Colors.accent)
            Text("Yükleniyor...")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: GrippdTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.6))
            Text("Yüklenemedi")
                .font(GrippdTheme.Typography.title)
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, GrippdTheme.Spacing.xl)
        }
    }
}

// MARK: - Movie Action Button

private struct MovieActionButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let activeColor: Color
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

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isActive ? activeColor.opacity(0.9) : .white.opacity(0.45))
            }
        }
    }
}

// MARK: - Cast Card

private struct CastCard: View {
    let member: TMDBCastMember

    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: member.profileURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Circle()
                        .fill(GrippdTheme.Colors.surface)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white.opacity(0.25))
                        )
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
