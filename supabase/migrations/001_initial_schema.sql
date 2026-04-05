-- ============================================================
-- Grippd — Initial Schema Migration
-- 001_initial_schema.sql
-- Supabase SQL Editor'a kopyalayıp çalıştır
-- ============================================================

-- ============================================================
-- 1. EXTENSIONS
-- ============================================================
create extension if not exists "uuid-ossp";

-- ============================================================
-- 2. TABLES
-- ============================================================

-- 2.1 users (auth.users tablosunu extend eder)
create table public.users (
  id                        uuid references auth.users(id) on delete cascade primary key,
  username                  text unique not null,
  display_name              text not null,
  bio                       text,
  avatar_url                text,
  banner_url                text,
  is_private                boolean default false,
  plan_type                 text default 'free' check (plan_type in ('free', 'premium')),
  -- Free tier limit takibi
  monthly_comment_count     integer default 0,
  monthly_comment_reset_at  timestamptz default date_trunc('month', now()),
  created_at                timestamptz default now(),
  updated_at                timestamptz default now()
);
comment on table public.users is 'Kullanıcı profil bilgileri';

-- 2.2 content (film, dizi, kitap — on-demand cache modeli)
create table public.content (
  id               uuid default gen_random_uuid() primary key,
  tmdb_id          integer,
  google_books_id  text,
  open_library_id  text,
  content_type     text not null check (content_type in ('movie', 'tv_show', 'book')),
  title            text not null,
  original_title   text,
  overview         text,
  poster_url       text,
  backdrop_url     text,
  release_date     date,
  genres           text[] default '{}',
  runtime_minutes  integer,
  language         text,
  -- Kullanıcı tarafından eklenen içerik
  is_user_created  boolean default false,
  created_by_user_id uuid references public.users(id) on delete set null,
  created_at       timestamptz default now(),
  unique (tmdb_id, content_type),
  unique (google_books_id)
);
comment on table public.content is 'Film, dizi ve kitap metadata cache';

-- 2.3 episodes (dizi bölümleri)
create table public.episodes (
  id               uuid default gen_random_uuid() primary key,
  content_id       uuid references public.content(id) on delete cascade not null,
  season_number    integer not null,
  episode_number   integer not null,
  title            text,
  overview         text,
  still_url        text,
  air_date         date,
  runtime_minutes  integer,
  tmdb_episode_id  integer,
  created_at       timestamptz default now(),
  unique (content_id, season_number, episode_number)
);
comment on table public.episodes is 'Dizi bölüm detayları';

-- 2.4 logs (izleme / okuma kayıtları — birden fazla olabilir)
create table public.logs (
  id               uuid default gen_random_uuid() primary key,
  user_id          uuid references public.users(id) on delete cascade not null,
  content_id       uuid references public.content(id) on delete cascade not null,
  episode_id       uuid references public.episodes(id) on delete cascade,
  watched_at       timestamptz not null default now(),
  -- 0.0–10.0 arası, 0.5 adımlarla
  rating           numeric(3,1) check (rating is null or (rating >= 0 and rating <= 10)),
  emoji_reaction   text,
  is_rewatch       boolean default false,
  notes            text,
  created_at       timestamptz default now(),
  updated_at       timestamptz default now()
);
comment on table public.logs is 'Kullanıcı izleme/okuma logları';

-- 2.5 reviews (uzun form yorum)
create table public.reviews (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references public.users(id) on delete cascade not null,
  content_id  uuid references public.content(id) on delete cascade not null,
  body        text not null,
  like_count  integer default 0,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);
comment on table public.reviews is 'İçerik yorumları';

-- 2.6 comments (log ve review altı yorumlar)
create table public.comments (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references public.users(id) on delete cascade not null,
  log_id      uuid references public.logs(id) on delete cascade,
  review_id   uuid references public.reviews(id) on delete cascade,
  body        text not null,
  like_count  integer default 0,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now(),
  -- Ya log ya review, ikisi birden olamaz
  constraint comments_target_check check (
    (log_id is not null)::int + (review_id is not null)::int = 1
  )
);
comment on table public.comments is 'Log ve review altı yorumlar';

-- 2.7 likes (log, review, comment beğenileri)
create table public.likes (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references public.users(id) on delete cascade not null,
  log_id      uuid references public.logs(id) on delete cascade,
  review_id   uuid references public.reviews(id) on delete cascade,
  comment_id  uuid references public.comments(id) on delete cascade,
  created_at  timestamptz default now(),
  -- Tek bir hedef
  constraint likes_target_check check (
    (log_id is not null)::int +
    (review_id is not null)::int +
    (comment_id is not null)::int = 1
  ),
  unique (user_id, log_id),
  unique (user_id, review_id),
  unique (user_id, comment_id)
);
comment on table public.likes is 'Beğeni kayıtları';

-- 2.8 lists (kullanıcı listeleri)
create table public.lists (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references public.users(id) on delete cascade not null,
  name        text not null,
  description text,
  is_public   boolean default true,
  is_default  boolean default false,
  list_type   text default 'custom' check (list_type in ('watchlist', 'readlist', 'custom')),
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);
comment on table public.lists is 'Kullanıcı listeleri (watchlist, readlist, custom)';

-- 2.9 list_items
create table public.list_items (
  id          uuid default gen_random_uuid() primary key,
  list_id     uuid references public.lists(id) on delete cascade not null,
  content_id  uuid references public.content(id) on delete cascade not null,
  sort_order  integer default 0,
  created_at  timestamptz default now(),
  unique (list_id, content_id)
);
comment on table public.list_items is 'Liste içerikleri';

-- 2.10 follows
create table public.follows (
  id            uuid default gen_random_uuid() primary key,
  follower_id   uuid references public.users(id) on delete cascade not null,
  following_id  uuid references public.users(id) on delete cascade not null,
  created_at    timestamptz default now(),
  unique (follower_id, following_id),
  constraint follows_no_self_follow check (follower_id != following_id)
);
comment on table public.follows is 'Takip ilişkileri';

-- 2.11 notifications
create table public.notifications (
  id          uuid default gen_random_uuid() primary key,
  user_id     uuid references public.users(id) on delete cascade not null,
  actor_id    uuid references public.users(id) on delete cascade,
  type        text not null check (type in ('follow', 'like_log', 'like_review', 'comment', 'comment_like')),
  log_id      uuid references public.logs(id) on delete cascade,
  review_id   uuid references public.reviews(id) on delete cascade,
  comment_id  uuid references public.comments(id) on delete cascade,
  is_read     boolean default false,
  created_at  timestamptz default now()
);
comment on table public.notifications is 'Kullanıcı bildirimleri';

-- 2.12 streaming_cache (Watchmode API sonuçlarını cache'le)
create table public.streaming_cache (
  id          uuid default gen_random_uuid() primary key,
  content_id  uuid references public.content(id) on delete cascade not null unique,
  platforms   jsonb default '[]',
  expires_at  timestamptz not null,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);
comment on table public.streaming_cache is 'Watchmode streaming platform cache (7 günlük TTL)';


-- ============================================================
-- 3. INDEXES
-- ============================================================
create index idx_content_tmdb_id      on public.content(tmdb_id);
create index idx_content_type         on public.content(content_type);
create index idx_content_user_created on public.content(is_user_created) where is_user_created = true;

create index idx_episodes_content     on public.episodes(content_id);

create index idx_logs_user_id         on public.logs(user_id);
create index idx_logs_content_id      on public.logs(content_id);
create index idx_logs_watched_at      on public.logs(watched_at desc);
create index idx_logs_user_content    on public.logs(user_id, content_id);

create index idx_reviews_content_id   on public.reviews(content_id);
create index idx_reviews_user_id      on public.reviews(user_id);

create index idx_comments_log_id      on public.comments(log_id);
create index idx_comments_review_id   on public.comments(review_id);

create index idx_likes_log_id         on public.likes(log_id);
create index idx_likes_review_id      on public.likes(review_id);

create index idx_lists_user_id        on public.lists(user_id);

create index idx_follows_follower     on public.follows(follower_id);
create index idx_follows_following    on public.follows(following_id);

create index idx_notifications_user   on public.notifications(user_id, is_read);

create index idx_streaming_expires    on public.streaming_cache(expires_at);


-- ============================================================
-- 4. FUNCTIONS & TRIGGERS
-- ============================================================

-- 4.1 updated_at otomatik güncelle
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_users_updated_at
  before update on public.users
  for each row execute function public.set_updated_at();

create trigger trg_logs_updated_at
  before update on public.logs
  for each row execute function public.set_updated_at();

create trigger trg_reviews_updated_at
  before update on public.reviews
  for each row execute function public.set_updated_at();

create trigger trg_comments_updated_at
  before update on public.comments
  for each row execute function public.set_updated_at();

create trigger trg_lists_updated_at
  before update on public.lists
  for each row execute function public.set_updated_at();

-- 4.2 Yeni auth kullanıcısı → public.users kaydı + varsayılan listeler
create or replace function public.handle_new_user()
returns trigger as $$
declare
  base_username text;
  final_username text;
  counter       integer := 0;
begin
  base_username := coalesce(
    new.raw_user_meta_data->>'username',
    split_part(new.email, '@', 1)
  );
  final_username := base_username;

  -- Kullanıcı adı çakışıyorsa sayı ekle
  while exists (select 1 from public.users where username = final_username) loop
    counter := counter + 1;
    final_username := base_username || counter::text;
  end loop;

  insert into public.users (id, username, display_name)
  values (
    new.id,
    final_username,
    coalesce(new.raw_user_meta_data->>'display_name', final_username)
  );

  -- Varsayılan listeler
  insert into public.lists (user_id, name, list_type, is_default, is_public)
  values
    (new.id, 'Watchlist',    'watchlist', true, true),
    (new.id, 'Reading List', 'readlist',  true, true);

  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 4.3 Aylık yorum sayacını sıfırla
create or replace function public.reset_monthly_comment_count()
returns void as $$
begin
  update public.users
  set monthly_comment_count    = 0,
      monthly_comment_reset_at = date_trunc('month', now())
  where monthly_comment_reset_at < date_trunc('month', now());
end;
$$ language plpgsql security definer;

-- 4.4 like_count denormalize güncelleme (reviews)
create or replace function public.update_review_like_count()
returns trigger as $$
begin
  if (tg_op = 'INSERT' and new.review_id is not null) then
    update public.reviews set like_count = like_count + 1 where id = new.review_id;
  elsif (tg_op = 'DELETE' and old.review_id is not null) then
    update public.reviews set like_count = greatest(like_count - 1, 0) where id = old.review_id;
  end if;
  return coalesce(new, old);
end;
$$ language plpgsql security definer;

create trigger trg_likes_review_count
  after insert or delete on public.likes
  for each row execute function public.update_review_like_count();

-- 4.5 like_count denormalize güncelleme (comments)
create or replace function public.update_comment_like_count()
returns trigger as $$
begin
  if (tg_op = 'INSERT' and new.comment_id is not null) then
    update public.comments set like_count = like_count + 1 where id = new.comment_id;
  elsif (tg_op = 'DELETE' and old.comment_id is not null) then
    update public.comments set like_count = greatest(like_count - 1, 0) where id = old.comment_id;
  end if;
  return coalesce(new, old);
end;
$$ language plpgsql security definer;

create trigger trg_likes_comment_count
  after insert or delete on public.likes
  for each row execute function public.update_comment_like_count();


-- ============================================================
-- 5. ROW LEVEL SECURITY
-- ============================================================

alter table public.users            enable row level security;
alter table public.content          enable row level security;
alter table public.episodes         enable row level security;
alter table public.logs             enable row level security;
alter table public.reviews          enable row level security;
alter table public.comments         enable row level security;
alter table public.likes            enable row level security;
alter table public.lists            enable row level security;
alter table public.list_items       enable row level security;
alter table public.follows          enable row level security;
alter table public.notifications    enable row level security;
alter table public.streaming_cache  enable row level security;

-- ── users ──────────────────────────────────────────────────
-- Public profil herkes görebilir; private profil sadece takipçiler
create policy "users_select" on public.users for select using (
  not is_private
  or id = auth.uid()
  or exists (
    select 1 from public.follows
    where follower_id = auth.uid() and following_id = users.id
  )
);
create policy "users_insert" on public.users for insert
  with check (id = auth.uid());
create policy "users_update" on public.users for update
  using (id = auth.uid());
create policy "users_delete" on public.users for delete
  using (id = auth.uid());

-- ── content ────────────────────────────────────────────────
create policy "content_select_all" on public.content for select using (true);
create policy "content_insert_auth" on public.content for insert
  with check (auth.uid() is not null);
create policy "content_update_creator" on public.content for update
  using (created_by_user_id = auth.uid());

-- ── episodes ───────────────────────────────────────────────
create policy "episodes_select_all" on public.episodes for select using (true);
create policy "episodes_insert_auth" on public.episodes for insert
  with check (auth.uid() is not null);

-- ── logs ───────────────────────────────────────────────────
-- Profil gizliliğine göre: public profil → herkes; private → sadece takipçi
create policy "logs_select" on public.logs for select using (
  user_id = auth.uid()
  or exists (
    select 1 from public.users u
    where u.id = logs.user_id
    and (
      not u.is_private
      or exists (
        select 1 from public.follows f
        where f.follower_id = auth.uid() and f.following_id = u.id
      )
    )
  )
);
create policy "logs_insert" on public.logs for insert
  with check (user_id = auth.uid());
create policy "logs_update" on public.logs for update
  using (user_id = auth.uid());
create policy "logs_delete" on public.logs for delete
  using (user_id = auth.uid());

-- ── reviews ────────────────────────────────────────────────
create policy "reviews_select" on public.reviews for select using (
  user_id = auth.uid()
  or exists (
    select 1 from public.users u
    where u.id = reviews.user_id
    and (
      not u.is_private
      or exists (
        select 1 from public.follows f
        where f.follower_id = auth.uid() and f.following_id = u.id
      )
    )
  )
);
create policy "reviews_insert" on public.reviews for insert
  with check (user_id = auth.uid());
create policy "reviews_update" on public.reviews for update
  using (user_id = auth.uid());
create policy "reviews_delete" on public.reviews for delete
  using (user_id = auth.uid());

-- ── comments ───────────────────────────────────────────────
create policy "comments_select_all" on public.comments for select using (true);
create policy "comments_insert_auth" on public.comments for insert
  with check (user_id = auth.uid());
create policy "comments_update_owner" on public.comments for update
  using (user_id = auth.uid());
create policy "comments_delete_owner" on public.comments for delete
  using (user_id = auth.uid());

-- ── likes ──────────────────────────────────────────────────
create policy "likes_select_all" on public.likes for select using (true);
create policy "likes_insert_auth" on public.likes for insert
  with check (user_id = auth.uid());
create policy "likes_delete_owner" on public.likes for delete
  using (user_id = auth.uid());

-- ── lists ──────────────────────────────────────────────────
create policy "lists_select" on public.lists for select using (
  user_id = auth.uid()
  or (
    is_public = true
    and exists (
      select 1 from public.users u
      where u.id = lists.user_id
      and (
        not u.is_private
        or exists (
          select 1 from public.follows f
          where f.follower_id = auth.uid() and f.following_id = u.id
        )
      )
    )
  )
);
create policy "lists_insert" on public.lists for insert
  with check (user_id = auth.uid());
create policy "lists_update" on public.lists for update
  using (user_id = auth.uid());
create policy "lists_delete" on public.lists for delete
  using (user_id = auth.uid() and is_default = false);

-- ── list_items ─────────────────────────────────────────────
create policy "list_items_select" on public.list_items for select using (
  exists (
    select 1 from public.lists l
    where l.id = list_items.list_id
    and (
      l.user_id = auth.uid()
      or (l.is_public = true and exists (
        select 1 from public.users u
        where u.id = l.user_id and not u.is_private
      ))
    )
  )
);
create policy "list_items_insert" on public.list_items for insert
  with check (
    exists (
      select 1 from public.lists l
      where l.id = list_items.list_id and l.user_id = auth.uid()
    )
  );
create policy "list_items_delete" on public.list_items for delete
  using (
    exists (
      select 1 from public.lists l
      where l.id = list_items.list_id and l.user_id = auth.uid()
    )
  );

-- ── follows ────────────────────────────────────────────────
create policy "follows_select_all" on public.follows for select using (true);
create policy "follows_insert_auth" on public.follows for insert
  with check (follower_id = auth.uid());
create policy "follows_delete_owner" on public.follows for delete
  using (follower_id = auth.uid());

-- ── notifications ──────────────────────────────────────────
create policy "notifications_select_own" on public.notifications for select
  using (user_id = auth.uid());
create policy "notifications_update_own" on public.notifications for update
  using (user_id = auth.uid());
create policy "notifications_insert_auth" on public.notifications for insert
  with check (auth.uid() is not null);

-- ── streaming_cache ────────────────────────────────────────
create policy "streaming_cache_select_all" on public.streaming_cache for select using (true);
create policy "streaming_cache_insert_auth" on public.streaming_cache for insert
  with check (auth.uid() is not null);
create policy "streaming_cache_update_auth" on public.streaming_cache for update
  using (auth.uid() is not null);
