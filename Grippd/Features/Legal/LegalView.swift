import SwiftUI

// MARK: - Legal Mode

enum LegalMode {
    case privacyPolicy
    case termsOfService
    case kvkk

    var title: String {
        switch self {
        case .privacyPolicy:  return "Gizlilik Politikası"
        case .termsOfService: return "Kullanım Koşulları"
        case .kvkk:           return "KVKK Aydınlatma Metni"
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

                        switch mode {
                        case .privacyPolicy:  privacyContent
                        case .termsOfService: termsContent
                        case .kvkk:           kvkkContent
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
                title: "1. Veri Sorumlusu",
                body: "Bu Gizlilik Politikası, Grippd uygulaması (\"biz\", \"uygulama\") tarafından hazırlanmıştır. Veri sorumlusu sıfatıyla kişisel verilerinizi 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) ve ilgili mevzuat çerçevesinde işlemekteyiz.\n\nİletişim: privacy@grippd.app"
            )
            legalSection(
                title: "2. Topladığımız Veriler",
                body: """
Kimlik ve iletişim verileri:
• Apple ID veya e-posta adresiniz (kimlik doğrulama için)
• Kullanıcı adı ve opsiyonel profil fotoğrafınız

İçerik ve aktivite verileri:
• Logladığınız filmler, diziler ve kitaplar
• Verdiğiniz puanlar, emoji reaksiyonlar ve notlar
• Yazdığınız yorumlar ve beğenileriniz
• Oluşturduğunuz listeler ve watchlist içerikleri

Sosyal veriler:
• Takip ettiğiniz ve sizi takip eden kullanıcılar

Abonelik verileri:
• Premium abonelik durumu (RevenueCat/Apple tarafından işlenir; kart bilgileri tarafımızca saklanmaz)

Teknik veriler:
• Uygulama sürümü ve cihaz türü (yalnızca hata tespiti için, anonim)
"""
            )
            legalSection(
                title: "3. Verilerin İşlenme Amaçları",
                body: """
• Hesabınızı oluşturmak, yönetmek ve kimliğinizi doğrulamak
• Film, dizi ve kitap loglarınızı kaydetmek ve listelemek
• Sosyal özellikler (feed, takip sistemi, yorumlar, beğeniler) sunmak
• Kişiselleştirilmiş içerik önerileri oluşturmak
• Premium abonelik işlemlerini gerçekleştirmek
• Uygulama performansını ve güvenliğini sağlamak
"""
            )
            legalSection(
                title: "4. Verilerin Paylaşımı",
                body: """
Kişisel verilerinizi üçüncü taraflara satmıyoruz. Yalnızca aşağıdaki hizmet sağlayıcılarla, belirtilen amaçlarla paylaşım yapılır:

• Supabase: Veritabanı ve kimlik doğrulama altyapısı (AB sunucuları)
• Apple / StoreKit 2: Abonelik ve ödeme işlemleri
• RevenueCat: Abonelik yönetimi ve doğrulama
• TMDB / Google Books: İçerik bilgisi sorgulaması (kişisel veri aktarılmaz, yalnızca arama sorguları)

Tüm altyapı sağlayıcıları kendi gizlilik politikalarına ve geçerli veri koruma mevzuatına tabidir.
"""
            )
            legalSection(
                title: "5. Profil Gizliliği",
                body: "Profilinizi \"Gizli\" olarak ayarlarsanız loglarınız ve aktiviteleriniz yalnızca onaylı takipçilerinize görünür. Bu ayarı istediğiniz zaman Ayarlar > Gizlilik bölümünden değiştirebilirsiniz."
            )
            legalSection(
                title: "6. Veri Güvenliği",
                body: """
• Tüm veriler Supabase altyapısında AES-256 şifrelemesiyle saklanır
• Satır Düzeyinde Güvenlik (Row Level Security) ile her kullanıcı yalnızca kendi verilerine erişebilir
• Tüm veri aktarımları SSL/TLS şifrelemesiyle korunur
• Şifreler hiçbir zaman düz metin olarak saklanmaz
"""
            )
            legalSection(
                title: "7. Veri Saklama Süresi",
                body: "Kişisel verileriniz hesabınız aktif olduğu sürece saklanır. Hesabınızı silmeniz halinde tüm kişisel verileriniz 30 gün içinde kalıcı olarak imha edilir. Abonelik kayıtları, Apple/RevenueCat'in politikası gereği yasal saklama süresi boyunca tutulabilir."
            )
            legalSection(
                title: "8. Çerez ve Takip",
                body: "Grippd mobil uygulaması çerez kullanmaz, reklam verisi toplamaz ve çapraz uygulama takibi yapmaz. App Tracking Transparency (ATT) izni talep edilmez."
            )
            legalSection(
                title: "9. Haklarınız",
                body: """
KVKK ve GDPR kapsamında aşağıdaki haklara sahipsiniz:
• Kişisel verilerinize erişim talep etme
• Yanlış verilerin düzeltilmesini isteme
• Verilerinizin silinmesini talep etme
• İşlemenin kısıtlanmasını talep etme
• Veri taşınabilirliği hakkı
• İşlemeye itiraz hakkı

Talepler için: privacy@grippd.app — 30 gün içinde yanıt verilir.
"""
            )
            legalSection(
                title: "10. Çocukların Gizliliği",
                body: "Grippd 17 yaş ve üzeri kullanıcılara yöneliktir. 17 yaşın altındaki bireylerden bilerek kişisel veri toplamıyoruz. Böyle bir durumun farkına varırsak ilgili verileri derhal sileriz."
            )
            legalSection(
                title: "11. Politika Değişiklikleri",
                body: "Bu politikada yapılacak önemli değişiklikler için uygulama içi bildirim veya e-posta ile önceden bilgilendirme yapılacaktır. Güncel politika her zaman bu sayfada yayınlanır."
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
• Film, dizi ve kitap deneyimlerini kişisel kullanım için loglamak
• Diğer kullanıcıların içeriklerini keşfetmek ve takip etmek
• Yorum yapmak ve beğenmek
"""
            )
            legalSection(
                title: "4. Yasaklı İçerik",
                body: """
Aşağıdaki içerikleri paylaşmak kesinlikle yasaktır:
• Hakaret, nefret söylemi veya taciz içeren yorumlar
• Başkalarının kişisel bilgilerini izinsiz paylaşmak
• Spam, yanıltıcı veya otomatik üretilmiş içerik
• Telif hakkı ihlali oluşturan materyaller

İhlaller hesap askıya alma veya kalıcı kapatmayla sonuçlanabilir.
"""
            )
            legalSection(
                title: "5. Premium Abonelik",
                body: """
• Premium abonelik aylık olarak faturalandırılır (fiyatlar App Store'da gösterilir).
• Abonelik, mevcut dönem bitmeden en az 24 saat önce iptal edilmezse otomatik yenilenir.
• Ücretsiz deneme süresi varsa, deneme bitmeden iptal edilmezse ücretli aboneliğe geçilir.
• İptal ve iade işlemleri App Store üzerinden yapılır; Apple'ın iade politikası geçerlidir.
"""
            )
            legalSection(
                title: "6. İçerik Hakları",
                body: "Uygulamaya yüklediğiniz içerikler (yorumlar, notlar, listeler) size aittir. Bize bu içerikleri uygulama kapsamında kullanma ve görüntüleme hakkını tanırsınız. İçerik API'lerinden (TMDB, Google Books) gelen veriler ilgili platformların kullanım koşullarına tabidir."
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
                title: "9. Uygulanacak Hukuk",
                body: "Bu koşullar Türkiye Cumhuriyeti kanunlarına tabidir. Uyuşmazlıklarda İstanbul mahkemeleri ve icra daireleri yetkilidir."
            )
            legalSection(
                title: "10. İletişim",
                body: "Kullanım koşullarına ilişkin sorularınız için: legal@grippd.app"
            )
        }
    }

    // MARK: - KVKK

    private var kvkkContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Giriş kartı
            VStack(alignment: .leading, spacing: 8) {
                Text("6698 Sayılı Kişisel Verilerin Korunması Kanunu kapsamında hazırlanmış aydınlatma metnidir.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineSpacing(4)

                HStack(spacing: 16) {
                    kvkkInfoItem(label: "Veri Sorumlusu", value: "Furkan Akarıos")
                    kvkkInfoItem(label: "İletişim", value: "privacy@grippd.app")
                }
                .padding(.top, 4)
            }
            .padding(14)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))

            legalSection(
                title: "1. İşlenen Kişisel Veri Kategorileri",
                body: """
Kimlik Verileri:
• Ad, soyad (opsiyonel — Apple Gizle özelliği kullanılabilir)
• Kullanıcı adı

İletişim Verileri:
• E-posta adresi (hesap doğrulama ve bildirimlerde)

Müşteri İşlem Verileri:
• Abonelik durumu, abonelik başlangıç/bitiş tarihleri

Görsel Veriler:
• Profil fotoğrafı (opsiyonel, kullanıcı tarafından yüklenir)

Dijital İz Verileri:
• Uygulama sürümü, son aktif olma zamanı (anonim hata tespiti)

İçerik Verileri:
• Loglar (izlenen/okunan içerikler), puanlar, yorumlar, notlar, listeler
• Takip ilişkileri, beğeniler (sosyal aktiviteler)
"""
            )
            legalSection(
                title: "2. Kişisel Verilerin İşlenme Amaçları",
                body: """
• Kimlik doğrulama ve hesap yönetimi (sözleşmenin ifası)
• Film, dizi ve kitap log hizmeti sunulması (sözleşmenin ifası)
• Sosyal özellikler (feed, takip, yorum) sağlanması (sözleşmenin ifası)
• Kişiselleştirilmiş içerik önerileri (meşru menfaat)
• Premium abonelik yönetimi (sözleşmenin ifası)
• Uygulama güvenliği ve performansının sağlanması (meşru menfaat)
• Yasal yükümlülüklerin yerine getirilmesi (kanuni zorunluluk)
"""
            )
            legalSection(
                title: "3. Kişisel Verilerin İşlenme Hukuki Sebepleri",
                body: """
KVKK md. 5 kapsamında aşağıdaki hukuki sebeplere dayanılmaktadır:

• Sözleşmenin kurulması veya ifası (md. 5/2-c)
• Veri sorumlusunun meşru menfaatleri (md. 5/2-f)
• Açık rıza (opsiyonel özellikler ve pazarlama iletişimi için)
• Kanunlarda açıkça öngörülmesi (md. 5/2-a)
"""
            )
            legalSection(
                title: "4. Kişisel Verilerin Aktarıldığı Taraflar",
                body: """
Yurt İçi Aktarım: Yapılmamaktadır.

Yurt Dışı Aktarım:
• Supabase Inc. (ABD) — Veritabanı ve kimlik doğrulama altyapısı; AB Standart Sözleşme Maddeleri kapsamında
• Apple Inc. (ABD) — Kimlik doğrulama (Sign in with Apple) ve ödeme altyapısı
• RevenueCat Inc. (ABD) — Abonelik yönetimi; yalnızca abonelik durum verisi

İçerik sorgulaması amacıyla TMDB ve Google Books API'lerine yalnızca anonim arama sorguları iletilmekte; kişisel veri aktarılmamaktadır.
"""
            )
            legalSection(
                title: "5. Kişisel Verilerin Saklanma Süresi",
                body: """
• Hesap verileri: Hesap aktif olduğu süre boyunca
• Log ve içerik verileri: Hesap aktif olduğu süre boyunca
• Abonelik kayıtları: Apple/RevenueCat'in politikası ve yasal yükümlülükler gereği azami 10 yıl
• Anonim teknik veriler: 12 ay

Hesabın silinmesi halinde kişisel veriler 30 gün içinde kalıcı olarak imha edilir.
"""
            )
            legalSection(
                title: "6. Kişisel Veri Sahibinin Hakları",
                body: """
KVKK'nın 11. maddesi uyarınca aşağıdaki haklara sahipsiniz:

a) Kişisel verilerinizin işlenip işlenmediğini öğrenme
b) İşlenmişse buna ilişkin bilgi talep etme
c) İşlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme
d) Yurt içinde veya yurt dışında aktarıldığı üçüncü kişileri bilme
e) Eksik veya yanlış işlenmiş verilerin düzeltilmesini isteme
f) KVKK md. 7 çerçevesinde silinmesini veya yok edilmesini isteme
g) (e) ve (f) kapsamındaki işlemlerin aktarılan üçüncü kişilere bildirilmesini isteme
h) İşlenen verilerin münhasıran otomatik sistemler vasıtasıyla analiz edilmesi suretiyle aleyhinize bir sonucun ortaya çıkmasına itiraz etme
i) Kanuna aykırı işleme sebebiyle zarara uğramanız halinde zararın giderilmesini talep etme
"""
            )
            legalSection(
                title: "7. Hakların Kullanılması",
                body: """
Yukarıdaki haklarınızı kullanmak için:

E-posta: privacy@grippd.app
Konu: KVKK Hak Kullanım Talebi

Talepler kimlik doğrulaması yapıldıktan sonra en geç 30 gün içinde yanıtlanır. Talebin niteliğine göre ücretsiz yanıt verilir; ancak işlemin ayrıca bir maliyet gerektirmesi halinde Kişisel Verileri Koruma Kurulu tarafından belirlenen tarifedeki ücret alınabilir.

Başvurunuzun reddedilmesi veya yetersiz yanıt verilmesi durumunda Kişisel Verileri Koruma Kurulu'na (kvkk.gov.tr) şikayette bulunabilirsiniz.
"""
            )
            legalSection(
                title: "8. Güvenlik Önlemleri",
                body: """
• Supabase altyapısında AES-256 veri şifrelemesi
• Tüm iletişimlerde TLS 1.3 şifrelemesi
• Satır Düzeyinde Güvenlik (RLS) ile kullanıcı verisi izolasyonu
• Şifre bilgisi hiçbir zaman düz metin olarak saklanmaz
• Düzenli güvenlik denetimleri
"""
            )
        }
    }

    // MARK: - Helpers

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

    private func kvkkInfoItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
                .textCase(.uppercase)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}
