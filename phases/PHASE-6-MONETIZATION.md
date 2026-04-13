# Faz 6 — Monetization & Premium

**Durum:** 🟡 Devam Ediyor  
**Branch base:** `develop`

---

## Adımlar

- [x] **Step 1** — RevenueCat SDK kurulum, Supabase subscription sync  
  Branch: `feature/phase-6-step-1-revenuecat-setup` ✅

- [x] **Step 2** — Paywall ekranı UI & premium visual indicators  
  Branch: `feature/phase-6-step-2-paywall-ui` ✅

- [ ] **Step 3** — Paywall ekranı UI: özellik karşılaştırması, animasyonlar  
  Branch: `feature/phase-6-step-3-paywall-ui`

- [ ] **Step 4** — Premium feature gate sistemi: merkezi kontrol noktası  
  Branch: `feature/phase-6-step-4-feature-gate`

- [ ] **Step 5** — Yorum limiti (20/ay) enforce: sayaç + paywall yönlendirme  
  Branch: `feature/phase-6-step-5-comment-limit-enforce`

- [ ] **Step 6** — Liste limiti (3) enforce: 3. listede paywall göster  
  Branch: `feature/phase-6-step-6-list-limit-enforce`

- [ ] **Step 7** — Custom içerik ekleme kilidi (Premium only)  
  Branch: `feature/phase-6-step-7-custom-content-gate`

- [ ] **Step 8** — Abonelik yönetim ekranı: aktif plan, yenileme, iptal  
  Branch: `feature/phase-6-step-8-subscription-management`

- [ ] **Step 9** — 7 günlük ücretsiz deneme (free trial) akışı  
  Branch: `feature/phase-6-step-9-free-trial`

- [ ] **Step 10** — RevenueCat analytics: MRR, churn rate, conversion  
  Branch: `feature/phase-6-step-10-revenue-analytics`

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
