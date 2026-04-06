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
