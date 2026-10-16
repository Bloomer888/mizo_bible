-- Same gap that 20261009044500_content_schema_grants.sql fixed for the
-- content schema, just never hit until now: user_data.* has RLS enabled
-- everywhere, but RLS bypass (what the service_role key gets) is a
-- separate permission layer from a plain schema/table GRANT. Every
-- OTHER user_data.* access so far has gone through the authenticated
-- role (the Flutter app's own sync, which already has explicit grants
-- from 20261010090000_user_data_schema.sql), so this gap sat unnoticed
-- until the admin panel's new Premium Overrides page became the first
-- thing to ever query user_data.* with the service-role key -- it fails
-- with Postgres error 42501 ("permission denied for schema user_data")
-- before RLS is even evaluated, surfacing in Next.js as a generic
-- "This page couldn't load."
--
-- Only service_role gets these grants, same reasoning as the content
-- schema's own grants migration: anon already has nothing here
-- (explicitly revoked in 20261012114400_user_data_hardening.sql), and
-- authenticated's access is scoped by RLS policies already in place --
-- widening either of those isn't needed to fix this.

grant usage on schema user_data to service_role;
grant all on all tables in schema user_data to service_role;
grant all on all sequences in schema user_data to service_role;

alter default privileges in schema user_data grant all on tables to service_role;
alter default privileges in schema user_data grant all on sequences to service_role;
