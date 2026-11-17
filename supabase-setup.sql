-- Run this once in the Supabase SQL Editor.
-- Then set supabaseConfig.url and supabaseConfig.anonKey near the top of the
-- inline script in index.html. Use the project's anon/publishable key only,
-- never a service-role key. Visitors can submit one rating per photo/browser.
-- Browser identifiers are a light duplicate-vote deterrent, not strong
-- anti-abuse protection; production-grade vote integrity needs server checks.

create table if not exists public.photo_ratings (
  photo_id text not null check (char_length(photo_id) between 1 and 200),
  voter_id uuid not null,
  rating smallint not null check (rating between 1 and 5),
  created_at timestamptz not null default now(),
  primary key (photo_id, voter_id)
);

alter table public.photo_ratings enable row level security;
revoke all on public.photo_ratings from anon, authenticated;
grant select, insert on public.photo_ratings to anon, authenticated;

drop policy if exists "Anyone can read photo ratings" on public.photo_ratings;
create policy "Anyone can read photo ratings"
  on public.photo_ratings for select
  to anon, authenticated
  using (true);

drop policy if exists "Anyone can submit photo ratings" on public.photo_ratings;
create policy "Anyone can submit photo ratings"
  on public.photo_ratings for insert
  to anon, authenticated
  with check (
    char_length(photo_id) between 1 and 200
    and rating between 1 and 5
  );

create or replace view public.photo_rating_summary
with (security_invoker = true)
as
select
  photo_id,
  count(*)::integer as rating_count,
  round(avg(rating)::numeric, 1) as average_rating
from public.photo_ratings
group by photo_id;

revoke all on public.photo_rating_summary from anon, authenticated;
grant select on public.photo_rating_summary to anon, authenticated;
