// Receives RevenueCat's webhook calls (configured in the RevenueCat
// dashboard -- Project Settings > Integrations > Webhooks) and logs
// every purchase event into billing.transactions. This is the only
// writer that table ever has.
//
// RevenueCat's docs: https://www.revenuecat.com/docs/integrations/webhooks

import { createClient } from "jsr:@supabase/supabase-js@2";

// Set via `supabase secrets set REVENUECAT_WEBHOOK_SECRET=...` -- must
// match the "Authorization header value" configured on the webhook in
// RevenueCat's dashboard exactly, or anyone who finds this function's
// URL could insert fake transactions.
const webhookSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  // The service-role key is injected automatically into every Edge
  // Function's environment -- never set by hand, never the same value
  // as the app's publishable key.
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

function msToIso(ms: number | null | undefined): string | null {
  return typeof ms === "number" ? new Date(ms).toISOString() : null;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  if (webhookSecret && req.headers.get("Authorization") !== webhookSecret) {
    return new Response("Unauthorized", { status: 401 });
  }

  let body: { event?: Record<string, unknown> };
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  const event = body.event;
  if (!event || typeof event.id !== "string" || typeof event.type !== "string" || typeof event.app_user_id !== "string") {
    // Missing the fields this table requires NOT NULL -- RevenueCat
    // sends a few housekeeping event types (e.g. TEST) that may not
    // look like this; acknowledge with 200 so it isn't retried forever,
    // but don't attempt to insert a row that would just fail.
    return new Response("Ignored: missing required event fields", { status: 200 });
  }

  const { error } = await supabase.schema("billing").from("transactions").upsert(
    {
      revenuecat_event_id: event.id,
      event_type: event.type,
      app_user_id: event.app_user_id,
      product_id: typeof event.product_id === "string" ? event.product_id : null,
      store: typeof event.store === "string" ? event.store : null,
      price: typeof event.price === "number" ? event.price : null,
      currency: typeof event.currency === "string" ? event.currency : null,
      price_in_purchased_currency:
        typeof event.price_in_purchased_currency === "number" ? event.price_in_purchased_currency : null,
      period_type: typeof event.period_type === "string" ? event.period_type : null,
      environment: typeof event.environment === "string" ? event.environment : null,
      purchased_at: msToIso(event.purchased_at_ms as number | undefined),
      expiration_at: msToIso(event.expiration_at_ms as number | undefined),
      raw_payload: body,
    },
    { onConflict: "revenuecat_event_id", ignoreDuplicates: true },
  );

  if (error) {
    console.error("Failed to log billing event:", error);
    return new Response("Database error", { status: 500 });
  }

  return new Response("OK", { status: 200 });
});
