import SwiftUI
import RevenueCat

struct PaywallSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var monthlyPackage: Package? = nil
    @State private var isLoadingOfferings = true
    @State private var isPurchasing = false
    @State private var errorMessage: String? = nil
    @State private var hasTrial = false
    @State private var trialDays = 7

    private let features: [(String, String)] = [
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
                    headerSection
                    featureList
                    Spacer()
                    ctaSection
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
        .task { await loadOfferings() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 52))
                .foregroundStyle(GrippdTheme.Colors.accent)

            Text("Grippd Premium")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if hasTrial {
                Text("\(trialDays) gün ücretsiz dene, beğenirsen devam et.")
                    .font(.system(size: 15))
                    .foregroundStyle(GrippdTheme.Colors.accent.opacity(0.9))
                    .multilineTextAlignment(.center)
            } else {
                Text("Sınırları kaldır, deneyimini dönüştür.")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 32)
        .padding(.bottom, 36)
        .padding(.horizontal, 24)
    }

    // MARK: - Feature List

    private var featureList: some View {
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
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 10) {
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button { Task { await purchase() } } label: {
                Group {
                    if isPurchasing || isLoadingOfferings {
                        ProgressView().tint(GrippdTheme.Colors.background)
                    } else if hasTrial {
                        VStack(spacing: 2) {
                            Text("\(trialDays) Gün Ücretsiz Dene")
                                .font(.system(size: 16, weight: .bold))
                            Text("Sonra \(priceString) / ay")
                                .font(.system(size: 12))
                                .opacity(0.7)
                        }
                        .foregroundStyle(GrippdTheme.Colors.background)
                    } else {
                        Text("\(priceString) / ay — Başla")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(GrippdTheme.Colors.background)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(GrippdTheme.Colors.accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isPurchasing || isLoadingOfferings)
            .padding(.horizontal, 24)

            if hasTrial {
                Text("Deneme süresi bitmeden iptal edebilirsin.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))
            }

            Button("Belki daha sonra") { dismiss() }
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.bottom, 32)
    }

    // MARK: - Helpers

    private var priceString: String {
        monthlyPackage?.storeProduct.localizedPriceString ?? "$9.99"
    }

    // MARK: - Actions

    private func loadOfferings() async {
        isLoadingOfferings = true
        do {
            let offerings = try await PurchaseService.shared.fetchOfferings()
            if let pkg = offerings.current?.monthly {
                monthlyPackage = pkg
                // Trial bilgisini kontrol et
                if let intro = pkg.storeProduct.introductoryDiscount,
                   intro.paymentMode == .freeTrial {
                    hasTrial = true
                    trialDays = intro.subscriptionPeriod.value
                }
            }
        } catch {
            // Offerings yüklenemezse sessizce devam et, fiyat fallback gösterir
        }
        isLoadingOfferings = false
    }

    private func purchase() async {
        guard let pkg = monthlyPackage else {
            // Paket yoksa App Store'a yönlendir
            appState.showPaywall = false
            dismiss()
            return
        }
        isPurchasing = true
        errorMessage = nil
        do {
            let success = try await PurchaseService.shared.purchase(package: pkg)
            if success {
                let premium = await PurchaseService.shared.isPremium()
                await MainActor.run {
                    appState.isPremium = premium
                }
                dismiss()
            }
        } catch {
            errorMessage = "Satın alma işlemi başarısız. Tekrar deneyin."
        }
        isPurchasing = false
    }
}
