# Faz 9 — Bugfix, Security & Final QA

**Durum:** 🔴 Başlamadı  
**Branch base:** `develop`

---

## Amaç

TestFlight test döneminde (Phase 7 Step 8) ve Phase 8 sürecinde biriken tüm sorunları
temizleyip uygulamayı App Store'a hazır hale getirmek.

---

## Adımlar

- [ ] **Step 1** — TestFlight crash raporları & feedback bugfix'leri  
  Branch: `feature/phase-9-step-1-crash-fixes`

- [ ] **Step 2** — Güvenlik denetimi: RLS politikaları, API key güvenliği, input validation  
  Branch: `feature/phase-9-step-2-security-audit`

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

_Bu faz boyunca alınan teknik kararlar buraya eklenir._
