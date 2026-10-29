-- A permanent, append-only ledger of every real purchase event RevenueCat
-- sees across both stores (Google Play + App Store) -- the source of
-- truth for revenue reporting and GST filing, since neither store nor
-- RevenueCat itself keeps a queryable record inside this project. Fed by
-- a RevenueCat webhook -> Edge Function, never written to directly by
-- the app or any user.
--
-- Its own schema, not user_data -- unlike premium_overrides, a signed-in
-- user has no reason to ever read their own row here (this is for the
-- admin/accounting side only), so there's no RLS policy to write at
-- all: same service-role-only lockdown as the content schema.
create schema if not exists billing;

create table if not exists billing.transactions (
  id                      bigint generated always as identity primary key,
  -- RevenueCat's own event id -- webhooks can retry/duplicate-deliver,
  -- so this is what makes re-inserting the same event a no-op instead
  -- of double-counting revenue.
  revenuecat_event_id     text not null unique,
  event_type              text not null,
  app_user_id             text not null,
  product_id              text,
  store                   text,
  price                   numeric,
  currency                text,
  price_in_purchased_currency numeric,
  period_type             text,
  -- SANDBOX vs PRODUCTION -- the one field every revenue total query
  -- must filter on, so test/RevenueCat-sandbox purchases never get
  -- counted as real income.
  environment             text,
  purchased_at            timestamptz,
  expiration_at           timestamptz,
  -- The full webhook payload, verbatim -- an audit trail, and a
  -- fallback for any field a future report needs that wasn't worth
  -- its own column today.
  raw_payload              jsonb not null,
  received_at              timestamptz not null default now()
);

create index if not exists transactions_app_user_id_idx on billing.transactions (app_user_id);
create index if not exists transactions_purchased_at_idx on billing.transactions (purchased_at);

alter table billing.transactions enable row level security;
-- Deliberately zero policies -- nobody using the anon/authenticated
-- Data API role, including the signed-in user this row is about, can
-- read or write this table at all. Only the Edge Function (service
-- role, bypasses RLS entirely) and the admin panel (also service role)
-- ever touch it.

grant usage on schema billing to service_role;
grant all on all tables in schema billing to service_role;
grant all on all sequences in schema billing to service_role;

alter default privileges in schema billing grant all on tables to service_role;
alter default privileges in schema billing grant all on sequences to service_role;
