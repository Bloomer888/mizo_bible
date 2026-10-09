-- The previous migration created content.* and enabled RLS on every table,
-- but never granted the Data API roles access to the schema itself. RLS
-- bypass (what the service_role key gets) is a separate permission layer
-- from a plain schema/table GRANT -- without this, every request hits
-- Postgres error 42501 ("permission denied for schema content") before
-- RLS is even evaluated.
--
-- Only service_role gets these grants, on purpose: anon/authenticated
-- have no RLS policies on any content.* table (previous migration), so
-- granting them schema usage too would still leave them reading nothing
-- -- but there's no reason to widen the surface for no benefit.

grant usage on schema content to service_role;
grant all on all tables in schema content to service_role;
grant all on all sequences in schema content to service_role;

-- So tables added to this schema later don't need a repeat of this
-- migration.
alter default privileges in schema content grant all on tables to service_role;
alter default privileges in schema content grant all on sequences to service_role;
