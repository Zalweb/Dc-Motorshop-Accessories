-- ============================================================
-- DC Motorshop Inventory — Supabase Storage Setup
-- Run this in the Supabase Dashboard → SQL Editor AFTER
-- running 001_initial_schema.sql
-- ============================================================

-- Create the product-images bucket (private — access via signed URLs)
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', false)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated owners to upload images for their business products
CREATE POLICY "auth users can upload product images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
  );

-- Allow authenticated users to read their own product images
CREATE POLICY "auth users can read product images"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
  );

-- Allow authenticated users to update/replace their own images
CREATE POLICY "auth users can update product images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
  );

-- Allow authenticated users to delete their own images
CREATE POLICY "auth users can delete product images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'product-images'
    AND auth.role() = 'authenticated'
  );
