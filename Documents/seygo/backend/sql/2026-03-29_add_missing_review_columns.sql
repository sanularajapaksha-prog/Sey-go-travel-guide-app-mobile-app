-- Add missing columns to reviews table
-- Safe to run multiple times (uses IF NOT EXISTS)

alter table public.reviews add column if not exists rejection_reason text;
alter table public.reviews add column if not exists approved_at      timestamptz;
alter table public.reviews add column if not exists approved_by      text;

-- Ensure RLS is enabled
alter table public.reviews enable row level security;

-- Recreate insert policy to make sure it exists
drop policy if exists "Users can insert reviews" on public.reviews;
create policy "Users can insert reviews" on public.reviews for insert
  with check (auth.uid() = user_id);

-- Allow service role full access (bypass RLS for backend)
drop policy if exists "Service role full access to reviews" on public.reviews;
