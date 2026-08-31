-- ============================================================
-- 005: Relational Product Variants & Inventory Transactions
-- ============================================================

-- 1. Create product_variants table
CREATE TABLE IF NOT EXISTS public.product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES public.business_profiles(id) ON DELETE CASCADE,
    sku TEXT,
    barcode TEXT,
    part_number TEXT,
    variant_name TEXT NOT NULL DEFAULT '',
    option1_name TEXT,
    option1_value TEXT,
    option2_name TEXT,
    option2_value TEXT,
    unit TEXT NOT NULL DEFAULT 'piece',
    cost_price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    selling_price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    stock_on_hand INTEGER NOT NULL DEFAULT 0,
    reorder_level INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_product_variants_business_sku 
    ON public.product_variants(business_id, sku) 
    WHERE sku IS NOT NULL AND deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_product_variants_business_barcode 
    ON public.product_variants(business_id, barcode) 
    WHERE barcode IS NOT NULL AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON public.product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_business_id ON public.product_variants(business_id);

-- 2. Create inventory_transactions table
CREATE TABLE IF NOT EXISTS public.inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.business_profiles(id) ON DELETE CASCADE,
    product_variant_id UUID NOT NULL REFERENCES public.product_variants(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN (
        'INITIAL_STOCK',
        'PURCHASE',
        'SALE',
        'SALE_RETURN',
        'PURCHASE_RETURN',
        'STOCK_ADJUSTMENT',
        'DAMAGE',
        'LOSS'
    )),
    quantity INTEGER NOT NULL,
    unit_cost NUMERIC(12,2),
    reference_type TEXT,
    reference_id UUID,
    notes TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inv_tx_variant ON public.inventory_transactions(product_variant_id);
CREATE INDEX IF NOT EXISTS idx_inv_tx_business ON public.inventory_transactions(business_id);
CREATE INDEX IF NOT EXISTS idx_inv_tx_created_at ON public.inventory_transactions(created_at);

-- 3. Update sale_items table
ALTER TABLE public.sale_items 
ADD COLUMN IF NOT EXISTS product_variant_id UUID REFERENCES public.product_variants(id),
ADD COLUMN IF NOT EXISTS sku TEXT,
ADD COLUMN IF NOT EXISTS variant_name TEXT;

-- 4. Enable RLS and security policies
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'product_variants' AND policyname = 'Owners manage their product_variants'
    ) THEN
        CREATE POLICY "Owners manage their product_variants" ON public.product_variants
            FOR ALL USING (business_id IN (SELECT id FROM public.business_profiles WHERE owner_id = auth.uid()));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'inventory_transactions' AND policyname = 'Owners manage their inventory_transactions'
    ) THEN
        CREATE POLICY "Owners manage their inventory_transactions" ON public.inventory_transactions
            FOR ALL USING (business_id IN (SELECT id FROM public.business_profiles WHERE owner_id = auth.uid()));
    END IF;
END $$;
