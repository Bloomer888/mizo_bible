-- User-data schema (Phase 8 of the plan): the Postgres mirror of
-- user_database.dart's six tables (lib/core/db/user_database.dart) --
-- what every row eventually syncs to once its owner signs in. A
-- separate schema from content.* on purpose: this is personal data
-- (bookmarks, notes, reading history), content.* is the shared Bible
-- text, and the two have opposite access rules -- this schema is
-- read/write for the signed-in owner only, content.* is service-role
-- only.
--
-- user_id is NOT NULL here, unlike the Drift side's nullable userId --
-- a row only ever reaches this table once it has been claimed with a
-- real signed-in user_id (Phase 9: "local rows claimed by stamping
-- user_id at real sign-in"). Unclaimed local rows simply never sync.
--
-- No `dirty` column: that flag is the client's own "not yet pushed"
-- bookkeeping (see SyncableColumns' doc comment in user_database.dart)
-- and is meaningless once a row has actually arrived here.
--
-- The sync engine itself (the Dart code that reads locally-dirty rows
-- and pushes/pulls against these tables) isn't written yet -- it needs
-- a real signed-in user_id to sync against, which doesn't exist until
-- Phase 9 ships auth. This migration is the schema it will sync
-- through, same relationship Phase 7's local tables had to this one.
--
-- RLS scopes every table to auth.uid() = user_id, for the authenticated
-- role only -- anonymous Supabase auth is disabled project-wide (plan's
-- Phase 9 notes), so there's no anon policy to write.

create schema if not exists user_data;

-- id is client-generated (package:uuid's v4(), same as the Drift side),
-- so a row created offline never collides with one from another device
-- once it syncs -- no server-side default, the client always supplies
-- one at insert.
--
-- Each per-verse table carries unique (user_id, book_id, chapter,
-- verse): the local repositories already enforce "at most one row per
-- verse" themselves (toggleBookmark/setHighlight/saveNote all
-- find-or-update), so this makes that an actual guarantee the sync
-- engine can upsert against instead of an incidental client behaviour.
-- reading_history is the one exception -- append-only like its Drift
-- counterpart, so it carries no unique constraint at all.

create table if not exists user_data.bookmarks (
  id         uuid primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  book_id    integer not null,
  chapter    integer not null,
  verse      integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted    boolean not null default false,
  unique (user_id, book_id, chapter, verse)
);

create table if not exists user_data.highlights (
  id         uuid primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  book_id    integer not null,
  chapter    integer not null,
  verse      integer not null,
  color      text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted    boolean not null default false,
  unique (user_id, book_id, chapter, verse)
);

create table if not exists user_data.notes (
  id         uuid primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  book_id    integer not null,
  chapter    integer not null,
  verse      integer not null,
  content    text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted    boolean not null default false,
  unique (user_id, book_id, chapter, verse)
);

-- Append-only, like its Drift counterpart -- deliberately no unique
-- constraint. Revisiting a chapter later is a fresh entry, not an
-- update; only immediate back-to-back repeats are skipped, and that's
-- client-side logic (logChapterVisit), not something this table
-- itself enforces.
create table if not exists user_data.reading_history (
  id         uuid primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  book_id    integer not null,
  chapter    integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted    boolean not null default false
);

create table if not exists user_data.reading_progress (
  id         uuid primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  book_id    integer not null,
  chapter    integer not null,
  verse      integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted    boolean not null default false,
  unique (user_id, book_id)
);

create table if not exists user_data.settings (
  id         uuid primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  key        text not null,
  value      text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted    boolean not null default false,
  unique (user_id, key)
);

alter table user_data.bookmarks        enable row level security;
alter table user_data.highlights       enable row level security;
alter table user_data.notes            enable row level security;
alter table user_data.reading_history  enable row level security;
alter table user_data.reading_progress enable row level security;
alter table user_data.settings         enable row level security;

-- One owner-only policy per CRUD shape the app actually uses (select /
-- insert / update -- it never hard-deletes, only tombstones via update,
-- so there is no delete policy to write). The `with check` on insert
-- and update additionally stops a row being written with someone
-- else's user_id, not just from reading one.

create policy "select own bookmarks" on user_data.bookmarks
  for select using (auth.uid() = user_id);
create policy "insert own bookmarks" on user_data.bookmarks
  for insert with check (auth.uid() = user_id);
create policy "update own bookmarks" on user_data.bookmarks
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "select own highlights" on user_data.highlights
  for select using (auth.uid() = user_id);
create policy "insert own highlights" on user_data.highlights
  for insert with check (auth.uid() = user_id);
create policy "update own highlights" on user_data.highlights
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "select own notes" on user_data.notes
  for select using (auth.uid() = user_id);
create policy "insert own notes" on user_data.notes
  for insert with check (auth.uid() = user_id);
create policy "update own notes" on user_data.notes
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "select own reading_history" on user_data.reading_history
  for select using (auth.uid() = user_id);
create policy "insert own reading_history" on user_data.reading_history
  for insert with check (auth.uid() = user_id);
create policy "update own reading_history" on user_data.reading_history
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "select own reading_progress" on user_data.reading_progress
  for select using (auth.uid() = user_id);
create policy "insert own reading_progress" on user_data.reading_progress
  for insert with check (auth.uid() = user_id);
create policy "update own reading_progress" on user_data.reading_progress
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "select own settings" on user_data.settings
  for select using (auth.uid() = user_id);
create policy "insert own settings" on user_data.settings
  for insert with check (auth.uid() = user_id);
create policy "update own settings" on user_data.settings
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Schema-level grant, same 42501 reasoning as
-- content_schema_grants.sql: RLS alone doesn't grant Data API access,
-- a plain GRANT is a separate, required layer. authenticated only --
-- anon never has a real auth.uid() here since anonymous auth is
-- disabled project-wide, so granting it nothing further narrows the
-- surface for no loss of function.

grant usage on schema user_data to authenticated;
grant select, insert, update on all tables in schema user_data to authenticated;
alter default privileges in schema user_data grant select, insert, update on tables to authenticated;
