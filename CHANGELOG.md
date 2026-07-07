# Changelog

Grippd — Film, dizi ve kitap günlüğü. Tüm sürüm notları burada tutulur.

## [1.0.0] — İlk Sürüm (App Store)

İlk kamuya açık sürüm. Grippd; izlediğin filmleri, dizileri ve okuduğun kitapları
takip ettiğin sosyal bir günlük uygulamasıdır.

### Özellikler
- **İçerik günlüğü:** Film, dizi (sezon/bölüm bazında) ve kitap loglama; çoklu log
  (rewatch/reread) desteği.
- **Puanlama:** 0,5 adımlı 1–10 yıldız sistemi + emoji tepkileri; renk kodlu gösterim.
- **Sosyal:** Takip sistemi, Feed, beğeni, yorum, public/private profil.
- **Keşfet:** Haftalık trendler, küratörlenmiş listeler, kişiselleştirilmiş öneriler.
- **Listeler:** Watchlist, okuma listesi ve özel listeler.
- **İstatistikler:** Yıllık Wrapped, tür dağılımı, en aktif aylar.
- **Premium (Grippd Pro):** Gelişmiş filtreler, öncelikli öneriler, özel içerik ekleme,
  sınırsız liste/yorum.
- **İçerik kaynakları:** TMDB (film/dizi), Google Books + Open Library (kitap),
  TMDB Watch Providers (yayın platformu bilgisi).

### Altyapı & Güvenlik (Faz 9)
- Sunucu tarafı yetkilendirme sertleştirmesi: kullanıcı kendi hesabında ayrıcalık
  yükseltemez (is_admin/is_banned/plan_type kolon bazlı kilit).
- Abonelik durumu (plan_type) yalnızca RevenueCat webhook → Supabase Edge Function
  ile yetkili biçimde yazılır (istemci paywall bypass'ı kapatıldı).
- Sunucu tarafı input validation (kullanıcı adı formatı + metin uzunluk sınırları).
- Ağ dayanıklılığı: 20 sn istek timeout'u, anlaşılır Türkçe ağ hata mesajları,
  içerik detay ekranlarında "Tekrar Dene".
- Görsel cache (NSCache) ve feed sayfalama.
