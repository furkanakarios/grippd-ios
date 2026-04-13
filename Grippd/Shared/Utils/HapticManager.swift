import UIKit

enum HapticManager {

    // Hafif dokunuş — beğeni, küçük seçim değişiklikleri
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // Orta dokunuş — follow/unfollow, tab seçimi
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    // Güçlü dokunuş — log kaydetme, satın alma, önemli aksiyon
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    // Başarı bildirimi — kayıt tamamlandı, satın alma başarılı
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // Hata bildirimi — geçersiz form, limit aşıldı
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // Rating değişimi — her yarım yıldız adımında
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
