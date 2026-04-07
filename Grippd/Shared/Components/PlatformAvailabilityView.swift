import SwiftUI

// MARK: - Platform Availability Section

/// Fetches and displays streaming platform availability.
/// Drop into MovieDetailView or TVShowDetailView.
struct PlatformAvailabilityView: View {
    enum ContentKind {
        case movie(tmdbID: Int)
        case tv(tmdbID: Int)
    }

    let kind: ContentKind

    @State private var sources: [WatchmodeSource] = []
    @State private var isLoading = false
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            if isLoading {
                HStack {
                    ProgressView().tint(GrippdTheme.Colors.accent)
                    Text("Platformlar kontrol ediliyor...")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(.horizontal, GrippdTheme.Spacing.md)

            } else if failed || (!isLoading && sources.isEmpty) {
                Text(failed ? "Platform bilgisi alınamadı" : "Bu içerik şu an Türkiye platformlarında yayınlanmıyor")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.horizontal, GrippdTheme.Spacing.md)

            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(sources) { source in
                            PlatformChip(source: source)
                        }
                    }
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                }
            }
        }
        .task { await fetchSources() }
    }

    private var sectionHeader: some View {
        Text("Nerede İzlenir?")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.45))
            .textCase(.uppercase)
            .tracking(1.2)
            .padding(.horizontal, GrippdTheme.Spacing.md)
    }

    private func fetchSources() async {
        isLoading = true
        failed = false
        do {
            switch kind {
            case .movie(let id):
                sources = try await WatchmodeClient.shared.sourcesForMovie(tmdbID: id)
            case .tv(let id):
                sources = try await WatchmodeClient.shared.sourcesForTV(tmdbID: id)
            }
        } catch WatchmodeError.missingAPIKey {
            // API key not configured yet — silently hide the section
            failed = false
            sources = []
        } catch {
            failed = true
        }
        isLoading = false
    }
}

// MARK: - Platform Chip

private struct PlatformChip: View {
    let source: WatchmodeSource

    var body: some View {
        VStack(spacing: 6) {
            Text(shortName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(source.platformColor, in: RoundedRectangle(cornerRadius: 10))

            Text(source.type.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(source.type.color)
        }
    }

    // Normalize well-known platform names
    private var shortName: String {
        let lower = source.name.lowercased()
        if lower.contains("amazon prime") { return "Prime Video" }
        if lower.contains("apple tv") { return "Apple TV+" }
        if lower.contains("disney") { return "Disney+" }
        return source.name
    }
}
