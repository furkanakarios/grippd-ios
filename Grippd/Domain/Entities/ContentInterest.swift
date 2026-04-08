import Foundation

enum ContentInterest: String, CaseIterable, Identifiable {
    // Film/Dizi türleri
    case action = "Aksiyon"
    case comedy = "Komedi"
    case drama = "Drama"
    case sciFi = "Bilim Kurgu"
    case horror = "Korku"
    case thriller = "Gerilim"
    case romance = "Romantik"
    case documentary = "Belgesel"
    case animation = "Animasyon"
    case fantasy = "Fantastik"
    // Kitap türleri
    case fiction = "Kurgu"
    case nonFiction = "Non-fiction"
    case mystery = "Gizem"
    case biography = "Biyografi"
    case history = "Tarih"
    case selfHelp = "Kişisel Gelişim"

    var id: String { rawValue }

    /// TMDB genre ID'leri (film/dizi için). Kitap türleri nil döner.
    var tmdbGenreIDs: [Int]? {
        switch self {
        case .action:      return [28]
        case .comedy:      return [35]
        case .drama:       return [18]
        case .sciFi:       return [878]
        case .horror:      return [27]
        case .thriller:    return [53]
        case .romance:     return [10749]
        case .documentary: return [99]
        case .animation:   return [16]
        case .fantasy:     return [14]
        case .fiction, .nonFiction, .mystery, .biography, .history, .selfHelp:
            return nil
        }
    }

    var isBookInterest: Bool { tmdbGenreIDs == nil }

    var emoji: String {
        switch self {
        case .action: "💥"
        case .comedy: "😂"
        case .drama: "🎭"
        case .sciFi: "🚀"
        case .horror: "👻"
        case .thriller: "🔪"
        case .romance: "❤️"
        case .documentary: "🎞️"
        case .animation: "✨"
        case .fantasy: "🧙"
        case .fiction: "📖"
        case .nonFiction: "📰"
        case .mystery: "🔍"
        case .biography: "👤"
        case .history: "🏛️"
        case .selfHelp: "🌱"
        }
    }
}
