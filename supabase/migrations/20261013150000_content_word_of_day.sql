-- content.word_of_day: a second, deliberate narrow exception to
-- "content.* is service-role only" -- same shape and reasoning as
-- content.daily_verses (20261013120000_content_daily_verses.sql).
-- One entry per calendar date (scheduled_for), admin-authored via the
-- admin panel's /word-of-day page, read live by the app via the
-- publishable key. Pastor-provided content -- no seed data here.
create table if not exists content.word_of_day (
  id            bigint generated always as identity primary key,
  word          text not null,
  meaning       text not null,
  scheduled_for date not null unique,
  created_at    timestamptz not null default now()
);

alter table content.word_of_day enable row level security;

-- schema-level `grant usage on schema content to anon, authenticated`
-- already exists from 20261013120000_content_daily_verses.sql.
grant select on content.word_of_day to anon, authenticated;

create policy "anyone can read word_of_day" on content.word_of_day
  for select using (true);
