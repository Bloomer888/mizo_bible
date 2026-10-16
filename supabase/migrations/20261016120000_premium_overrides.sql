-- A narrow, admin-managed comp/allowlist mechanism for Premium access,
-- independent of RevenueCat -- for staff, testers, and anyone else the
-- admin wants to grant free access to before (or alongside) real
-- billing. Lives in user_data, not content, since this is per-user
-- entitlement data, not shared Bible content.
--
-- Deliberately asymmetric RLS: a signed-in user can read ONLY their own
-- row (so the app can check "am I comped" without ever seeing who else
-- is), but only the service-role client (the admin panel) can insert,
-- update, or delete -- there is no authenticated insert/update/delete
-- policy at all, so a user can never grant themselves (or anyone else)
-- premium by writing to this table directly.
create table if not exists user_data.premium_overrides (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  email       text not null,
  note        text,
  granted_by  text,
  granted_at  timestamptz not null default now()
);

alter table user_data.premium_overrides enable row level security;

create policy "users can read their own premium override" on user_data.premium_overrides
  for select using (auth.uid() = user_id);

grant select on user_data.premium_overrides to authenticated;
