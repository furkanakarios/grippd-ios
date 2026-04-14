# Faz 8 — Admin Panel (Mobile)

**Durum:** 🔴 Başlamadı  
**Branch base:** `develop`

---

## Amaç

Uygulama sahibinin mobil cihazdan içerik ve kullanıcı yönetimi yapabilmesi.
Admin kullanıcı özel bir `is_admin` flag ile işaretlenir, normal kullanıcılar bu ekranlara erişemez.

---

## Adımlar

- [ ] **Step 1** — Admin kimlik doğrulama: `is_admin` flag kontrolü, admin tab/menü  
  Branch: `feature/phase-8-step-1-admin-auth`

- [ ] **Step 2** — Kullanıcı yönetimi: listeleme, arama, ban/unban, plan değiştirme  
  Branch: `feature/phase-8-step-2-user-management`

- [ ] **Step 3** — İçerik moderasyonu: raporlanan yorumlar, içerik kaldırma  
  Branch: `feature/phase-8-step-3-content-moderation`

- [ ] **Step 4** — Curated list yönetimi: Discover ekranındaki koleksiyonları admin ekler/düzenler  
  Branch: `feature/phase-8-step-4-curated-lists-admin`

- [ ] **Step 5** — Uygulama istatistikleri: toplam kullanıcı, günlük aktif, log sayısı  
  Branch: `feature/phase-8-step-5-app-stats`

- [ ] **Step 6** — Push notification gönderimi: tüm kullanıcılara veya segmente duyuru  
  Branch: `feature/phase-8-step-6-push-notifications`

- [ ] **Step 7** — A/B test altyapısı: kullanıcı gruplama, varyant atama, sonuç takibi  
  Branch: `feature/phase-8-step-7-ab-testing`  
  > Phase 5 Step 10'dan ertelendi.

- [ ] **Step 8** — Feature flag sistemi: özelliği canlıda açıp kapama  
  Branch: `feature/phase-8-step-8-feature-flags`

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
