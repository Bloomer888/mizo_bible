-- Reading history stays phone-only, for every user, free or Premium --
-- a deliberate decision (2026-10-11), not an oversight: unlike
-- bookmarks/highlights/notes/reading_progress/settings, it never
-- reaches this backend at all now, so there's nothing left here for it
-- to sync through. Dropping the table (not just leaving it unused)
-- keeps the schema honest about that -- a table nothing ever writes to
-- would just be a stale claim about what this app does.
--
-- Pre-launch, no real user rows exist yet, so there's no data-loss
-- concern in dropping it outright rather than archiving first.
--
-- The reading streak feature (Home tab) derives entirely from the
-- Drift-only, local reading_history table in user_database.dart, which
-- this migration does not touch -- only the Postgres mirror goes away.

drop table if exists user_data.reading_history;
