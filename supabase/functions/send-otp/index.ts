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

// Module-level rate limiting by IP (max 10 requests per 10 minutes)
interface IpRecord {
  count: number;
  resetAt: number;
}
const ipRateLimits = new Map<string, IpRecord>();

function checkIpRateLimit(ip: string): boolean {
  const now = Date.now();
  const windowMs = 10 * 60 * 1000;

  // Prune expired entries each call
  for (const [key, value] of ipRateLimits.entries()) {
    if (now > value.resetAt) {
      ipRateLimits.delete(key);
    }
  }

  const record = ipRateLimits.get(ip);
  if (!record) {
    ipRateLimits.set(ip, { count: 1, resetAt: now + windowMs });
    return true;
  }

  if (record.count >= 10) {
    return false;
  }

  record.count += 1;
  return true;
}

serve(async (req) => {
  const corsHeaders = getCorsHeaders(req);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Check IP rate limit
    const clientIp =
      req.headers.get("x-forwarded-for")?.split(",")[0].trim() ||
      req.headers.get("cf-connecting-ip") ||
      "unknown";

    if (!checkIpRateLimit(clientIp)) {
      return new Response(
        JSON.stringify({ error: "Too many requests from this IP. Try again later." }),
        {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { email } = await req.json();

    if (!email || !email.includes("@")) {
      return new Response(JSON.stringify({ error: "Invalid email address" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    // Supabase service-role client (bypasses RLS)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Rate limit per email: count password_resets created in last 10 minutes
    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000).toISOString();
    const { count: resetCount, error: countError } = await supabase
      .from("password_resets")
      .select("*", { count: "exact", head: true })
      .eq("email", normalizedEmail)
      .gte("created_at", tenMinutesAgo);

    if (countError) throw countError;

    if (resetCount !== null && resetCount >= 3) {
      return new Response(
        JSON.stringify({ error: "Too many reset requests. Try again later." }),
        {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Generic success response to prevent email enumeration
    const genericSuccessResponse = () =>
      new Response(
        JSON.stringify({
          success: true,
          message: "If that email is registered, a password reset code has been sent.",
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );

    // Verify user exists in Supabase Auth before sending OTP (anti-enumeration: still return 200)
    const { data: usersData, error: usersError } =
      await supabase.auth.admin.listUsers();
    if (usersError) throw usersError;

    const userExists = usersData.users.some(
      (u: any) => u.email?.toLowerCase() === normalizedEmail
    );

    if (!userExists) {
      return genericSuccessResponse();
    }

    // Secure random 6-digit OTP using crypto.getRandomValues
    const randomBuffer = new Uint32Array(1);
    crypto.getRandomValues(randomBuffer);
    const otp = (100000 + (randomBuffer[0] % 900000)).toString();

    // Hash the OTP before storing (SHA-256)
    const encoder = new TextEncoder();
    const data = encoder.encode(otp);
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const otpHash = hashArray
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    // Delete any existing unused codes for this email first
    await supabase
      .from("password_resets")
      .delete()
      .eq("email", normalizedEmail)
      .eq("used", false);

    // Insert the new OTP
    const { error: insertError } = await supabase.from("password_resets").insert({
      email: normalizedEmail,
      otp_hash: otpHash,
      expires_at: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
    });

    if (insertError) throw insertError;

    // Send email via Resend API
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) throw new Error("RESEND_API_KEY not configured");

    const emailRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "DC Motorshop <onboarding@resend.dev>",
        to: [normalizedEmail],
        subject: "Your Password Reset Code",
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #0C101B; color: #ffffff; border-radius: 12px;">
            <h2 style="color: #3B82F6; margin-bottom: 8px;">DC Motorshop &amp; Accessories</h2>
            <p style="color: #9CA3AF; margin-bottom: 32px;">Password Reset Request</p>
            <p style="color: #ffffff;">Use the code below to reset your password. It expires in <strong>15 minutes</strong>.</p>
            <div style="background: #1E293B; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0;">
              <span style="font-size: 48px; font-weight: 800; letter-spacing: 12px; color: #3B82F6;">${otp}</span>
            </div>
            <p style="color: #64748B; font-size: 13px;">If you did not request this code, ignore this email.</p>
          </div>
        `,
      }),
    });

    if (!emailRes.ok) {
      const errBody = await emailRes.text();
      throw new Error(`Resend API error: ${errBody}`);
    }

    return genericSuccessResponse();
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
