/// Supabase project credentials.
///
/// Override at build time using --dart-define:
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co
///   --dart-define=SUPABASE_ANON_KEY=your-anon-key
///
/// Or update the default values below directly (safe for anon key — it is
/// a public key designed to be embedded in clients).
library;

const String kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://wuzrwqqqidrnziphamzr.supabase.co',
);

const String kSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind1enJ3cXFxaWRybnppcGhhbXpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzOTM2OTMsImV4cCI6MjA5MTk2OTY5M30.D_4oBV7sDo4-_4fZbvg7_-B8TyKcFfYUxtUXfmhsBS8',
);

/// Supabase Storage bucket name for product images.
const String kProductImagesBucket = 'product-images';
