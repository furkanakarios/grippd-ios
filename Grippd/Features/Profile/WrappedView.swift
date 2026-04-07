import SwiftUI

// MARK: - Wrapped View

struct WrappedView: View {
    let stats: LogService.WrappedStats
    @Binding var isPresented: Bool

    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging = false

    private let pageCount = 7

    var body: some View {
        ZStack(alignment: .top) {
            // Background gradient changes per page
            pageBackground(for: currentPage)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Text("\(stats.year) Özeti")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Page indicator dots
                HStack(spacing: 6) {
                    ForEach(0..<pageCount, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.white : Color.white.opacity(0.25))
                            .frame(width: i == currentPage ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 12)

                // Pages
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    totalPage.tag(1)
                    typePage.tag(2)
                    ratingPage.tag(3)
                    platformPage.tag(4)
                    streakPage.tag(5)
                    personalityPage.tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentPage)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Backgrounds

    @ViewBuilder
    private func pageBackground(for page: Int) -> some View {
        let gradients: [[Color]] = [
            [Color(hex: "#1a0a2e"), Color(hex: "#16213e")],
            [Color(hex: "#0f2027"), Color(hex: "#203a43")],
            [Color(hex: "#1a1a2e"), Color(hex: "#16213e")],
            [Color(hex: "#2d1b69"), Color(hex: "#11998e").opacity(0.3)],
            [Color(hex: "#0f0c29"), Color(hex: "#302b63")],
            [Color(hex: "#1a0533"), Color(hex: "#2d1b69")],
            [Color(hex: "#0d0d0d"), Color(hex: "#1a0a2e")],
        ]
        let colors = page < gradients.count ? gradients[page] : gradients[0]
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: - Page 0: Welcome

    private var welcomePage: some View {
        WrappedPageLayout {
            VStack(spacing: 20) {
                Text("✨")
                    .font(.system(size: 72))
                Text("\(stats.year)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Yılın nasıl geçti\nbir bakalım")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Spacer().frame(height: 20)

                Text("Kaydır →")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }

    // MARK: - Page 1: Total

    private var totalPage: some View {
        WrappedPageLayout {
            VStack(spacing: 16) {
                Text("Bu yıl")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))

                Text("\(stats.totalLogged)")
                    .font(.system(size: 96, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)

                Text("içerik izledin / okudun")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))

                Spacer().frame(height: 24)

                HStack(spacing: 20) {
                    countChip(icon: "film", count: stats.totalMovies, label: "Film", color: GrippdTheme.Colors.accent)
                    countChip(icon: "tv", count: stats.totalShows, label: "Dizi", color: .blue)
                    countChip(icon: "book.closed", count: stats.totalBooks, label: "Kitap", color: .green)
                }
            }
        }
    }

    // MARK: - Page 2: Content Type

    private var typePage: some View {
        let total = max(stats.totalLogged, 1)
        let dominant: (icon: String, label: String, count: Int, color: Color) = {
            if stats.totalMovies >= stats.totalShows && stats.totalMovies >= stats.totalBooks {
                return ("film", "film", stats.totalMovies, GrippdTheme.Colors.accent)
            } else if stats.totalShows >= stats.totalBooks {
                return ("tv", "dizi", stats.totalShows, .blue)
            } else {
                return ("book.closed", "kitap", stats.totalBooks, .green)
            }
        }()

        return WrappedPageLayout {
            VStack(spacing: 20) {
                Image(systemName: dominant.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(dominant.color)

                Text("En çok")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.6))
                Text(dominant.label)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("izledin/okudun")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer().frame(height: 16)

                VStack(spacing: 10) {
                    typeBar(icon: "film", label: "Filmler", count: stats.totalMovies, total: total, color: GrippdTheme.Colors.accent)
                    typeBar(icon: "tv", label: "Diziler", count: stats.totalShows, total: total, color: .blue)
                    typeBar(icon: "book.closed", label: "Kitaplar", count: stats.totalBooks, total: total, color: .green)
                }
                .padding(.horizontal, 8)

                if let month = stats.mostActiveMonth, stats.mostActiveMonthCount > 1 {
                    Text("En aktif ay: \(month) (\(stats.mostActiveMonthCount) içerik)")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.top, 8)
                }
            }
        }
    }

    // MARK: - Page 3: Rating

    private var ratingPage: some View {
        WrappedPageLayout {
            VStack(spacing: 20) {
                if let avg = stats.averageRating {
                    Text("Ortalama\npuanın")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", avg))
                            .font(.system(size: 80, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("/ 10")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Text(ratingComment(avg))
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    if let title = stats.topRatedTitle, let r = stats.topRatedRating {
                        Spacer().frame(height: 12)
                        VStack(spacing: 6) {
                            Text("En yüksek puan")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.4))
                                .textCase(.uppercase)
                                .tracking(1)
                            Text(title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill").foregroundStyle(GrippdTheme.Colors.accent)
                                Text(String(format: "%.1f", r)).foregroundStyle(.white)
                            }
                            .font(.system(size: 15, weight: .medium))
                        }
                        .padding(16)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                    }
                } else {
                    Text("😴")
                        .font(.system(size: 72))
                    Text("Henüz puan\nvermedin")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    // MARK: - Page 4: Platform

    private var platformPage: some View {
        WrappedPageLayout {
            VStack(spacing: 20) {
                if let platform = stats.topPlatform {
                    Text("En çok kullandığın\nplatform")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)

                    Text(platformEmoji(platform))
                        .font(.system(size: 64))

                    Text(platform.displayName)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                } else {
                    Text("📱")
                        .font(.system(size: 72))
                    Text("Platform bilgisi\ngirilmemiş")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }

                if stats.rewatchCount > 0 {
                    Spacer().frame(height: 12)
                    Text("Ayrıca \(stats.rewatchCount) kez tekrar izledin")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.55))
                }

                if let first = stats.firstLogTitle, let date = stats.firstLogDate {
                    Spacer().frame(height: 8)
                    VStack(spacing: 4) {
                        Text("Yılın ilk içeriği")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                            .textCase(.uppercase)
                            .tracking(1)
                        Text(first)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        Text(date.formatted(.dateTime.day().month(.wide)))
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(14)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    // MARK: - Page 5: Streak

    private var streakPage: some View {
        WrappedPageLayout {
            VStack(spacing: 16) {
                Text("🔥")
                    .font(.system(size: 64))

                Text("En uzun\nlog serisi")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(stats.longestStreak)")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("gün")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Text(streakComment(stats.longestStreak))
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                if let emoji = stats.topEmoji {
                    Spacer().frame(height: 16)
                    VStack(spacing: 8) {
                        Text("En çok kullandığın ifade")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                            .textCase(.uppercase)
                            .tracking(1)
                        Text(emoji)
                            .font(.system(size: 52))
                    }
                    .padding(16)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    // MARK: - Page 6: Personality

    private var personalityPage: some View {
        WrappedPageLayout {
            VStack(spacing: 20) {
                Text(stats.personalityEmoji)
                    .font(.system(size: 80))

                Text("Sen bir")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))

                Text(stats.personalityType)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("sin!")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer().frame(height: 16)

                // Final summary chips
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        summaryChip("\(stats.totalLogged)", sub: "İçerik")
                        if let avg = stats.averageRating {
                            summaryChip(String(format: "%.1f", avg), sub: "Ort. Puan")
                        }
                    }
                    HStack(spacing: 10) {
                        summaryChip("\(stats.longestStreak)g", sub: "Seri")
                        if let platform = stats.topPlatform {
                            summaryChip(platform.displayName, sub: "Platform")
                        }
                    }
                }

                Spacer().frame(height: 8)
                Text("Grippd ile takipte kal 🎬")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }

    // MARK: - Helpers

    private func countChip(icon: String, count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            Text("\(count)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private func typeBar(icon: String, label: String, count: Int, total: Int, color: Color) -> some View {
        let ratio = Double(count) / Double(max(total, 1))
        return HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(.white.opacity(0.5)).frame(width: 16)
            Text(label).font(.system(size: 13)).foregroundStyle(.white.opacity(0.7)).frame(width: 58, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.08)).frame(height: 8)
                    Capsule().fill(color.opacity(0.8)).frame(width: max(geo.size.width * ratio, 4), height: 8)
                }
            }
            .frame(height: 8)
            Text("\(count)").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.white).frame(width: 28, alignment: .trailing)
        }
    }

    private func summaryChip(_ value: String, sub: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(sub)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func ratingComment(_ avg: Double) -> String {
        switch avg {
        case 9...:  return "Çok seçici ya da çok şanslısın! 🌟"
        case 7.5...: return "Genellikle kaliteli şeyler izliyorsun"
        case 6...:  return "Dengeli bir izleyicisin"
        case 4...:  return "Pek memnun kalmıyorsun sanırım 😅"
        default:    return "Bir eleştirmen gibi bakıyorsun 🔍"
        }
    }

    private func streakComment(_ days: Int) -> String {
        switch days {
        case 30...: return "İnanılmaz! Neredeyse her gün logladın 🏆"
        case 14...: return "Harika bir alışkanlık oluşturdun!"
        case 7...:  return "Bir haftalık seri, hiç fena değil"
        case 3...:  return "İyi başlangıç, devam et!"
        default:    return "Seri rekoru kırmak için hazır mısın?"
        }
    }

    private func platformEmoji(_ platform: LogPlatform) -> String {
        switch platform {
        case .netflix:      return "🔴"
        case .disneyPlus:   return "🔵"
        case .amazonPrime:  return "🟡"
        case .hboMax:       return "🟣"
        case .appletv:      return "⬛"
        case .bluTV:        return "🔵"
        case .mubi:         return "🎨"
        case .cinema:       return "🎬"
        case .dvd:          return "💿"
        case .library:      return "🏛️"
        case .kindle:       return "📱"
        case .physicalBook: return "📖"
        case .other:        return "📺"
        }
    }
}

// MARK: - Page Layout

private struct WrappedPageLayout<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                content()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 32)
                Spacer(minLength: 60)
            }
            .frame(minHeight: UIScreen.main.bounds.height - 140)
        }
    }
}

// MARK: - Color Hex Extension

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
