// Push notification webhook. Slug: swift-worker (dashboard name: send-push-notification).
// Called by the database triggers in supabase/migrations/20261115000006_push_webhooks.sql.
// Required secrets: WEBHOOK_SECRET, FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY.
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by the platform.
// Deploy with "Verify JWT" OFF: the x-webhook-secret header authenticates the caller instead.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { JWT } from "https://esm.sh/google-auth-library@9";

const MAX_BODY_LENGTH = 120;

// Compares every character, so timing does not reveal how much of the secret matched.
function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

serve(async (req) => {
  const expected = Deno.env.get("WEBHOOK_SECRET");
  const received = req.headers.get("x-webhook-secret") ?? "";
  if (!expected || !safeEqual(received, expected)) {
    return new Response("Unauthorized", { status: 401 });
  }

  try {
    const { table, record } = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    let targetUserIds: string[] = [];
    let title = "";
    let body = "";
    let isHighPriority = false;
    const dataPayload: Record<string, string> = { table };

    // 1. New booking: notify the driver
    if (table === "bookings") {
      const { data: offer } = await supabase
        .from("trip_offers")
        .select("driver_id")
        .eq("trip_offer_id", record.trip_offer_id)
        .single();

      if (offer) targetUserIds.push(offer.driver_id);
      title = "New Seat Booked";
      body = `A passenger booked ${record.seats_booked} seat(s) on your trip.`;
      dataPayload.booking_id = record.booking_id;
    } // 2. New message: notify the other participant(s)
    else if (table === "messages") {
      if (record.booking_id) {
        const { data: booking } = await supabase
          .from("bookings")
          .select("passenger_id, trip_offers(driver_id)")
          .eq("booking_id", record.booking_id)
          .single();

        if (booking) {
          // deno-lint-ignore no-explicit-any
          const driverId = (booking.trip_offers as any)?.driver_id;
          const recipient = record.sender_id === booking.passenger_id
            ? driverId
            : booking.passenger_id;
          if (recipient) targetUserIds.push(recipient);
        }
      } else if (record.trip_id) {
        const { data: trip } = await supabase
          .from("trips")
          .select("driver_id")
          .eq("trip_id", record.trip_id)
          .single();

        const { data: passengers } = await supabase
          .from("bookings")
          .select("passenger_id")
          .eq("trip_id", record.trip_id);

        const allUsers = [
          trip?.driver_id,
          ...(passengers?.map((p) => p.passenger_id) || []),
        ];
        targetUserIds = allUsers.filter(
          (id): id is string => Boolean(id) && id !== record.sender_id,
        );
      }

      title = "New Carpool Message";
      // Keep the lock-screen preview short.
      const text = String(record.content ?? "");
      body = text.length > MAX_BODY_LENGTH ? `${text.slice(0, MAX_BODY_LENGTH)}...` : text;
      dataPayload.message_id = record.message_id;
    } // 3. SOS alert: high-priority push to staff analysts
    else if (table === "sos_alerts") {
      const { data: staff } = await supabase
        .from("users")
        .select("usersId")
        .eq("usersRole", "staffAnalyst");

      targetUserIds = staff?.map((s) => s.usersId) || [];
      title = "EMERGENCY SOS ALERT";
      body = `SOS triggered on Trip ${record.trip_id}. Immediate attention required.`;
      isHighPriority = true;
      dataPayload.alert_id = record.alert_id;
    } else {
      return new Response("Unsupported table", { status: 400 });
    }

    targetUserIds = [...new Set(targetUserIds)];
    if (targetUserIds.length === 0) {
      return new Response("No recipients found", { status: 200 });
    }

    // Fetch FCM tokens for the recipients (users.usersId is the legacy camelCase column)
    const { data: users } = await supabase
      .from("users")
      .select("fcm_token")
      .in("usersId", targetUserIds)
      .not("fcm_token", "is", null);

    const tokens = users?.map((u) => u.fcm_token).filter(Boolean) || [];
    if (tokens.length === 0) {
      return new Response("No valid FCM tokens", { status: 200 });
    }

    // Authenticate with Google OAuth2 for the FCM HTTP v1 API
    const jwtClient = new JWT({
      email: Deno.env.get("FIREBASE_CLIENT_EMAIL"),
      key: Deno.env.get("FIREBASE_PRIVATE_KEY")!.replace(/\\n/g, "\n"),
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const authTokens = await jwtClient.authorize();

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${
      Deno.env.get("FIREBASE_PROJECT_ID")
    }/messages:send`;

    const results = await Promise.all(
      tokens.map(async (token) => {
        const res = await fetch(fcmUrl, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${authTokens.access_token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title, body },
              data: dataPayload,
              android: { priority: isHighPriority ? "high" : "normal" },
            },
          }),
        });
        if (res.status === 404) {
          // FCM reports an unregistered (stale) token: stop sending to it.
          await supabase.from("users").update({ fcm_token: null }).eq("fcm_token", token);
        } else if (!res.ok) {
          console.error("FCM send failed with status", res.status);
        }
        return res.ok;
      }),
    );

    return new Response(JSON.stringify({ sent: results.filter(Boolean).length }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    // Details go to the function logs, not to the caller.
    console.error("send-push-notification failed:", err);
    return new Response(JSON.stringify({ error: "Internal error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
