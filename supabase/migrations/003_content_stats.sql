-- content_stats: içeriklerin topluluk puanı ve yorum sayısı
create table if not exists content_stats (
  content_key  text primary key,
  avg_rating   double precision not null default 0,
  review_count int not null default 0,
  updated_at   timestamptz not null default now()
);

alter table content_stats enable row level security;

drop policy if exists "Public read" on content_stats;
create policy "Public read" on content_stats for select using (true);

-- Test verisi (Inception, Interstellar, Breaking Bad, Game of Thrones)
insert into content_stats (content_key, avg_rating, review_count)
values
  ('movie-27205', 8.3, 142),
  ('movie-157336', 8.6, 218),
  ('tv-1396', 9.1, 287),
  ('tv-1399', 8.7, 195)
on conflict do nothing;
