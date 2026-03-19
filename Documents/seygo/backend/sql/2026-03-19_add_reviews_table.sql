create table if not exists public.reviews (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid references auth.users(id) on delete cascade,
  place_id       text,
  place_name     text not null,
  rating         int check (rating between 1 and 5),
  review_text    text,
  status         text default 'pending',   -- pending | approved
  user_name      text,
  user_badge     text default 'Explorer',
  likes_count    int default 0,
  comments_count int default 0,
  created_at     timestamptz default now()
);

create index if not exists idx_reviews_user_id on public.reviews (user_id);
create index if not exists idx_reviews_status  on public.reviews (status);
create index if not exists idx_reviews_place_id on public.reviews (place_id);
