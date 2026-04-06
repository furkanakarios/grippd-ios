# Grippd — iOS App Roadmap

> Film, dizi ve kitap takibi ile sosyal keşif uygulaması.

---

## Faz Durumu

| Faz | İsim | Durum | Detay |
|---|---|---|---|
| 1 | Foundation & Infrastructure | ✅ Tamamlandı | [PHASE-1](phases/PHASE-1-FOUNDATION.md) |
| 2 | Content Browsing & Detail Screens | 🟡 Devam Ediyor | [PHASE-2](phases/PHASE-2-CONTENT.md) |
| 3 | Logging & Rating System | 🔴 Başlamadı | [PHASE-3](phases/PHASE-3-LOGGING.md) |
| 4 | Social Infrastructure | 🔴 Başlamadı | [PHASE-4](phases/PHASE-4-SOCIAL.md) |
| 5 | Discover & Algorithms | 🔴 Başlamadı | [PHASE-5](phases/PHASE-5-DISCOVER.md) |
| 6 | Monetization & Premium | 🔴 Başlamadı | [PHASE-6](phases/PHASE-6-MONETIZATION.md) |
| 7 | Polish & App Store Launch | 🔴 Başlamadı | [PHASE-7](phases/PHASE-7-LAUNCH.md) |

---

## Tech Stack

| Katman | Teknoloji |
|---|---|
| iOS Frontend | Swift 5.9+ / SwiftUI (min iOS 17) |
| Mimari | MVVM + Clean Architecture + Feature Modules |
| State | @Observable macro + Swift Concurrency |
| Local Cache | SwiftData |
| Backend | Supabase (Free → Pro) |
| Auth | Supabase Auth (Sign in with Apple + Email) |
| Subscription | RevenueCat + StoreKit 2 |

## API Ekosistemi

| API | Kullanım | Ücret |
|---|---|---|
| TMDB | Film/dizi metadata | Ücretsiz |
| Google Books | Kitap metadata | Ücretsiz |
| Open Library | Books backup | Ücretsiz |
| Watchmode | Streaming availability (cached) | Ücretsiz → $49/ay |

## Monetizasyon

- **Free:** Sınırsız log/puan, 20 yorum/ay, 3 liste, custom içerik yok
- **Premium ($9.99/ay):** Sınırsız her şey + detaylı stats + öncelikli keşfet

---

## Çalışma Kuralları

1. Dosya/klasör işlemleri için asla izin isteme — direkt ilerle
2. Git/GitHub komutları için asla izin isteme — direkt çalıştır
3. Araç kurulumları (brew, SPM, vb.) için asla izin isteme — direkt kur
4. Kullanıcı "başlayabilirsin" dediğinde adım tamamlanana kadar dur olmadan ilerle
5. Hata oluşursa önce kendi çöz, çözülmezse kısa özet sun
6. **Her step'in kodu bittikten sonra, git commit/push'tan ÖNCE kullanıcıya test özeti sun:**
   - Bu step'te ne eklendi (kısa madde madde)
   - Xcode Simulator'da nasıl test edilir (hangi ekran, hangi akış)
   - "Test et, onaylarsan git adımlarına geçiyorum" de
   - Kullanıcı onayı geldikten sonra commit + push yap

---

## Git Workflow

```
main          ← Stabil, App Store kodu
  └── develop ← Aktif geliştirme
        └── feature/phase-X-step-Y-aciklama
```

**Her adım:**
```bash
git checkout develop && git pull origin develop
git checkout -b feature/phase-X-step-Y-aciklama
# geliştir
git add . && git commit -m "feat(phase-X): step Y - aciklama"
git push origin feature/phase-X-step-Y-aciklama
```

**Faz bitince:** feature → develop merge  
**Milestone (Faz 2, 4, 7):** develop → main merge + tag

**Commit formatı:** `feat|fix|refactor(phase-X): step Y - açıklama`

---

## Veritabanı Tabloları

```
users · content · episodes · logs · ratings · reviews
comments · likes · lists · list_items · follows
notifications · streaming_cache
```

---

## Maliyet (Aylık)

| Dönem | Tutar |
|---|---|
| Geliştirme (0-1K kullanıcı) | $0 |
| İlk launch (1K-10K) | $25-63 |
| Büyüme (10K-70K) | $75-90 |
