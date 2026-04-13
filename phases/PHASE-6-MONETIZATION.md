# Faz 6 — Monetization & Premium

**Durum:** ✅ Tamamlandı  
**Branch base:** `develop`

---

## Adımlar

- [x] **Step 1** — RevenueCat SDK kurulum, Supabase subscription sync  
  Branch: `feature/phase-6-step-1-revenuecat-setup` ✅

- [x] **Step 2** — Paywall ekranı UI & premium visual indicators  
  Branch: `feature/phase-6-step-2-paywall-ui` ✅

- [x] **Step 3** — Premium feature gate sistemi: merkezi kontrol noktası (PremiumGate)  
  Branch: `feature/phase-6-step-3-feature-gate` ✅

- [x] **Step 4** — Yorum limiti (20/ay) enforce: sayaç + paywall yönlendirme  
  Branch: `feature/phase-6-step-4-comment-limit-enforce` ✅

- [x] **Step 5** — Paywall ekranı UI: özellik karşılaştırması (Step 2 ile birleştirildi)  
  Branch: `feature/phase-6-step-2-paywall-ui` ✅

- [x] **Step 6** — Liste limiti (3) enforce: paywall yönlendirme (Phase 3 Step 8'de tamamlandı)  
  Branch: `feature/phase-3-step-8-list-limits` ✅

- [x] **Step 7** — Custom içerik ekleme kilidi (Premium only)  
  Branch: `feature/phase-6-step-7-custom-content-gate` ✅

- [x] **Step 8** — Abonelik yönetim ekranı: aktif plan, yenileme, iptal  
  Branch: `feature/phase-6-step-8-subscription-management` ✅

- [x] **Step 9** — 7 günlük ücretsiz deneme (free trial) akışı  
  Branch: `feature/phase-6-step-9-free-trial` ✅

- [ ] **Step 10** — RevenueCat analytics: MRR, churn rate, conversion ⏸ Ertelendi  
  Branch: `feature/phase-6-step-10-revenue-analytics`  
  > Kullanıcı tabanı yeterince büyüdüğünde anlamlı olacak. Admin Panel fazına alındı.

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

_Bu faz boyunca alınan teknik kararlar buraya eklenir._

---

## Notlar & Sorunlar

_Geliştirme sürecinde karşılaşılan sorunlar ve çözümleri buraya eklenir._
