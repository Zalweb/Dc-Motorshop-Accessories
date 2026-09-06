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
    const body = await req.json();
    const { email, new_password, reset_ticket, otp } = body;

    if (!email || !new_password || new_password.length < 8) {
      return new Response(
        JSON.stringify({
          error: "Email and new password (min 8 characters) are required.",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!reset_ticket && !otp) {
      return new Response(
        JSON.stringify({
          error: "Reset ticket or OTP is required to reset password.",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const normalizedEmail = email.trim().toLowerCase();

    // Supabase service-role client (bypasses RLS)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    let verified = false;

    // Option 1: Verified via reset_ticket (from verify-otp)
    if (reset_ticket) {
      const { data: ticketRecord, error: ticketError } = await supabase
        .from("password_resets")
        .select("id, email, expires_at, created_at, used")
        .eq("id", reset_ticket)
        .eq("email", normalizedEmail)
        .maybeSingle();

      if (ticketError) throw ticketError;

      if (ticketRecord) {
        // Reset ticket is valid within 30 minutes of creation
        const createdAt = new Date(ticketRecord.created_at).getTime();
        const thirtyMinMs = 30 * 60 * 1000;
        if (Date.now() - createdAt <= thirtyMinMs) {
          verified = true;
        }
      }
    }

    // Option 2: Direct OTP verification fallback
    if (!verified && otp && typeof otp === "string" && otp.length === 6) {
      const encoder = new TextEncoder();
      const data = encoder.encode(otp.trim());
      const hashBuffer = await crypto.subtle.digest("SHA-256", data);
      const hashArray = Array.from(new Uint8Array(hashBuffer));
      const otpHash = hashArray
        .map((b) => b.toString(16).padStart(2, "0"))
        .join("");

      const { data: records, error: fetchError } = await supabase
        .from("password_resets")
        .select("id, expires_at, used")
        .eq("email", normalizedEmail)
        .eq("otp_hash", otpHash)
        .order("created_at", { ascending: false })
        .limit(1);

      if (fetchError) throw fetchError;

      if (records && records.length > 0) {
        const record = records[0];
        if (new Date(record.expires_at).getTime() >= Date.now()) {
          verified = true;
          // Ensure it's marked used
          await supabase
            .from("password_resets")
            .update({ used: true })
            .eq("id", record.id);
        }
      }
    }

    if (!verified) {
      return new Response(
        JSON.stringify({ error: "Invalid, expired, or unverified reset request." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Locate the user in Supabase Auth
    const { data: usersData, error: usersError } =
      await supabase.auth.admin.listUsers();
    if (usersError) throw usersError;

    const user = usersData.users.find(
      (u: any) => u.email?.toLowerCase() === normalizedEmail
    );

    if (!user) {
      return new Response(
        JSON.stringify({ error: "User account not found." }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Update the user's password via Supabase Auth Admin
    const { error: updateAuthError } =
      await supabase.auth.admin.updateUserById(user.id, {
        password: new_password,
      });

    if (updateAuthError) throw updateAuthError;

    // Clean up all password resets for this user after successful change
    await supabase
      .from("password_resets")
      .delete()
      .eq("email", normalizedEmail);

    return new Response(
      JSON.stringify({
        success: true,
        message: "Password updated successfully.",
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
