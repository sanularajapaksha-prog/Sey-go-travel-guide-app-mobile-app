-- Add latitude/longitude columns to placses table if not already present
alter table public.placses
  add column if not exists latitude  double precision null;

alter table public.placses
  add column if not exists longitude double precision null;

-- Index for geo queries
create index if not exists idx_placses_lat_lng
  on public.placses (latitude, longitude);
