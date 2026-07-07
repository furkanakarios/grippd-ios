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

- [ ] **Step 3** — Edge case düzeltmeleri: boş state'ler, network hataları, timeout handling  
  Branch: `feature/phase-9-step-3-edge-cases`

- [ ] **Step 4** — UI regresyon testi: tüm ekranlar gözden geçirilir, tutarsızlıklar giderilir  
  Branch: `feature/phase-9-step-4-ui-regression`

- [ ] **Step 5** — Final performans geçişi: Instruments son kontrol, büyük listeler stress test  
  Branch: `feature/phase-9-step-5-final-performance`

- [ ] **Step 6** — Release build hazırlığı: versiyonlama, changelog, production config kontrolü  
  Branch: `feature/phase-9-step-6-release-prep`

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
