-- Verse of the Day's curated reference list, admin-editable (2026-10-13).
-- Unlike every other content.* table, this one needs a real exception to
-- "service-role only": bible.db (the rest of content.*'s delivery
-- mechanism) is copy-once-per-install and rebuilt wholesale only on a new
-- app release (see lib/core/db/bible_database.dart and
-- tool/export_bible_db.py) -- fine for verse *text*, which matches the
-- "Bible is always local" design, but wrong for a list that's meant to be
-- refreshed by a human over time. So the app fetches this one table live,
-- via the publishable (anon) key, instead of through the bible.db
-- pipeline -- see verse_of_the_day.dart's syncDailyVerseReferences. Verse
-- *text* itself is still only ever read from the local bible.db; this
-- table only ever holds (book_id, chapter, verse) references, never text.
--
-- No service-role grant needed here -- the previous migration's
-- `alter default privileges in schema content grant all on tables to
-- service_role` already covers any new table in this schema automatically.

create table if not exists content.daily_verses (
  id          bigint generated always as identity primary key,
  book_id     integer not null references content.books(id),
  chapter     integer not null,
  verse       integer not null,
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now()
);

alter table content.daily_verses enable row level security;

-- The one deliberate crack in "content schema is service-role only" --
-- scoped to exactly this table, read-only. Every other content.* table's
-- lockdown (RLS enabled, zero policies, no anon/authenticated grant) is
-- untouched.
grant usage on schema content to anon, authenticated;
grant select on content.daily_verses to anon, authenticated;

create policy "anyone can read daily_verses" on content.daily_verses
  for select using (true);
