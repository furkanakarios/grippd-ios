import SwiftUI

// MARK: - Platform Availability Section

/// Fetches and displays streaming platform availability via TMDB Watch Providers (TR region).
struct PlatformAvailabilityView: View {
    enum ContentKind {
        case movie(tmdbID: Int)
        case tv(tmdbID: Int)
    }

    let kind: ContentKind

    @State private var entries: [TMDBProviderEntry] = []
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

            } else if failed || (!isLoading && entries.isEmpty) {
                Text(failed ? "Platform bilgisi alınamadı" : "Bu içerik şu an Türkiye platformlarında yayınlanmıyor")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.horizontal, GrippdTheme.Spacing.md)

            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(entries) { entry in
                            PlatformChip(entry: entry)
                        }
                    }
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                }
            }
        }
        .task { await fetchProviders() }
    }

    private var sectionHeader: some View {
        Text("Nerede İzlenir?")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.45))
            .textCase(.uppercase)
            .tracking(1.2)
            .padding(.horizontal, GrippdTheme.Spacing.md)
    }

    private func fetchProviders() async {
        isLoading = true
        failed = false
        do {
            switch kind {
            case .movie(let id):
                entries = try await TMDBClient.shared.watchProvidersForMovie(id: id)
            case .tv(let id):
                entries = try await TMDBClient.shared.watchProvidersForTV(id: id)
            }
        } catch {
            failed = true
        }
        isLoading = false
    }
}

// MARK: - Platform Chip

private struct PlatformChip: View {
    let entry: TMDBProviderEntry

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(platformColor)
                    .frame(width: 52, height: 52)

                if let logoURL = entry.provider.logoURL {
                    AsyncImage(url: logoURL) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            platformFallbackLabel
                        }
                    }
                } else {
                    platformFallbackLabel
                }
            }

            Text(entry.type.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(typeColor)
        }
    }

    private var platformFallbackLabel: some View {
        Text(shortName)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(6)
    }

    private var shortName: String {
        let lower = entry.provider.providerName.lowercased()
        if lower.contains("amazon prime") || lower.contains("prime video") { return "Prime" }
        if lower.contains("apple tv") { return "Apple TV+" }
        if lower.contains("disney") { return "Disney+" }
        if lower.contains("netflix") { return "Netflix" }
        if lower.contains("mubi") { return "MUBI" }
        if lower.contains("blutv") { return "BluTV" }
        if lower.contains("gain") { return "Gain" }
        if lower.contains("exxen") { return "Exxen" }
        if lower.contains("hbo") || lower.contains("max") { return "Max" }
        if lower.contains("hulu") { return "Hulu" }
        return entry.provider.providerName
    }

    private var platformColor: Color {
        let lower = entry.provider.providerName.lowercased()
        if lower.contains("netflix") { return Color(red: 0.9, green: 0.1, blue: 0.1) }
        if lower.contains("disney") { return Color(red: 0.05, green: 0.18, blue: 0.55) }
        if lower.contains("prime") || lower.contains("amazon") { return Color(red: 0.0, green: 0.46, blue: 0.75) }
        if lower.contains("apple") { return Color(red: 0.35, green: 0.35, blue: 0.38) }
        if lower.contains("mubi") { return Color(red: 0.0, green: 0.48, blue: 0.4) }
        if lower.contains("blutv") { return Color(red: 0.42, green: 0.15, blue: 0.75) }
        if lower.contains("gain") { return Color(red: 0.85, green: 0.25, blue: 0.1) }
        if lower.contains("exxen") { return Color(red: 0.75, green: 0.1, blue: 0.15) }
        if lower.contains("hbo") || lower.contains("max") { return Color(red: 0.45, green: 0.05, blue: 0.75) }
        if lower.contains("hulu") { return Color(red: 0.1, green: 0.78, blue: 0.48) }
        return Color(red: 0.22, green: 0.22, blue: 0.26)
    }

    private var typeColor: Color {
        switch entry.type {
        case .flatrate: return Color(red: 0.2, green: 0.78, blue: 0.45)
        case .free: return Color(red: 0.4, green: 0.8, blue: 0.9)
        case .rent: return Color(red: 0.91, green: 0.70, blue: 0.29)
        case .buy: return Color(red: 0.4, green: 0.6, blue: 1.0)
        }
    }
}
