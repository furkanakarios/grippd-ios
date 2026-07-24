# Faz 9 — Bugfix, Security & Final QA

**Durum:** 🟡 Devam Ediyor  
**Branch base:** `develop`

---

## Amaç

TestFlight test döneminde (Phase 7 Step 8) ve Phase 8 sürecinde biriken tüm sorunları
temizleyip uygulamayı App Store'a hazır hale getirmek.

---

## Adımlar

- [x] **Step 1** — Log kaybı bugfix: oturum açıldığında Supabase'den log pull, clearOwner tutarlılığı  
  Branch: `feature/phase-9-step-1-crash-fixes`

- [x] **Step 2** ✅ — Güvenlik denetimi: RLS politikaları, API key güvenliği, input validation  
  Branch: `feature/phase-9-step-2-security-audit` · Migration: `supabase/migrations/004_security_audit_phase9.sql`
  Bulgular & düzeltmeler:
  - **(KRİTİK, düzeltildi)** Ayrıcalık yükseltme: kullanıcı kendi `users` satırında `is_admin`/`is_banned`/`plan_type`/comment sayaçlarını yazabiliyordu (canlı ortamda ispatlandı). Kolon bazlı UPDATE kilidi eklendi; admin ban `admin_set_banned` SECURITY DEFINER RPC'sine taşındı.
  - **(düzeltildi)** Input validation: metin alanları sınırsızdı → username format + uzunluk CHECK kısıtları (bio 500, comment 2000, review 5000, list adı 100/desc 500, notes 2000).
  - **(düzeltildi)** notifications tablosuna istemciden serbest INSERT (`WITH CHECK true`) kaldırıldı; yinelenen politikalar sadeleştirildi.
  - **(düzeltildi)** Paywall bypass: `plan_type` artık istemciden yazılamıyor (kolon yetkisi kaldırıldı, canlı doğrulandı). Kaynak otorite RevenueCat webhook → Edge Function `revenuecat-webhook` (service_role ile yazar). Admin plan değişimi `admin_set_plan` RPC'sine taşındı. Migration: `005_plan_type_server_authority.sql`. **Kalan tek manuel adım:** RevenueCat dashboard'da webhook URL + Authorization secret ayarı (bkz. Alınan Kararlar).
  - **(düşük)** TMDB API anahtarı bundle-restricted değil (binary'den çıkarılabilir); Google Books zaten `com.grippd.app` ile kısıtlı. Supabase anon key RLS ile korunuyor.
  - **(not)** Şema drift: yerel `migrations/` (001-003) canlı şemanın çok gerisinde; canlı şema dashboard'dan büyümüş.

- [x] **Step 3** ✅ — Edge case düzeltmeleri: boş state'ler, network hataları, timeout handling  
  Branch: `feature/phase-9-step-3-edge-cases`
  - Network timeout: 4 client (TMDB, Google Books, Open Library, Supabase) `URLSessionConfiguration.default` (60sn) kullanıyordu → `timeoutIntervalForRequest = 20` eklendi.
  - `NetworkError` yardımcısı: URLError kodlarını anlaşılır Türkçe mesaja çevirir (offline/timeout/host); 3 içerik client'ına bağlandı.
  - `GrippdErrorStateView` (ikon + mesaj + "Tekrar Dene"): 5 detay ekranına (film/dizi/sezon/bölüm/kitap) retry eklendi — eskiden hata ekranında retry yoktu, kullanıcı çıkıp girmek zorundaydı.
  - Yeni dosya `NetworkError.swift` Sources build phase'ine eklendi (pbxproj).

- [x] **Step 4** ✅ — UI regresyon testi: tüm ekranlar gözden geçirilir, tutarsızlıklar giderilir  
  Branch: `feature/phase-9-step-4-ui-regression`
  - Tasarım sistemi tutarlılığı: 5 içerik detay ekranı (film/dizi/sezon/bölüm/kitap) ad-hoc loading VStack'i yerine `GrippdLoadingView` kullanacak şekilde standartlaştırıldı (Step 3'te error state'leri standartlaşmıştı; loading de eşitlendi).
  - CuratedListDetailView: ad-hoc `ProgressView` → `GrippdLoadingView`, Apple `ContentUnavailableView` → `GrippdEmptyStateView` (uygulama görsel diline uyduruldu).
  - **Bilinen kalan (düşük öncelik, kozmetik):** Bazı ekranlarda hâlâ ad-hoc empty-state `Text` var (Search, Feed, Notifications, AddToListSheet, LogCommentsView, CustomContentDetail). Bunlar scroll içi inline olabildiğinden `GrippdEmptyStateView`'a körü körüne çevirmek layout kaydırabilir; cihaz görsel testinde her biri tek tek değerlendirilecek.

- [x] **Step 5** ✅ (kod incelemesi) — Final performans geçişi: Instruments son kontrol, büyük listeler stress test  
  Branch: `feature/phase-9-step-5-final-performance`
  - **İyi:** Feed hem LazyVStack (sanallaştırma) hem `.range()` pagination; öneriler/keşfet `.limit()` ile sınırlı; görseller `CachedAsyncImage` (NSCache) ile cache'li.
  - **Ölçeklenme riski (bilinçli ertelendi — pre-launch küçük ölçek, regresyon riski):**
    1. `SocialService.fetchFollowers`/`fetchFollowing` limitsiz — tüm takipçi/takip listesini tek çekiyor. Popüler hesapta yavaşlar; çözüm infinite scroll. Launch sonrası kullanıcı büyüyünce ele alınacak.
    2. `LogSyncService.fetchAllFromRemote` limitsiz — girişte kullanıcının tüm loglarını yerel mirror'a çekiyor (local-first tasarım). Çok aktif kullanıcıda giriş yavaşlar. Mimari; büyük iş.
  - **Kullanıcı aksiyonu bekliyor:** Instruments ile CPU/memory profiling + büyük listelerde gerçek stress testi Xcode'da interaktif yapılacak (kod tarafından çalıştırılamaz).

- [~] **Step 6** 🟡 (kod/config kısmı bitti; kullanıcı aksiyonları bekliyor) — Release build hazırlığı  
  Branch: `feature/phase-9-step-6-release-prep`
  **Yapıldı (kod/config):**
  - Versiyon denetimi: `MARKETING_VERSION = 1.0.0`, app target `CURRENT_PROJECT_VERSION = 15`, `CFBundleShortVersionString`/`CFBundleVersion` build ayarlarına bağlı. `ITSAppUsesNonExemptEncryption = false` (export compliance prompt'u önler). Uygun.
  - **Release configuration temiz derleniyor** (simulator, Release; hata yok).
  - `CHANGELOG.md` oluşturuldu (v1.0.0 sürüm notları).
  - `xcconfig.template` güncellendi (stale WATCHMODE_API_KEY kaldırıldı; REVENUECAT_API_KEY + DEVELOPMENT_TEAM eklendi).
  - Debug artifacts: `Purchases.logLevel = .warn` (uygun), `#if DEBUG` yok, 11 print() diagnostic log (hassas veri yok — bırakıldı).
  **KULLANICI AKSİYONU BEKLİYOR (kod tarafından yapılamaz):**
  - ⚠️ **RevenueCat production key:** `Release.xcconfig` içinde `REVENUECAT_API_KEY = REVENUECAT_KEY_PLACEHOLDER` — production public key (`appl_...`) ile değiştirilmeli, yoksa release'te satın almalar çalışmaz.
  - App Store Connect: uygulama kaydı, ekran görüntüleri yükleme, metadata/fiyat.
  - Xcode: Archive + distribution signing + TestFlight'a upload.
  - RevenueCat webhook'unu gerçek sandbox satın almayla doğrula (plan_type premium'a dönüyor mu).

---

## Test Kuralı

Her step'in kodu tamamlandıktan sonra, **git commit/push'tan ÖNCE**:
1. O step'te yapılanlar kısaca özetlenir
2. Xcode Simulator'da nasıl görüleceği / test edileceği açıklanır
3. Kullanıcı test edip onay verir
4. Onay sonrası commit + push yapılır
5. Feature branch develop'a merge edilir, develop remote'a push edilir
6. Faz tamamlandığında develop → main merge + push yapılır

---

## Faz Sonrası Ek Düzeltmeler

- **Feed/log tarihleri hep "az önce" görünüyordu (2026-07-24).** Postgres, salise
  sıfır olduğunda ISO8601 çıktısına yazmıyor (`...T17:23:00+00:00`). Kod ise
  `ISO8601DateFormatter`'ı `.withFractionalSeconds` ile katı kullanıyordu; salisesiz
  değerler parse edilemiyor ve çağrı yerlerindeki `?? Date()` fallback'i yüzünden
  tarih "şimdi" oluyordu. Kullanıcının seçtiği `watched_at` çoğunlukla tam dakika
  olduğu için neredeyse tüm loglar etkileniyordu (feed, profil geçmişi, Wrapped,
  yorum/bildirim/admin ekranları). Çözüm: `SupabaseDate` yardımcısı — önce saliseli,
  sonra salisesiz formatter denenir; 13 parse/serialize noktası buna geçirildi.
- **Supabase keep-alive (2026-07-24).** Free tier ~7 gün hareketsizlikte projeyi
  duraklatıyor (ikinci kez yaşandı). `.github/workflows/supabase-keepalive.yml`
  3 günde bir hafif REST isteği atarak projeyi ayakta tutar. **Geçici çözüm —
  App Store'a çıkmadan önce Supabase Pro'ya geçilmeli.**

## Alınan Kararlar

- **Step 2 — plan_type (paywall) kalıcı çözümü [TAMAMLANDI]:** `plan_type` artık
  istemciden yazılamaz. Kaynak otorite RevenueCat webhook → Supabase Edge Function
  `revenuecat-webhook` (service_role ile yazar). İstemci write yolu kapatıldı
  (migration 005). Admin plan değişimi `admin_set_plan` RPC'sine taşındı.
  **Kalan tek manuel adım — RevenueCat dashboard kurulumu:**
  1. RevenueCat → Project → Integrations → Webhooks → Add.
  2. Webhook URL: `https://muwsslmfbecsgdvuamou.supabase.co/functions/v1/revenuecat-webhook`
  3. Authorization header: Supabase secret `REVENUECAT_WEBHOOK_SECRET` değeri
     (secret Supabase'de ayarlı; değeri güvenli notlarda, repoya konmadı).
  4. Event'ler: tümü (veya en az INITIAL_PURCHASE, RENEWAL, CANCELLATION,
     EXPIRATION, PRODUCT_CHANGE, BILLING_ISSUE, UNCANCELLATION, REFUND).
  Bu kurulum yapılmadan webhook tetiklenmez; plan_type yeni satın almalarda
  güncellenmez (mevcut premium kullanıcılar etkilenmez). RevenueCat sandbox'tan
  "Send test event" ile doğrulanabilir.
- **Step 2 — Admin mutasyonları RPC'ye:** Kolon kilidi nedeniyle admin işlemleri
  (ban) artık doğrudan tablo UPDATE'i ile değil, `is_admin()` kontrolü yapan
  SECURITY DEFINER RPC ile yapılır. İleride yeni admin write işlemleri de aynı
  desene (privileged RPC) uymalı.
