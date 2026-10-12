-- Reading plan progress (Premium feature, 2026-10-12): unlike
-- reading_history, this table *does* sync -- "pick up your plan on
-- another device" is a genuine fit for sync, not the privacy concern
-- reading history was (see the migration that dropped
-- user_data.reading_history for that reasoning). Same shape and same
-- RLS pattern as every other table in this schema -- see
-- 20261010090000_user_data_schema.sql's own header comment for the
-- conventions this follows (client-generated uuid id, user_id not
-- null here unlike the Drift side's nullable userId, no `dirty`
-- column, tombstone-only deletes).
--
-- One row per (user, plan) -- completed_days_csv holds the whole
-- day-completion state as a comma-separated list of day numbers
-- (e.g. "1,2,3,7"), matching exactly what the Drift side stores, so
-- the plain column-for-column sync in sync_repository.dart needs no
-- translation in either direction. A real child table (one row per
-- completed day) would be more "normalized," but progress is always
-- read and written as a whole for the active plan, never queried
-- day-by-day, so there is no join this would ever need to support.

create table if not exists user_data.reading_plan_progress (
  id                  uuid primary key,
  user_id             uuid not null references auth.users(id) on delete cascade,
  plan_id             text not null,
  started_at          timestamptz not null default now(),
  completed_days_csv  text not null default '',
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted             boolean not null default false,
  unique (user_id, plan_id)
);

alter table user_data.reading_plan_progress enable row level security;

create policy "select own reading_plan_progress" on user_data.reading_plan_progress
  for select using (auth.uid() = user_id);
create policy "insert own reading_plan_progress" on user_data.reading_plan_progress
  for insert with check (auth.uid() = user_id);
create policy "update own reading_plan_progress" on user_data.reading_plan_progress
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

grant select, insert, update on user_data.reading_plan_progress to authenticated;
