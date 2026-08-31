-- ============================================================================
-- DC MOTORSHOP INVENTORY — DATABASE CLEANUP SCRIPT
-- Purpose:
--   1. Clears all test/historical sales & sale items.
--   2. Merges & deletes duplicate business profiles (keeping the active one).
--   3. Deduplicates categories & re-links all products to the primary category.
--   4. Deduplicates products (keeping the one with inventory/latest updates).
--   5. Cleans up soft-deleted/orphaned records.
--
-- Instructions:
--   Copy and paste this script into your Supabase Dashboard → SQL Editor → Run.
-- ============================================================================

BEGIN;

-- ────────────────────────────────────────────────────────────
-- 1. REMOVE ALL SALES & SALE ITEMS
-- ────────────────────────────────────────────────────────────
DELETE FROM public.sale_items;
DELETE FROM public.sales;

-- ────────────────────────────────────────────────────────────
-- 2. DEDUPLICATE BUSINESS PROFILES
-- ────────────────────────────────────────────────────────────
DO $$
DECLARE
  rec RECORD;
  keeper_id UUID;
  dup_id UUID;
BEGIN
  -- For each owner_id that has more than 1 business profile:
  FOR rec IN (
    SELECT owner_id, count(*)
    FROM public.business_profiles
    GROUP BY owner_id
    HAVING count(*) > 1
  ) LOOP
    -- Pick the keeper: the profile that has active products, or the most recently updated
    SELECT bp.id INTO keeper_id
    FROM public.business_profiles bp
    LEFT JOIN public.products p ON p.business_id = bp.id
    WHERE bp.owner_id = rec.owner_id
    GROUP BY bp.id, bp.updated_at
    ORDER BY count(p.id) DESC, bp.updated_at DESC
    LIMIT 1;

    -- Reassign all related child records from duplicates to the keeper
    FOR dup_id IN (
      SELECT id FROM public.business_profiles
      WHERE owner_id = rec.owner_id AND id <> keeper_id
    ) LOOP
      UPDATE public.products SET business_id = keeper_id WHERE business_id = dup_id;
      UPDATE public.categories SET business_id = keeper_id WHERE business_id = dup_id;
      UPDATE public.expenses SET business_id = keeper_id WHERE business_id = dup_id;
      
      -- Delete the duplicate profile
      DELETE FROM public.business_profiles WHERE id = dup_id;
    END LOOP;
  END LOOP;
END $$;

-- ────────────────────────────────────────────────────────────
-- 3. DEDUPLICATE CATEGORIES & RE-LINK PRODUCTS
-- ────────────────────────────────────────────────────────────
DO $$
DECLARE
  cat_rec RECORD;
  primary_cat_id UUID;
  dup_cat_id UUID;
BEGIN
  FOR cat_rec IN (
    SELECT business_id, LOWER(TRIM(name)) AS norm_name, COUNT(*)
    FROM public.categories
    WHERE deleted_at IS NULL
    GROUP BY business_id, LOWER(TRIM(name))
    HAVING COUNT(*) > 1
  ) LOOP
    -- Pick primary category (the one with the most connected products)
    SELECT c.id INTO primary_cat_id
    FROM public.categories c
    LEFT JOIN public.products p ON p.category_id = c.id
    WHERE c.business_id = cat_rec.business_id 
      AND LOWER(TRIM(c.name)) = cat_rec.norm_name 
      AND c.deleted_at IS NULL
    GROUP BY c.id, c.created_at
    ORDER BY COUNT(p.id) DESC, c.created_at ASC
    LIMIT 1;

    -- Reassign products from duplicate category to primary category, then delete duplicate
    FOR dup_cat_id IN (
      SELECT id FROM public.categories
      WHERE business_id = cat_rec.business_id 
        AND LOWER(TRIM(name)) = cat_rec.norm_name 
        AND id <> primary_cat_id
    ) LOOP
      UPDATE public.products SET category_id = primary_cat_id WHERE category_id = dup_cat_id;
      DELETE FROM public.categories WHERE id = dup_cat_id;
    END LOOP;
  END LOOP;
END $$;

-- ────────────────────────────────────────────────────────────
-- 4. DEDUPLICATE PRODUCTS
-- ────────────────────────────────────────────────────────────
DO $$
DECLARE
  prod_rec RECORD;
  keeper_prod_id UUID;
  dup_prod_id UUID;
BEGIN
  FOR prod_rec IN (
    SELECT business_id, LOWER(TRIM(name)) AS norm_name, COUNT(*)
    FROM public.products
    WHERE deleted_at IS NULL
    GROUP BY business_id, LOWER(TRIM(name))
    HAVING COUNT(*) > 1
  ) LOOP
    -- Pick keeper product: one with highest stock on hand or latest updated
    SELECT id INTO keeper_prod_id
    FROM public.products
    WHERE business_id = prod_rec.business_id 
      AND LOWER(TRIM(name)) = prod_rec.norm_name 
      AND deleted_at IS NULL
    ORDER BY stock_on_hand DESC, updated_at DESC
    LIMIT 1;

    -- Remove redundant duplicates
    FOR dup_prod_id IN (
      SELECT id FROM public.products
      WHERE business_id = prod_rec.business_id 
        AND LOWER(TRIM(name)) = prod_rec.norm_name 
        AND id <> keeper_prod_id
    ) LOOP
      DELETE FROM public.products WHERE id = dup_prod_id;
    END LOOP;
  END LOOP;
END $$;

-- ────────────────────────────────────────────────────────────
-- 5. PURGE SOFT-DELETED RECORDS
-- ────────────────────────────────────────────────────────────
DELETE FROM public.categories WHERE deleted_at IS NOT NULL;
DELETE FROM public.products WHERE deleted_at IS NOT NULL;
DELETE FROM public.expenses WHERE deleted_at IS NOT NULL;

COMMIT;

-- Verification Queries
SELECT 'Business Profiles Remaining' AS item, COUNT(*) AS count FROM public.business_profiles
UNION ALL
SELECT 'Categories Remaining' AS item, COUNT(*) AS count FROM public.categories
UNION ALL
SELECT 'Products Remaining' AS item, COUNT(*) AS count FROM public.products
UNION ALL
SELECT 'Sales Remaining' AS item, COUNT(*) AS count FROM public.sales
UNION ALL
SELECT 'Sale Items Remaining' AS item, COUNT(*) AS count FROM public.sale_items;
