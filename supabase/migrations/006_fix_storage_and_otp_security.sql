-- ============================================================
-- 006: Fix Storage Policies and OTP Password Resets Security
-- ============================================================

-- 1. Drop the four overly-broad storage policies from 002_storage_bucket.sql
DROP POLICY IF EXISTS "auth users can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "auth users can read product images" ON storage.objects;
DROP POLICY IF EXISTS "auth users can update product images" ON storage.objects;
DROP POLICY IF EXISTS "auth users can delete product images" ON storage.objects;

-- 2. Recreate storage policies scoped by owner:
-- Top-level folder in storage path must match (auth.uid())::text
CREATE POLICY "Users can upload product images to own folder"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = (auth.uid())::text
  );

CREATE POLICY "Users can read product images from own folder"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = (auth.uid())::text
  );

CREATE POLICY "Users can update product images in own folder"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = (auth.uid())::text
  );

CREATE POLICY "Users can delete product images from own folder"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = (auth.uid())::text
  );

-- Allow authenticated users to SELECT the 'product-images' bucket row
CREATE POLICY "Authenticated users can select product-images bucket"
  ON storage.buckets FOR SELECT
  USING (
    id = 'product-images'
    AND auth.role() = 'authenticated'
  );

-- 3. Create password_resets table
CREATE TABLE IF NOT EXISTS public.password_resets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL,
  otp_hash text NOT NULL,
  expires_at timestamptz NOT NULL,
  used boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 4. Enable Row Level Security on password_resets with NO client policies (service-role only)
ALTER TABLE public.password_resets ENABLE ROW LEVEL SECURITY;

-- 5. Index password_resets on email
CREATE INDEX IF NOT EXISTS idx_password_resets_email ON public.password_resets(email);
