-- Add columns that exist in the app schema but may be missing from the live playlists table.
-- Safe to run multiple times (add column if not exists).

alter table public.playlists
  add column if not exists user_id       uuid    references auth.users(id) on delete cascade;

alter table public.playlists
  add column if not exists icon          text    default 'playlist_play';

alter table public.playlists
  add column if not exists is_default    boolean default false;

alter table public.playlists
  add column if not exists is_featured   boolean default false;

alter table public.playlists
  add column if not exists visibility    text    default 'public';

alter table public.playlists
  add column if not exists creator_name  text;

alter table public.playlists
  add column if not exists places_count  int     default 0;

create index if not exists idx_playlists_user_id on public.playlists (user_id);
