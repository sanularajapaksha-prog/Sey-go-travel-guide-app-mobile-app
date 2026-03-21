-- =============================================================================
-- Fix playlist_places.playlist_id type mismatch
--
-- Problem: The original migration defined playlist_places.playlist_id as UUID,
-- but in production playlists.id is bigint (auto-increment integer).
-- PostgreSQL cannot create a UUID FK to a bigint column, so either the table
-- was never created or every INSERT fails with "invalid input syntax for type uuid".
--
-- Fix: Change playlist_id and place_id to text so this table works regardless
-- of whether playlists.id is UUID or bigint.
-- =============================================================================

-- Drop old table (and its triggers/policies) if it exists.
drop table if exists public.playlist_places cascade;

create table public.playlist_places (
  id           uuid primary key default gen_random_uuid(),
  playlist_id  text not null,          -- text: accepts both UUID and bigint strings
  place_id     text not null,          -- text: accepts both Google Place IDs and bigint DB ids
  notes        text,
  distance_km  float,
  sort_order   int  default 0,
  added_at     timestamptz default now()
);

create index if not exists idx_playlist_places_playlist_id on public.playlist_places (playlist_id);
create index if not exists idx_playlist_places_place_id    on public.playlist_places (place_id);

-- Prevent the same place appearing twice in a playlist
create unique index if not exists uq_playlist_places
  on public.playlist_places (playlist_id, place_id);

alter table public.playlist_places enable row level security;

-- Anyone can read playlist places if the parent playlist is public
create policy "Playlist places inherit playlist read access"
  on public.playlist_places for select
  using (
    exists (
      select 1 from public.playlists pl
      where pl.id::text = playlist_id
        and (
          (pl.status = 'active' and pl.visibility = 'public')
          or pl.user_id = auth.uid()
        )
    )
  );

-- Owners can insert / update / delete their playlist places
create policy "Playlist owners can manage places"
  on public.playlist_places for all
  using (
    exists (
      select 1 from public.playlists pl
      where pl.id::text = playlist_id
        and pl.user_id = auth.uid()
    )
  );

-- Keep playlists.places_count in sync automatically
create or replace function public.sync_playlist_places_count()
returns trigger language plpgsql security definer as $$
begin
  if TG_OP = 'INSERT' then
    update public.playlists
      set places_count = places_count + 1
      where id::text = new.playlist_id;
  elsif TG_OP = 'DELETE' then
    update public.playlists
      set places_count = greatest(places_count - 1, 0)
      where id::text = old.playlist_id;
  end if;
  return null;
end;
$$;

drop trigger if exists playlist_places_count_sync on public.playlist_places;
create trigger playlist_places_count_sync
  after insert or delete on public.playlist_places
  for each row execute function public.sync_playlist_places_count();
