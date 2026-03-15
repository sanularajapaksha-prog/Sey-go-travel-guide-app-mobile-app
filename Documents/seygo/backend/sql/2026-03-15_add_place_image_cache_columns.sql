alter table public.placses
  add column if not exists image_url text null;

alter table public.placses
  add column if not exists image_source text null;

alter table public.placses
  add column if not exists photo_last_checked timestamptz null;

create index if not exists idx_placses_photo_last_checked
  on public.placses (photo_last_checked);
