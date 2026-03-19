-- ============================================================
-- SeyGo — Run this entire file once in Supabase SQL Editor
-- Safe to run multiple times
-- ============================================================


-- ============================================================
-- 1. profiles
-- ============================================================
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  full_name     text,
  bio           text,
  home_city     text,
  travel_style  text,
  avatar_url    text,
  updated_at    timestamptz default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Users can read own profile"   on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;

create policy "Users can read own profile"   on public.profiles for select using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);


-- ============================================================
-- 2. playlists
-- ============================================================
create table if not exists public.playlists (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid references auth.users(id) on delete cascade,
  name           text not null,
  description    text,
  icon           text default 'playlist_play',
  status         text default 'active',
  visibility     text default 'public',
  is_featured    boolean default false,
  is_default     boolean default false,
  creator_name   text,
  places_count   int default 0,
  created_at     timestamptz default now()
);

alter table public.playlists add column if not exists user_id      uuid references auth.users(id) on delete cascade;
alter table public.playlists add column if not exists icon         text default 'playlist_play';
alter table public.playlists add column if not exists status       text default 'active';
alter table public.playlists add column if not exists is_default   boolean default false;
alter table public.playlists add column if not exists is_featured  boolean default false;
alter table public.playlists add column if not exists visibility   text default 'public';
alter table public.playlists add column if not exists creator_name text;
alter table public.playlists add column if not exists places_count int default 0;

create index if not exists idx_playlists_user_id     on public.playlists (user_id);
create index if not exists idx_playlists_status      on public.playlists (status);
create index if not exists idx_playlists_is_featured on public.playlists (is_featured);

alter table public.playlists enable row level security;

drop policy if exists "Public playlists are readable by all" on public.playlists;
drop policy if exists "Owners can read own playlists"        on public.playlists;
drop policy if exists "Owners can insert playlists"          on public.playlists;
drop policy if exists "Owners can update playlists"          on public.playlists;
drop policy if exists "Owners can delete playlists"          on public.playlists;

create policy "Public playlists are readable by all" on public.playlists for select
  using (status = 'active' and visibility = 'public');
create policy "Owners can read own playlists" on public.playlists for select
  using (auth.uid() = user_id);
create policy "Owners can insert playlists" on public.playlists for insert
  with check (auth.uid() = user_id);
create policy "Owners can update playlists" on public.playlists for update
  using (auth.uid() = user_id);
create policy "Owners can delete playlists" on public.playlists for delete
  using (auth.uid() = user_id);


-- ============================================================
-- 3. playlist_places
-- ============================================================
create table if not exists public.playlist_places (
  id           uuid primary key default gen_random_uuid(),
  playlist_id  uuid not null references public.playlists(id) on delete cascade,
  place_id     text not null,
  notes        text,
  distance_km  float,
  sort_order   int default 0,
  added_at     timestamptz default now()
);

create index if not exists idx_playlist_places_playlist_id on public.playlist_places (playlist_id);
create index if not exists idx_playlist_places_place_id    on public.playlist_places (place_id);
create unique index if not exists uq_playlist_places on public.playlist_places (playlist_id, place_id);

alter table public.playlist_places enable row level security;

drop policy if exists "Playlist places inherit playlist read access" on public.playlist_places;
drop policy if exists "Playlist owners can manage places"            on public.playlist_places;

create policy "Playlist places inherit playlist read access" on public.playlist_places for select
  using (exists (
    select 1 from public.playlists pl
    where pl.id = playlist_id
      and ((pl.status = 'active' and pl.visibility = 'public') or pl.user_id = auth.uid())
  ));
create policy "Playlist owners can manage places" on public.playlist_places for all
  using (exists (
    select 1 from public.playlists pl
    where pl.id = playlist_id and pl.user_id = auth.uid()
  ));

-- Auto-sync places_count
create or replace function public.sync_playlist_places_count()
returns trigger language plpgsql security definer as $$
begin
  if TG_OP = 'INSERT' then
    update public.playlists set places_count = places_count + 1 where id = new.playlist_id;
  elsif TG_OP = 'DELETE' then
    update public.playlists set places_count = greatest(places_count - 1, 0) where id = old.playlist_id;
  end if;
  return null;
end;
$$;

drop trigger if exists playlist_places_count_sync on public.playlist_places;
create trigger playlist_places_count_sync
  after insert or delete on public.playlist_places
  for each row execute function public.sync_playlist_places_count();


-- ============================================================
-- 4. reviews
-- Drop and recreate if user_id has wrong type (bigint instead of uuid)
-- ============================================================
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'reviews'
      and column_name = 'user_id' and data_type != 'uuid'
  ) then
    drop table public.reviews cascade;
  end if;
end $$;

create table if not exists public.reviews (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid references auth.users(id) on delete cascade,
  place_id       text,
  place_name     text not null,
  rating         int check (rating between 1 and 5),
  review_text    text,
  status         text default 'pending',
  user_name      text,
  user_badge     text default 'Explorer',
  likes_count    int default 0,
  comments_count int default 0,
  created_at     timestamptz default now()
);

alter table public.reviews add column if not exists user_id        uuid references auth.users(id) on delete cascade;
alter table public.reviews add column if not exists place_id       text;
alter table public.reviews add column if not exists place_name     text;
alter table public.reviews add column if not exists rating         int;
alter table public.reviews add column if not exists review_text    text;
alter table public.reviews add column if not exists status         text default 'pending';
alter table public.reviews add column if not exists user_name      text;
alter table public.reviews add column if not exists user_badge     text default 'Explorer';
alter table public.reviews add column if not exists likes_count    int default 0;
alter table public.reviews add column if not exists comments_count int default 0;
alter table public.reviews add column if not exists created_at     timestamptz default now();

create index if not exists idx_reviews_user_id  on public.reviews (user_id);
create index if not exists idx_reviews_status   on public.reviews (status);
create index if not exists idx_reviews_place_id on public.reviews (place_id);

alter table public.reviews enable row level security;

drop policy if exists "Approved reviews readable by all" on public.reviews;
drop policy if exists "Users can read own reviews"       on public.reviews;
drop policy if exists "Users can insert reviews"         on public.reviews;
drop policy if exists "Users can update own reviews"     on public.reviews;

create policy "Approved reviews readable by all" on public.reviews for select
  using (status = 'approved');
create policy "Users can read own reviews" on public.reviews for select
  using (auth.uid() = user_id);
create policy "Users can insert reviews" on public.reviews for insert
  with check (auth.uid() = user_id);
create policy "Users can update own reviews" on public.reviews for update
  using (auth.uid() = user_id);


-- ============================================================
-- 5. photos (for stats tracking)
-- ============================================================
create table if not exists public.photos (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users(id) on delete cascade,
  place_id   text,
  url        text,
  created_at timestamptz default now()
);

alter table public.photos add column if not exists user_id    uuid references auth.users(id) on delete cascade;
alter table public.photos add column if not exists place_id   text;
alter table public.photos add column if not exists url        text;
alter table public.photos add column if not exists created_at timestamptz default now();

create index if not exists idx_photos_user_id on public.photos (user_id);

alter table public.photos enable row level security;

drop policy if exists "Users can manage own photos" on public.photos;
create policy "Users can manage own photos" on public.photos for all
  using (auth.uid() = user_id);


-- ============================================================
-- Done!
-- ============================================================
