import SwiftUI

// MARK: - StarRatingView
/// 0–10 puan, 0.5 adımlı, 5 yıldız üzerinde gösterim.
/// Dokunma + sürükleme ile interaktif, silme desteği (uzun basma veya tekrar tap).

struct StarRatingView: View {
    @Binding var rating: Double?   // nil = puanlanmadı
    var starSize: CGFloat = 36
    var spacing: CGFloat = 6
    var readOnly: Bool = false

    @State private var dragRating: Double? = nil
    @State private var bounceID: Int? = nil   // animasyon tetikleyici

    private let starCount = 5

    // Gösterilecek değer: sürükleme sırasında dragRating, yoksa rating, yoksa 0
    private var displayRating: Double { dragRating ?? rating ?? 0 }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: spacing) {
                ForEach(1...starCount, id: \.self) { index in
                    starView(for: index)
                        .symbolEffect(.bounce, value: bounceID == index)
                }
            }
            .gesture(readOnly ? nil : dragGesture)
            .simultaneousGesture(readOnly ? nil : tapGesture)

            ratingLabel
        }
    }

    // MARK: - Star Shape

    @ViewBuilder
    private func starView(for index: Int) -> some View {
        let full  = displayRating >= Double(index) * 2
        let half  = !full && displayRating >= Double(index) * 2 - 1

        ZStack {
            // Boş yıldız (arka plan)
            Image(systemName: "star")
                .font(.system(size: starSize, weight: .regular))
                .foregroundStyle(.white.opacity(0.15))

            // Dolu ya da yarım yıldız
            if full {
                Image(systemName: "star.fill")
                    .font(.system(size: starSize, weight: .regular))
                    .foregroundStyle(starColor(for: displayRating))
                    .transition(.scale.combined(with: .opacity))
            } else if half {
                Image(systemName: "star.leadinghalf.filled")
                    .font(.system(size: starSize, weight: .regular))
                    .foregroundStyle(starColor(for: displayRating))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: starSize, height: starSize)
    }

    // MARK: - Rating Label

    private var ratingLabel: some View {
        Group {
            if let r = dragRating ?? rating {
                Text(String(format: r == Double(Int(r)) ? "%.0f / 10" : "%.1f / 10", r))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: r))
            } else {
                Text("Puan ver")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .animation(.spring(response: 0.2), value: dragRating ?? rating ?? -1)
    }

    // MARK: - Color

    private func starColor(for value: Double) -> Color {
        switch value {
        case ..<4:  return Color(red: 0.95, green: 0.35, blue: 0.35)   // kırmızı
        case ..<6:  return Color(red: 1.00, green: 0.65, blue: 0.20)   // turuncu
        case ..<8:  return Color(red: 1.00, green: 0.85, blue: 0.20)   // sarı
        default:    return Color(red: 0.30, green: 0.85, blue: 0.45)   // yeşil
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let newRating = ratingFrom(x: value.location.x)
                if newRating != dragRating {
                    HapticManager.selection()
                }
                withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                    dragRating = newRating
                }
            }
            .onEnded { value in
                let newRating = ratingFrom(x: value.location.x)
                commit(newRating)
            }
    }

    private var tapGesture: some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                let newRating = ratingFrom(x: value.location.x)
                commit(newRating)
            }
    }

    // MARK: - Helpers

    private func ratingFrom(x: CGFloat) -> Double {
        let totalWidth = CGFloat(starCount) * starSize + CGFloat(starCount - 1) * spacing
        let clamped = max(0, min(x, totalWidth))
        let starWidth = starSize + spacing
        let raw = (clamped / totalWidth) * 10
        // 0.5 adımlara yuvarlama
        let rounded = (raw * 2).rounded() / 2
        return max(0.5, min(10.0, rounded))
    }

    private func commit(_ newRating: Double) {
        HapticManager.selection()
        let starIndex = Int(ceil(newRating / 2))
        withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
            // Aynı puana tekrar basınca sıfırla
            if rating == newRating {
                rating = nil
                dragRating = nil
            } else {
                rating = newRating
                dragRating = nil
                bounceID = starIndex
            }
        }
        // Bounce sıfırla
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            bounceID = nil
        }
    }
}

// MARK: - Compact Read-Only Version (log listeleri için)

struct StarRatingBadge: View {
    let rating: Double
    var fontSize: CGFloat = 13

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: fontSize - 2, weight: .semibold))
                .foregroundStyle(badgeColor)
            Text(String(format: rating == Double(Int(rating)) ? "%.0f" : "%.1f", rating))
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(red: 0.10, green: 0.10, blue: 0.13))
                .overlay(Capsule().stroke(badgeColor.opacity(0.6), lineWidth: 1))
        )
    }

    static func ratingColor(_ rating: Double) -> Color {
        switch rating {
        case ..<4:  return Color(red: 0.95, green: 0.35, blue: 0.35)
        case ..<6:  return Color(red: 1.00, green: 0.65, blue: 0.20)
        case ..<8:  return Color(red: 1.00, green: 0.85, blue: 0.20)
        default:    return Color(red: 0.30, green: 0.85, blue: 0.45)
        }
    }

    private var badgeColor: Color { Self.ratingColor(rating) }
}

// MARK: - LogBadge (emoji + rating birleşik)

struct LogBadge: View {
    var emoji: String?
    var rating: Double?
    var fontSize: CGFloat = 12

    var body: some View {
        HStack(spacing: 4) {
            if let emoji {
                Text(emoji)
                    .font(.system(size: fontSize + 1))
            }
            if let rating {
                if emoji != nil {
                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 1, height: 12)
                }
                Image(systemName: "star.fill")
                    .font(.system(size: fontSize - 2, weight: .semibold))
                    .foregroundStyle(StarRatingBadge.ratingColor(rating))
                Text(String(format: rating == Double(Int(rating)) ? "%.0f" : "%.1f", rating))
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(red: 0.10, green: 0.10, blue: 0.13))
                .overlay(
                    Capsule().stroke(
                        rating != nil
                            ? StarRatingBadge.ratingColor(rating!).opacity(0.6)
                            : Color.white.opacity(0.2),
                        lineWidth: 1
                    )
                )
        )
    }
}
