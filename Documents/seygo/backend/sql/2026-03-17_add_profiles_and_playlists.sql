-- =============================================================================
-- profiles table
-- Stores extended user profile data beyond what Supabase auth provides.
-- =============================================================================

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

create policy "Users can read own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Auto-update updated_at on row change
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();


-- =============================================================================
-- playlists table
-- A playlist is an ordered collection of places, owned by a user.
-- is_featured / visibility allow admin-curated public playlists.
-- =============================================================================

create table if not exists public.playlists (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid references auth.users(id) on delete cascade,
  name           text not null,
  description    text,
  icon           text default 'playlist_play',
  status         text default 'active',      -- active | archived
  visibility     text default 'public',      -- public | private
  is_featured    boolean default false,
  is_default     boolean default false,
  creator_name   text,
  places_count   int default 0,
  created_at     timestamptz default now()
);

create index if not exists idx_playlists_user_id     on public.playlists (user_id);
create index if not exists idx_playlists_status      on public.playlists (status);
create index if not exists idx_playlists_is_featured on public.playlists (is_featured);

alter table public.playlists enable row level security;

-- Anyone can read active public playlists
create policy "Public playlists are readable by all"
  on public.playlists for select
  using (status = 'active' and visibility = 'public');

-- Owners can read all their own playlists (including private)
create policy "Owners can read own playlists"
  on public.playlists for select
  using (auth.uid() = user_id);

create policy "Owners can insert playlists"
  on public.playlists for insert
  with check (auth.uid() = user_id);

create policy "Owners can update playlists"
  on public.playlists for update
  using (auth.uid() = user_id);

create policy "Owners can delete playlists"
  on public.playlists for delete
  using (auth.uid() = user_id);


-- =============================================================================
-- playlist_places junction table
-- Links a playlist to places (by place_id from the places table).
-- sort_order controls display order within a playlist.
-- =============================================================================

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

-- Unique: a place can only appear once per playlist
create unique index if not exists uq_playlist_places
  on public.playlist_places (playlist_id, place_id);

alter table public.playlist_places enable row level security;

-- Allow reading if the parent playlist is readable
create policy "Playlist places inherit playlist read access"
  on public.playlist_places for select
  using (
    exists (
      select 1 from public.playlists pl
      where pl.id = playlist_id
        and (
          (pl.status = 'active' and pl.visibility = 'public')
          or pl.user_id = auth.uid()
        )
    )
  );

create policy "Playlist owners can manage places"
  on public.playlist_places for all
  using (
    exists (
      select 1 from public.playlists pl
      where pl.id = playlist_id
        and pl.user_id = auth.uid()
    )
  );


-- =============================================================================
-- Helper: keep playlists.places_count in sync automatically
-- =============================================================================

create or replace function public.sync_playlist_places_count()
returns trigger language plpgsql security definer as $$
begin
  if TG_OP = 'INSERT' then
    update public.playlists
      set places_count = places_count + 1
      where id = new.playlist_id;
  elsif TG_OP = 'DELETE' then
    update public.playlists
      set places_count = greatest(places_count - 1, 0)
      where id = old.playlist_id;
  end if;
  return null;
end;
$$;

create trigger playlist_places_count_sync
  after insert or delete on public.playlist_places
  for each row execute function public.sync_playlist_places_count();
