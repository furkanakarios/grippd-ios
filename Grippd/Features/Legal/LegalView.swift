import SwiftUI

// MARK: - Legal Mode

enum LegalMode {
    case privacyPolicy
    case termsOfService

    var title: String {
        switch self {
        case .privacyPolicy:   return "Gizlilik Politikası"
        case .termsOfService:  return "Kullanım Koşulları"
        }
    }

    var lastUpdated: String { "13 Nisan 2025" }
}

// MARK: - LegalView

struct LegalView: View {
    let mode: LegalMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.10, green: 0.10, blue: 0.13).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Tarih
                        Text("Son güncelleme: \(mode.lastUpdated)")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.35))

                        // İçerik
                        switch mode {
                        case .privacyPolicy:   privacyContent
                        case .termsOfService:  termsContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .toolbarBackground(Color(red: 0.10, green: 0.10, blue: 0.13), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Privacy Policy

    private var privacyContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            legalSection(
                title: "1. Genel Bakış",
                body: "Grippd (\"biz\", \"uygulama\"), film, dizi ve kitap deneyimlerini kaydetmenizi ve arkadaşlarınızla paylaşmanızı sağlayan bir mobil uygulamadır. Bu Gizlilik Politikası, uygulamayı kullandığınızda hangi verileri topladığımızı, nasıl kullandığımızı ve nasıl koruduğumuzu açıklar."
            )
            legalSection(
                title: "2. Topladığımız Veriler",
                body: """
• Hesap bilgileri: Apple ID veya e-posta adresiniz (Supabase Auth üzerinden saklanır).
• Profil bilgileri: Kullanıcı adı, biyografi, profil fotoğrafı (opsiyonel).
• İçerik verileri: Logladığınız filmler, diziler, kitaplar; verdiğiniz puanlar, yazdığınız notlar ve yorumlar.
• Sosyal veriler: Takip ettiğiniz ve sizi takip eden kullanıcılar, beğeniler.
• Cihaz bilgileri: Uygulama hataları ve performans verileri (anonim).
"""
            )
            legalSection(
                title: "3. Verileri Nasıl Kullanırız",
                body: """
• Hesabınızı oluşturmak ve yönetmek.
• İçerik keşfi ve kişiselleştirilmiş öneriler sunmak.
• Sosyal özellikler (feed, takip sistemi, yorumlar) için.
• Uygulama performansını iyileştirmek.
• Premium abonelik işlemlerini gerçekleştirmek (RevenueCat/StoreKit 2).
"""
            )
            legalSection(
                title: "4. Veri Paylaşımı",
                body: "Kişisel verilerinizi üçüncü taraflarla satmıyoruz. Yalnızca hizmet altyapısı için gerekli üçüncü taraf sağlayıcılarla (Supabase, Apple, RevenueCat) paylaşım yapılır. Bu sağlayıcılar kendi gizlilik politikalarına tabidir."
            )
            legalSection(
                title: "5. Profil Gizliliği",
                body: "Profilinizi \"Gizli\" olarak ayarlarsanız loglarınız ve aktiviteleriniz yalnızca onaylı takipçilerinize görünür. Gizli profil ayarını uygulama Ayarlar bölümünden istediğiniz zaman değiştirebilirsiniz."
            )
            legalSection(
                title: "6. Veri Güvenliği",
                body: "Verileriniz Supabase altyapısında şifrelenerek saklanır. Satır Düzeyinde Güvenlik (Row Level Security) ile her kullanıcı yalnızca kendi verilerine erişebilir. SSL/TLS şifrelemesi tüm veri aktarımlarında kullanılır."
            )
            legalSection(
                title: "7. Verilerinizin Silinmesi",
                body: "Hesabınızı silmek için Ayarlar > Hesap bölümünden talepte bulunabilirsiniz. Hesap silme işlemi, profilinize ve loglarınıza ait tüm verilerin kalıcı olarak silinmesiyle sonuçlanır."
            )
            legalSection(
                title: "8. Çocukların Gizliliği",
                body: "Grippd 17 yaş ve üzeri kullanıcılara yöneliktir. 17 yaşın altındaki bireylerden bilerek kişisel veri toplamıyoruz."
            )
            legalSection(
                title: "9. İletişim",
                body: "Gizlilik politikamıza ilişkin sorularınız için: privacy@grippd.app"
            )
        }
    }

    // MARK: - Terms of Service

    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            legalSection(
                title: "1. Kabul",
                body: "Grippd uygulamasını kullanarak bu Kullanım Koşulları'nı kabul etmiş olursunuz. Koşulları kabul etmiyorsanız uygulamayı kullanmayınız."
            )
            legalSection(
                title: "2. Hesap",
                body: """
• Hesabınızın güvenliğinden siz sorumlusunuz.
• Doğru ve güncel bilgi sağlamayı kabul edersiniz.
• Tek kişiye bir hesap; hesap devredilemez.
• 17 yaşın altındaysanız ebeveyn/vasi onayı gereklidir.
"""
            )
            legalSection(
                title: "3. İzin Verilen Kullanım",
                body: """
Grippd'i şu amaçlarla kullanabilirsiniz:
• Film, dizi ve kitap deneyimlerini kişisel kullanım için loglamak.
• Diğer kullanıcıların içeriklerini keşfetmek ve takip etmek.
• Yorum yapmak ve beğenmek.
"""
            )
            legalSection(
                title: "4. Yasaklı İçerik",
                body: """
Aşağıdaki içerikleri paylaşmak kesinlikle yasaktır:
• Hakaret, nefret söylemi veya taciz içeren yorumlar.
• Başkalarının kişisel bilgilerini izinsiz paylaşmak.
• Spam, yanıltıcı veya otomatik üretilmiş içerik.
• Telif hakkı ihlali oluşturan materyaller.

İhlaller hesap askıya alma veya kalıcı kapatmayla sonuçlanabilir.
"""
            )
            legalSection(
                title: "5. Premium Abonelik",
                body: """
• Premium abonelik aylık $9.99 olarak faturalandırılır (fiyatlar bölgeye göre değişebilir).
• Abonelik, mevcut dönem bitmeden en az 24 saat önce iptal edilmezse otomatik yenilenir.
• Ücretsiz deneme süresi varsa, deneme bitmeden iptal edilmezse ücretli aboneliğe geçilir.
• İptal ve iade işlemleri App Store üzerinden yapılır; Apple'ın iade politikası geçerlidir.
"""
            )
            legalSection(
                title: "6. İçerik Hakları",
                body: "Uygulamaya yüklediğiniz içerikler (yorumlar, notlar, listeler) size aittir. Bize bu içerikleri uygulama kapsamında kullanma ve görüntüleme hakkını tanırsınız."
            )
            legalSection(
                title: "7. Hizmet Değişiklikleri",
                body: "Grippd hizmetini önceden bildirmeksizin değiştirme, kısıtlama veya sonlandırma hakkını saklı tutar. Önemli değişiklikler için uygulama içi bildirim veya e-posta ile duyuru yapılacaktır."
            )
            legalSection(
                title: "8. Sorumluluk Sınırlaması",
                body: "Grippd, uygulama üzerindeki kullanıcı içeriklerinden doğan zararlardan sorumlu tutulamaz. Hizmet \"olduğu gibi\" sunulmakta olup kesintisiz çalışma garanti edilmez."
            )
            legalSection(
                title: "9. İletişim",
                body: "Kullanım koşullarına ilişkin sorularınız için: legal@grippd.app"
            )
        }
    }

    // MARK: - Helper

    private func legalSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GrippdTheme.Colors.accent)

            Text(body)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }
}
