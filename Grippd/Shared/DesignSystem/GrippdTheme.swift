import SwiftUI

enum GrippdTheme {

    // MARK: - Colors
    enum Colors {
        /// Ana arka plan — near-black, hafif cool ton
        static let background = Color(red: 0.05, green: 0.05, blue: 0.07)
        /// İkincil yüzey
        static let surface = Color(red: 0.10, green: 0.10, blue: 0.13)
        /// Warm gold accent — sinematik
        static let accent = Color(red: 0.91, green: 0.70, blue: 0.29)
        /// Accent'in soluk versiyonu
        static let accentMuted = Color(red: 0.91, green: 0.70, blue: 0.29).opacity(0.15)
        /// Gradient top rengi — hafif mor tint
        static let gradientTop = Color(red: 0.08, green: 0.06, blue: 0.12)
        /// Gradient bottom
        static let gradientBottom = Color(red: 0.03, green: 0.03, blue: 0.05)
    }

    // MARK: - Gradients
    enum Gradients {
        static let background = LinearGradient(
            colors: [Colors.gradientTop, Colors.gradientBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        static let accentGlow = RadialGradient(
            colors: [Colors.accent.opacity(0.12), .clear],
            center: .top,
            startRadius: 0,
            endRadius: 400
        )
    }

    // MARK: - Typography
    enum Typography {
        static let appName = Font.system(size: 44, weight: .black, design: .rounded)
        static let headline = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let caption = Font.system(size: 13, weight: .regular, design: .default)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let pill: CGFloat = 100
    }
}
