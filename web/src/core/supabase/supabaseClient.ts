import { createClient } from '@supabase/supabase-js';

export const kSupabaseUrl = 'https://wuzrwqqqidrnziphamzr.supabase.co';
export const kSupabaseAnonKey = 'sb_publishable_AHBbVOPcRTV430LAyTu42w_c62ohE4L';
export const kProductImagesBucket = 'product-images';

export const supabase = createClient(kSupabaseUrl, kSupabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
});
