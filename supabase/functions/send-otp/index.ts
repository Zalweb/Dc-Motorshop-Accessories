import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { email } = await req.json();

    if (!email || !email.includes("@")) {
      return new Response(JSON.stringify({ error: "Invalid email address" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Generate a 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Hash the OTP before storing (simple SHA-256)
    const encoder = new TextEncoder();
    const data = encoder.encode(otp);
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const otpHash = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

    // Store in Supabase (service role — bypasses RLS)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Verify the user exists in Supabase Auth before sending OTP
    const { data: usersData, error: usersError } = await supabase.auth.admin.listUsers();
    if (usersError) throw usersError;

    const userExists = usersData.users.some(
      (u: any) => u.email?.toLowerCase() === email.toLowerCase()
    );

    if (!userExists) {
      return new Response(
        JSON.stringify({ error: "No account found with that email address." }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Delete any existing unused codes for this email first
    await supabase
      .from("password_resets")
      .delete()
      .eq("email", email.toLowerCase())
      .eq("used", false);

    // Insert the new OTP
    const { error: insertError } = await supabase.from("password_resets").insert({
      email: email.toLowerCase(),
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
        to: [email],
        subject: "Your Password Reset Code",
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #0C101B; color: #ffffff; border-radius: 12px;">
            <h2 style="color: #3B82F6; margin-bottom: 8px;">DC Motorshop &amp; Accessories</h2>
            <p style="color: #9CA3AF; margin-bottom: 32px;">Password Reset Request</p>
            <p style="color: #ffffff;">Use the code below to reset your password. It expires in <strong>15 minutes</strong>.</p>
            <div style="background: #1E293B; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0;">
              <span style="font-size: 48px; font-weight: 800; letter-spacing: 12px; color: #3B82F6;">${otp}</span>
            </div>
            <p style="color: #64748B; font-size: 13px;">If you did not request a password reset, you can safely ignore this email.</p>
          </div>
        `,
      }),
    });

    if (!emailRes.ok) {
      const errBody = await emailRes.text();
      throw new Error(`Resend API error: ${errBody}`);
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
