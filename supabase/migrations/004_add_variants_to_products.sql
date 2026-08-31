-- ============================================================
-- Add Variant Columns to Products Table in Supabase
-- ============================================================

ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS has_variants BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS variation1_name TEXT,
ADD COLUMN IF NOT EXISTS variation2_name TEXT,
ADD COLUMN IF NOT EXISTS variants JSONB NOT NULL DEFAULT '[]';
