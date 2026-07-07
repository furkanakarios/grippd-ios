-- Faz 9 — Step 2 (devam): plan_type sunucu otoritesine taşındı
-- Tarih: 2026-07-07
--
-- Paywall bypass kapatılıyor: plan_type artık istemciden yazılamaz. Kaynak
-- otorite RevenueCat webhook → Edge Function (revenuecat-webhook), service_role
-- ile yazar. Admin panelinden plan değişimi de is_admin() kontrollü RPC ile olur.
--
-- UYGULAMA NOTU: psql / `supabase db push` ile uygulanır (Management API'nin
-- /database/query ucu dollar-quote'lu fonksiyon gövdesini bölebilir; o yol
-- kullanılacaksa ifadeler tek tek gönderilmelidir).

begin;

-- İstemcinin plan_type yazma yetkisini kaldır (migration 004'te grant edilmişti).
revoke update (plan_type) on public.users from authenticated;

-- Admin'in başka kullanıcının planını değiştirmesi için yetkili RPC.
create or replace function public.admin_set_plan(target_user_id uuid, new_plan text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Yetkisiz işlem: yalnızca admin';
  end if;
  if new_plan not in ('free', 'premium') then
    raise exception 'Geçersiz plan: %', new_plan;
  end if;
  update public.users
     set plan_type = new_plan,
         updated_at = now()
   where id = target_user_id;
end;
$$;

grant execute on function public.admin_set_plan(uuid, text) to authenticated;

commit;
