-- Faz 1 Step 6: Onboarding tamamlandı flag'i
alter table public.users
  add column if not exists onboarding_completed boolean default false;

-- Mevcut kullanıcılar için: username trigger tarafından atandıysa onboarding tamamlanmış sayılır
-- (migration öncesi kayıt olan test kullanıcıları etkilenmesin diye false bırakıyoruz)
