import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const ALLOWED_ORIGINS = [
  "https://dc-mshop.vercel.app",
  "http://localhost:3000",
];

function getCorsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("origin");
  const headers: Record<string, string> = {
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };

  if (origin && ALLOWED_ORIGINS.includes(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
  }

  return headers;
}

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { email, otp } = await req.json();

    if (!email || !otp || typeof otp !== "string" || otp.length !== 6) {
      return new Response(
        JSON.stringify({ error: "Email and valid 6-digit code are required." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const normalizedEmail = email.trim().toLowerCase();

    // Hash the submitted OTP using SHA-256
    const encoder = new TextEncoder();
    const data = encoder.encode(otp.trim());
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const otpHash = hashArray
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    // Supabase service-role client (bypasses RLS to query password_resets)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Look up latest unused reset row matching email and hash
    const { data: records, error: fetchError } = await supabase
      .from("password_resets")
      .select("id, expires_at, used")
      .eq("email", normalizedEmail)
      .eq("otp_hash", otpHash)
      .eq("used", false)
      .order("created_at", { ascending: false })
      .limit(1);

    if (fetchError) throw fetchError;

    if (!records || records.length === 0) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired code. Please try again." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const record = records[0];

    // Check expiry
    if (new Date(record.expires_at).getTime() < Date.now()) {
      return new Response(
        JSON.stringify({ error: "Code has expired. Please request a new one." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Mark used = true
    const { error: updateError } = await supabase
      .from("password_resets")
      .update({ used: true })
      .eq("id", record.id);

    if (updateError) throw updateError;

    // Generate a secure reset ticket to pass to reset-password
    // Use the record id as the reset ticket
    return new Response(
      JSON.stringify({
        success: true,
        reset_ticket: record.id,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
