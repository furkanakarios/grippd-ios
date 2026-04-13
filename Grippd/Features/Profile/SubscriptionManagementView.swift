import SwiftUI
import RevenueCat

struct SubscriptionManagementView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var renewalDate: Date? = nil
    @State private var isLoadingInfo = true
    @State private var isRestoring = false
    @State private var restoreMessage: String? = nil
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            GrippdBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if appState.isPremium {
                        premiumCard
                        manageSection
                    } else {
                        freeCard
                        upgradeSection
                    }
                    restoreSection
                }
                .padding(.horizontal, GrippdTheme.Spacing.md)
                .padding(.top, 20)
                .padding(.bottom, GrippdTheme.Spacing.xxl)
            }
        }
        .navigationTitle("Abonelik")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(GrippdTheme.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadSubscriptionInfo() }
        .sheet(isPresented: $showPaywall) {
            PaywallSheetView()
        }
    }

    // MARK: - Premium Card

    private var premiumCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(GrippdTheme.Colors.accent.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Grippd Premium")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Aktif abonelik")
                        .font(.system(size: 13))
                        .foregroundStyle(GrippdTheme.Colors.accent)
                }
                Spacer()
            }

            Divider().background(.white.opacity(0.08))

            if isLoadingInfo {
                HStack {
                    ProgressView().tint(GrippdTheme.Colors.accent).scaleEffect(0.8)
                    Text("Plan detayları yükleniyor...")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let date = renewalDate {
                infoRow(label: "Yenileme tarihi", value: date.formatted(.dateTime.day().month(.wide).year()))
            } else {
                infoRow(label: "Plan", value: "Aylık · $9.99")
            }
        }
        .padding(GrippdTheme.Spacing.md)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Free Card

    private var freeCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.07))
                        .frame(width: 52, height: 52)
                    Image(systemName: "person.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ücretsiz Plan")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Sınırlı özellikler")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
            }

            Divider().background(.white.opacity(0.08))

            VStack(spacing: 8) {
                limitRow(label: "Liste", value: "\(PremiumGate.maxFreeLists) liste")
                limitRow(label: "Yorum", value: "Ayda \(PremiumGate.maxFreeCommentsPerMonth) yorum")
                limitRow(label: "Custom içerik", value: "Kilitli")
            }
        }
        .padding(GrippdTheme.Spacing.md)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Manage Section (Premium)

    private var manageSection: some View {
        VStack(spacing: 0) {
            actionButton(
                icon: "gear",
                title: "Aboneliği Yönet",
                subtitle: "App Store'da iptal veya değiştir",
                color: GrippdTheme.Colors.accent
            ) {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }
        }
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Upgrade Section (Free)

    private var upgradeSection: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16))
                Text("Premium'a Geç")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(GrippdTheme.Colors.background)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(GrippdTheme.Colors.accent, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Restore Section

    private var restoreSection: some View {
        VStack(spacing: 0) {
            actionButton(
                icon: "arrow.clockwise",
                title: "Satın Alımları Geri Yükle",
                subtitle: isRestoring ? "Yükleniyor..." : "Daha önce Premium aldıysanız",
                color: .white.opacity(0.6)
            ) {
                Task { await restorePurchases() }
            }
            .disabled(isRestoring)

            if let message = restoreMessage {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(message.contains("başarı") ? GrippdTheme.Colors.accent : .red.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, GrippdTheme.Spacing.md)
                    .padding(.bottom, 12)
            }
        }
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Components

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    private func limitRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.45))
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func actionButton(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.2))
            }
            .padding(.horizontal, GrippdTheme.Spacing.md)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func loadSubscriptionInfo() async {
        isLoadingInfo = true
        if let info = try? await Purchases.shared.customerInfo(),
           let expiration = info.entitlements[GrippdProduct.entitlement]?.expirationDate {
            renewalDate = expiration
        }
        isLoadingInfo = false
    }

    private func restorePurchases() async {
        isRestoring = true
        restoreMessage = nil
        do {
            try await PurchaseService.shared.restorePurchases()
            let premium = await PurchaseService.shared.isPremium()
            await MainActor.run { appState.isPremium = premium }
            restoreMessage = premium ? "Satın alım başarıyla geri yüklendi." : "Geri yüklenecek aktif abonelik bulunamadı."
        } catch {
            restoreMessage = "Geri yükleme başarısız oldu. Tekrar deneyin."
        }
        isRestoring = false
    }
}
