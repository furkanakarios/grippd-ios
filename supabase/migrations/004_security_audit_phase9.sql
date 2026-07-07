-- Faz 9 — Step 2: Güvenlik Denetimi düzeltmeleri
-- Tarih: 2026-07-07
--
-- Bu migration üç güvenlik açığını kapatır:
--   1. (KRİTİK) users tablosunda ayrıcalık yükseltme — kullanıcı kendi satırında
--      is_admin / is_banned / comment sayaçlarını değiştirebiliyordu.
--   2. Sunucu tarafı input validation eksikliği — metin alanlarında sınır yoktu.
--   3. notifications tablosuna istemciden serbest INSERT (spam/phishing vektörü).
--
-- Not: plan_type kolonu bilinçli olarak kilitlenMEDİ; şu an istemci RevenueCat
-- entitlement'ına göre yazıyor. Kalıcı çözüm (RevenueCat webhook → Edge Function)
-- ayrı bir iş olarak ele alınacak (bkz. PHASE-9 Alınan Kararlar).
--
-- UYGULAMA NOTU: Bu dosya psql / `supabase db push` ile uygulanmalıdır. Supabase
-- Management API'nin /database/query ucu, dollar-quote'lu ($$...$$) fonksiyon
-- gövdelerini naif biçimde ';' üzerinden böldüğü için CREATE FUNCTION'ı parçalar
-- ve batch'i geri sarar. O yol kullanılacaksa ifadeler tek tek gönderilmelidir.

begin;

-- ============================================================================
-- 1. AYRICALIK YÜKSELTME — users kolon bazlı UPDATE kilidi
-- ============================================================================
-- RLS satır sahipliğini koruyordu ama kolon bazında kısıt yoktu; sahibi olduğu
-- satırda her kolonu (is_admin dahil) yazabiliyordu. Kolon düzeyinde yetki ile
-- kullanıcının yalnızca profil alanlarını güncellemesine izin veriyoruz.
-- Owner (postgres) ve service_role bu kısıttan etkilenmez; SECURITY DEFINER
-- fonksiyonlar (sayaç güncelleme vb.) sorunsuz çalışmaya devam eder.

revoke update on public.users from anon, authenticated;

grant update (
  username,
  display_name,
  bio,
  avatar_url,
  banner_url,
  is_private,
  interests,
  onboarding_completed,
  plan_type            -- geçici: istemci RevenueCat sonrası yazıyor (webhook'a taşınacak)
) on public.users to authenticated;

-- is_admin, is_banned, monthly_comment_count, monthly_comment_reset_at,
-- id, created_at, updated_at kasıtlı olarak grant edilmedi → istemci değiştiremez.

-- Admin'in başka kullanıcıyı banlaması artık doğrudan UPDATE ile değil (kolon
-- yetkisi kaldırıldı), is_admin() kontrolü yapan SECURITY DEFINER RPC ile olur.
-- Bu, admin mutasyonlarını denetlenebilir tek kapıya toplar.
create or replace function public.admin_set_banned(target_user_id uuid, banned boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Yetkisiz işlem: yalnızca admin';
  end if;
  update public.users
     set is_banned = banned,
         updated_at = now()
   where id = target_user_id;
end;
$$;

grant execute on function public.admin_set_banned(uuid, boolean) to authenticated;

-- ============================================================================
-- 2. INPUT VALIDATION — sunucu tarafı uzunluk/format kısıtları
-- ============================================================================
-- Metin alanları sınırsızdı; kötü niyetli kullanıcı megabaytlarca veri sokabilir
-- (depolama/DoS/UI bozulması). Mevcut veri bu kısıtları ihlal etmiyor (doğrulandı).

alter table public.users
  add constraint users_username_format check (username ~ '^[a-z0-9_]{3,30}$'),
  add constraint users_display_name_len check (char_length(coalesce(display_name, '')) <= 50),
  add constraint users_bio_len check (bio is null or char_length(bio) <= 500);

alter table public.comments
  add constraint comments_body_len check (char_length(coalesce(body, '')) between 1 and 2000);

alter table public.reviews
  add constraint reviews_body_len check (body is null or char_length(body) <= 5000);

alter table public.lists
  add constraint lists_name_len check (char_length(coalesce(name, '')) between 1 and 100),
  add constraint lists_desc_len check (description is null or char_length(description) <= 500);

alter table public.logs
  add constraint logs_notes_len check (notes is null or char_length(notes) <= 2000);

-- ============================================================================
-- 3. NOTIFICATIONS — istemciden serbest INSERT'i kaldır
-- ============================================================================
-- Bildirimler yalnızca SECURITY DEFINER trigger'larla (postgres sahipli, RLS'i
-- bypass eder) oluşturuluyor; istemci hiçbir zaman doğrudan insert etmiyor.
-- Serbest INSERT politikaları herhangi bir kullanıcının başkasına sahte bildirim
-- göndermesine izin veriyordu — kaldırıyoruz.

drop policy if exists "Bildirim eklenebilir" on public.notifications;
drop policy if exists "notifications_insert_auth" on public.notifications;

-- Yinelenen SELECT/UPDATE politikalarını sadeleştir (aynı kuralın iki kopyası).
drop policy if exists "Kullanıcı kendi bildirimlerini görebilir" on public.notifications;
drop policy if exists "Kullanıcı kendi bildirimlerini güncelleyebilir" on public.notifications;

commit;

-- PostgREST'in yeni fonksiyonu/şemayı görmesi için cache yenile (transaction dışı).
notify pgrst, 'reload schema';
