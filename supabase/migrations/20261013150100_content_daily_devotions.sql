-- content.daily_devotions: same narrow, deliberate RLS exception as
-- content.word_of_day above and content.daily_verses before it. One
-- full write-up per calendar date (scheduled_for), admin-authored via
-- the admin panel's /daily-devotions page, read live by the app via
-- the publishable key. The scripture reference is structured
-- (book_id/chapter/verse_start/verse_end), not free text, so the app
-- can deep-link into the reader the same way Verse of the Day does.
create table if not exists content.daily_devotions (
  id            bigint generated always as identity primary key,
  title         text not null,
  book_id       integer references content.books(id),
  chapter       integer,
  verse_start   integer,
  verse_end     integer,
  body          text not null,
  scheduled_for date not null unique,
  created_at    timestamptz not null default now()
);

alter table content.daily_devotions enable row level security;

grant select on content.daily_devotions to anon, authenticated;

create policy "anyone can read daily_devotions" on content.daily_devotions
  for select using (true);
