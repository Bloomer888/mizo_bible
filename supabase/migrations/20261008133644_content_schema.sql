-- Canonical Bible content schema (Phase 2/3 of the plan).
--
-- This is what the admin panel edits. The Flutter app never queries this --
-- it only ever reads the local bible.db built by exporting FROM these
-- tables. Separate on purpose from any future user-data schema (bookmarks,
-- notes, etc.), which lives in its own migration later (Phase 8).
--
-- RLS is enabled with NO policies anywhere in this file, deliberately: that
-- means the publishable/anon key -- the one already in dart_define.json,
-- safe to ship in the app -- gets zero access to these tables. Only the
-- service-role key (used server-side only, inside the admin panel, never in
-- the Flutter app) can read or write here. If a future phase needs the app
-- to read any of this directly, that's an explicit policy added then, not
-- an accident of an open table.

create schema if not exists content;

-- One row per translation. Swappable by design -- see the plan's rights
-- callout. rights_status gives the licensing question a permanent home
-- instead of living only in a planning document.
create table if not exists content.translations (
  id             text primary key,            -- e.g. 'mizo_crc_2026', 'kjv_nkjv_blend'
  name           text not null,
  short_name     text not null,
  language_code  text not null,
  year           integer,
  publisher      text,
  rights_status  text not null default 'pending'
                   check (rights_status in ('confirmed','pending','print_only','public_domain')),
  rights_notes   text,
  license_text   text,
  is_bundled     boolean not null default true,
  sort_order     integer not null default 0
);

-- The 66 canonical books, translation-independent.
create table if not exists content.books (
  id             integer primary key,         -- 1..66, canonical order
  testament      text not null check (testament in ('OT','NT')),
  chapter_count  integer not null,
  osis_code      text not null unique         -- e.g. 'Gen', 'Matt'
);

-- Per-translation book names, e.g. 'Mathaia' vs 'Matthew'.
create table if not exists content.book_names (
  book_id        integer not null references content.books(id),
  translation_id text not null references content.translations(id),
  name           text not null,
  short_name     text not null,
  primary key (book_id, translation_id)
);

-- The verse text itself. updated_at/updated_by feed the audit log below.
create table if not exists content.verses (
  translation_id text not null references content.translations(id),
  book_id        integer not null references content.books(id),
  chapter        integer not null,
  verse          integer not null,
  text           text not null,
  heading        text,                        -- section heading preceding this verse
  cross_ref      text,
  updated_at     timestamptz not null default now(),
  updated_by     text,
  primary key (translation_id, book_id, chapter, verse)
);

-- Verse-alignment between one pair of translations, materialised once
-- rather than computed at runtime. a/b, not left/right -- which side a
-- translation displays on is a UI setting, not a content fact.
create table if not exists content.parallel_rows (
  pair_id    text not null,                   -- e.g. 'mizo_crc_2026|kjv_nkjv_blend'
  book_id    integer not null references content.books(id),
  chapter    integer not null,
  row_index  integer not null,
  label      text not null,                   -- '2' or '2-4'
  a_start    integer,                         -- null = this translation has no verse here
  a_end      integer,
  b_start    integer,
  b_end      integer,
  primary key (pair_id, book_id, chapter, row_index)
);

-- Who changed which verse and what it was before. Cheap insurance on a
-- sacred text that more than one person can edit.
create table if not exists content.edit_log (
  id          bigint generated always as identity primary key,
  table_name  text not null,
  row_key     text not null,
  old_value   jsonb,
  new_value   jsonb,
  edited_by   text,
  edited_at   timestamptz not null default now()
);

-- Admin-panel allow-list. Deliberately separate from "is this a signed-in
-- user" -- regular Bible-app users become auth.users rows too once Phase 9
-- ships, and must never satisfy this check.
create table if not exists content.admin_users (
  user_id     uuid primary key references auth.users(id),
  email       text not null,
  role        text not null default 'editor' check (role in ('admin','editor')),
  created_at  timestamptz not null default now()
);

alter table content.translations enable row level security;
alter table content.books        enable row level security;
alter table content.book_names   enable row level security;
alter table content.verses       enable row level security;
alter table content.parallel_rows enable row level security;
alter table content.edit_log     enable row level security;
alter table content.admin_users  enable row level security;
-- No policies defined above => no row is visible to anon or authenticated
-- roles. Only the service-role key (admin panel, server-side only) bypasses
-- RLS and can see these tables at all.
