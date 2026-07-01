-- ============================================================
-- DC Motorshop Inventory — Supabase Initial Schema
-- Run this in the Supabase Dashboard → SQL Editor
-- ============================================================

-- Enable UUID generation (already available in Supabase)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ────────────────────────────────────────────────────────────
-- BUSINESS PROFILES
-- One row per registered shop (tied to auth.users.id)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.business_profiles (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  business_name  TEXT NOT NULL DEFAULT 'DC Motorshop & Accessories',
  business_type  TEXT NOT NULL DEFAULT 'Motorcycle Shop',
  address        TEXT,
  phone          TEXT,
  email          TEXT,
  timezone       TEXT NOT NULL DEFAULT 'Asia/Manila (GMT+8)',
  currency       TEXT NOT NULL DEFAULT 'PHP — Philippine Peso',
  theme_color    TEXT NOT NULL DEFAULT 'Blue',
  logo_url       TEXT,
  receipt_qr_link TEXT,
  onboarding_complete BOOLEAN NOT NULL DEFAULT FALSE,
  onboarding_checklist JSONB NOT NULL DEFAULT '[]',
  allow_sell_when_out_of_stock BOOLEAN NOT NULL DEFAULT FALSE,
  track_partial_change         BOOLEAN NOT NULL DEFAULT FALSE,
  include_unpaid_in_reports    BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.business_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner can manage own business"
  ON public.business_profiles
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- ────────────────────────────────────────────────────────────
-- CATEGORIES
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.categories (
  id          UUID PRIMARY KEY,
  business_id UUID NOT NULL REFERENCES public.business_profiles(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  is_service  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at  TIMESTAMPTZ,
  UNIQUE (business_id, name)
);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner can manage own categories"
  ON public.categories
  USING (business_id IN (SELECT id FROM public.business_profiles WHERE owner_id = auth.uid()))
  WITH CHECK (business_id IN (SELECT id FROM public.business_profiles WHERE owner_id = auth.uid()));

-- ────────────────────────────────────────────────────────────
-- PRODUCTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.products (
  id              UUID PRIMARY KEY,
  business_id     UUID NOT NULL REFERENCES public.business_profiles(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  barcode         TEXT,
  part_number     TEXT,
  description     TEXT,
  category        TEXT,
  brand           TEXT,
  unit            TEXT NOT NULL DEFAULT 'piece',
  is_service      BOOLEAN NOT NULL DEFAULT FALSE,
  cost_price      NUMERIC(12, 2) NOT NULL DEFAULT 0,
  selling_price   NUMERIC(12, 2) NOT NULL DEFAULT 0,
  stock_on_hand   INTEGER NOT NULL DEFAULT 0,
  image_url       TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner can manage own products"
  ON public.products
  USING (business_id IN (SELECT id FROM public.business_profiles WHERE owner_id = auth.uid()))
  WITH CHECK (business_id IN (SELECT id FROM public.business_profiles WHERE owner_id = auth.uid()));

CREATE INDEX IF NOT EXISTS idx_products_business_id ON public.products(business_id);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON public.products(business_id, barcode) WHERE barcode IS NOT NULL;

-- ────────────────────────────────────────────────────────────
-- SALES
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sales (
  id              UUID PRIMARY KEY,
  business_id     UUID NOT NULL REFERENCES public.business_profiles(id) ON DELETE CASCADE,
  sale_number     TEXT NOT NULL,
  customer_name   TEXT,
  subtotal        NUMERIC(12, 2) NOT NULL DEFAULT 0,
  discount        NUMERIC(12, 2) NOT NULL DEFAULT 0,
  total           NUMERIC(12, 2) NOT NULL DEFAULT 0,
  status          TEXT NOT NULL DEFAULT 'paid',
  payment_method  TEXT NOT NULL DEFAULT 'cash',
  amount_received NUMERIC(12, 2) NOT NULL DEFAULT 0,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner can manage own sales"
  ON public.sales
  USING (business_id IN (SELECT id FROM public.business_profiles WHERE owner_id = auth.uid()))
  WITH CHECK (business_id IN (SELECT id FROM public.business_profiles WHERE owner_id = auth.uid()));

CREATE INDEX IF NOT EXISTS idx_sales_business_created ON public.sales(business_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_sale_number ON public.sales(business_id, sale_number);

-- ────────────────────────────────────────────────────────────
-- SALE ITEMS
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sale_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id     UUID NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
  business_id UUID NOT NULL REFERENCES public.business_profiles(id) ON DELETE CASCADE,
  product_id  UUID REFERENCES public.products(id) ON DELETE SET NULL,
  name        TEXT NOT NULL,
  quantity    INTEGER NOT NULL DEFAULT 1,
  unit_price  NUMERIC(12, 2) NOT NULL DEFAULT 0,
  unit_cost   NUMERIC(12, 2) NOT NULL DEFAULT 0,
  line_total  NUMERIC(12, 2) NOT NULL DEFAULT 0
);

ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner can manage own sale items"
  ON public.sale_items
  USING (business_id IN (SELECT id FROM public.business_profiles WHERE owner_id = auth.uid()))
  WITH CHECK (business_id IN (SELECT id FROM public.business_profiles WHERE owner_id = auth.uid()));

-- ────────────────────────────────────────────────────────────
-- EXPENSES
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.expenses (
  id                      UUID PRIMARY KEY,
  business_id             UUID NOT NULL REFERENCES public.business_profiles(id) ON DELETE CASCADE,
  label                   TEXT NOT NULL,
  amount                  NUMERIC(12, 2) NOT NULL DEFAULT 0,
  note                    TEXT,
  type                    TEXT NOT NULL DEFAULT 'variable',
  category                TEXT,
  frequency               TEXT,
  end_date                DATE,
  include_in_calculations BOOLEAN NOT NULL DEFAULT TRUE,
  spent_on                DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at              TIMESTAMPTZ
);

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner can manage own expenses"
  ON public.expenses
  USING (business_id IN (SELECT id FROM public.business_profiles WHERE owner_id = auth.uid()))
  WITH CHECK (business_id IN (SELECT id FROM public.business_profiles WHERE owner_id = auth.uid()));

CREATE INDEX IF NOT EXISTS idx_expenses_business_created ON public.expenses(business_id, created_at DESC);

-- ────────────────────────────────────────────────────────────
-- UPDATED_AT TRIGGER
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_business_profiles_updated_at
  BEFORE UPDATE ON public.business_profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_categories_updated_at
  BEFORE UPDATE ON public.categories
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_sales_updated_at
  BEFORE UPDATE ON public.sales
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_expenses_updated_at
  BEFORE UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
