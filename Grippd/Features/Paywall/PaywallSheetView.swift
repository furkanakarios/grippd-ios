import SwiftUI

/// Placeholder paywall sheet — Phase 6'da RevenueCat ile dolacak.
struct PaywallSheetView: View {
    @Environment(\.dismiss) private var dismiss

    private let features = [
        ("Sınırsız yorum", "bubble.left.and.bubble.right.fill"),
        ("Sınırsız liste", "list.bullet.rectangle.fill"),
        ("Detaylı istatistikler", "chart.bar.fill"),
        ("Öncelikli keşfet", "sparkles"),
        ("Custom içerik ekleme", "plus.circle.fill"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                GrippdBackground()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(GrippdTheme.Colors.accent)

                        Text("Grippd Premium")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Sınırları kaldır, deneyimini dönüştür.")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 36)

                    // Feature list
                    VStack(spacing: 16) {
                        ForEach(features, id: \.0) { feature in
                            HStack(spacing: 14) {
                                Image(systemName: feature.1)
                                    .font(.system(size: 18))
                                    .foregroundStyle(GrippdTheme.Colors.accent)
                                    .frame(width: 28)
                                Text(feature.0)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white.opacity(0.85))
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(GrippdTheme.Colors.accent)
                            }
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    // CTA
                    VStack(spacing: 12) {
                        Button {
                            // Phase 6'da RevenueCat purchase buraya
                            dismiss()
                        } label: {
                            Text("$9.99 / ay — Başla")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(GrippdTheme.Colors.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(GrippdTheme.Colors.accent, in: RoundedRectangle(cornerRadius: 14))
                        }

                        Button("Belki daha sonra") { dismiss() }
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
            .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
