// RevenueCat Webhook → Supabase plan_type senkronizasyonu
//
// Amaç: plan_type (premium/free) artık istemciden yazılmıyor. RevenueCat, abonelik
// olaylarını bu fonksiyona POST eder; fonksiyon service_role ile yetkili biçimde
// public.users.plan_type'ı günceller. Böylece kullanıcı kendini premium yapamaz.
//
// Güvenlik: RevenueCat dashboard'da ayarlanan Authorization header değeri, burada
// REVENUECAT_WEBHOOK_SECRET ile karşılaştırılır. Eşleşmezse 401.
//
// Eşleme: app_user_id = Supabase user UUID (PurchaseService.login her girişte
// Supabase user.id.uuidString ile logIn çağırıyor). Anonim RevenueCat id'leri atlanır.
//
// Deploy: supabase functions deploy revenuecat-webhook --no-verify-jwt
//   (RevenueCat Supabase JWT göndermez; kimlik doğrulama secret ile yapılır.)

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Entitlement'ı kaldıran olaylar (süresiz/non-renewing satın almalar için).
const REVOKING_TYPES = new Set([
  "EXPIRATION",
  "REFUND",
  "SUBSCRIPTION_PAUSED",
]);

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const expectedSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
  const auth = req.headers.get("Authorization");
  if (!expectedSecret || auth !== expectedSecret) {
    return new Response("Unauthorized", { status: 401 });
  }

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return new Response("Bad JSON", { status: 400 });
  }

  const event = payload?.event as Record<string, unknown> | undefined;
  if (!event) {
    return new Response("No event", { status: 200 });
  }

  const type = String(event.type ?? "");
  if (type === "TEST") {
    return new Response(JSON.stringify({ ok: true, test: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  const appUserId = String(event.app_user_id ?? "");
  if (!UUID_RE.test(appUserId)) {
    // Anonim / eşleştirilemeyen kullanıcı → sessizce geç (RevenueCat retry storm'u önle).
    return new Response(
      JSON.stringify({ ok: true, skipped: "non-uuid app_user_id" }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  }

  // Premium mi? Abonelikler için expiration zamanı otoritedir; süresiz satın
  // almalar (expiration null) için olay tipine bakılır.
  const expMs = event.expiration_at_ms as number | null | undefined;
  let isPremium: boolean;
  if (expMs === null || expMs === undefined) {
    isPremium = !REVOKING_TYPES.has(type);
  } else {
    isPremium = Number(expMs) > Date.now();
  }
  const planType = isPremium ? "premium" : "free";

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    console.error("Missing SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY");
    return new Response("Server misconfigured", { status: 500 });
  }

  // service_role RLS ve kolon yetkilerini bypass eder → plan_type yazılabilir.
  const res = await fetch(
    `${supabaseUrl}/rest/v1/users?id=eq.${appUserId}`,
    {
      method: "PATCH",
      headers: {
        "apikey": serviceKey,
        "Authorization": `Bearer ${serviceKey}`,
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
      },
      body: JSON.stringify({ plan_type: planType }),
    },
  );

  if (!res.ok) {
    const detail = await res.text();
    console.error(`plan_type update failed (${res.status}): ${detail}`);
    return new Response("DB update failed", { status: 500 });
  }

  return new Response(
    JSON.stringify({ ok: true, user: appUserId, plan_type: planType, event: type }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
