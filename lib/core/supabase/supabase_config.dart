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
  defaultValue: 'sb_publishable_AHBbVOPcRTV430LAyTu42w_c62ohE4L',
);

/// Supabase Storage bucket name for product images.
const String kProductImagesBucket = 'product-images';
