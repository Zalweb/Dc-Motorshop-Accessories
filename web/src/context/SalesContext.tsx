import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '../core/supabase/supabaseClient';
import { CartItem, DashboardMetrics, Product, Sale, SaleItem } from '../core/types';
import { INITIAL_SALES } from '../core/storage/seedData';
import { isDateInFilter, DateFilterType } from '../core/utils/date';
import { exportSalesToExcel } from '../core/utils/exportExcel';
import { useAuth } from './AuthContext';
import { useBusiness } from './BusinessContext';
import { useInventory } from './InventoryContext';
import { useExpenses } from './ExpenseContext';

interface CheckoutOptions {
  customerName?: string;
  paymentMethod: 'cash' | 'gcash' | 'maya' | 'bank_transfer' | 'credit';
  amountReceived: number;
  discount?: number;
  notes?: string;
}

interface SalesContextType {
  sales: Sale[];
  cart: CartItem[];
  loading: boolean;
  addToCart: (product: Product, quantity?: number) => void;
  removeFromCart: (productId: string) => void;
  updateCartQuantity: (productId: string, quantity: number) => void;
  updateCartItemDiscount: (productId: string, discount: number) => void;
  clearCart: () => void;
  cartSubtotal: number;
  cartDiscount: number;
  cartTotal: number;
  cartItemCount: number;
  processCheckout: (options: CheckoutOptions) => Promise<Sale>;
  getMetricsForFilter: (filter: DateFilterType, customStart?: string, customEnd?: string) => DashboardMetrics;
  getFilteredSales: (filter: DateFilterType, searchQuery?: string, customStart?: string, customEnd?: string) => Sale[];
  exportSales: (filteredSales?: Sale[]) => void;
  refreshSales: () => Promise<void>;
  markSalePaid: (saleId: string) => Promise<void>;
  clearAllSales: () => void;
  seedSampleSalesData: () => Promise<void>;
}

const SalesContext = createContext<SalesContextType | undefined>(undefined);

export const SalesProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user } = useAuth();
  const { profile } = useBusiness();
  const { products, updateProduct } = useInventory();
  const { expenses } = useExpenses();

  const [sales, setSales] = useState<Sale[]>(() => {
    const saved = localStorage.getItem('dc_sales');
    return saved ? JSON.parse(saved) : INITIAL_SALES;
  });
  const [cart, setCart] = useState<CartItem[]>([]);
  const [loading, setLoading] = useState<boolean>(false);

  // Fetch sales and sale items from Supabase
  const refreshSales = async () => {
    if (!user) return;
    setLoading(true);
    try {
      const { data: salesData, error: salesErr } = await supabase
        .from('sales')
        .select('*')
        .eq('business_id', profile.id)
        .order('created_at', { ascending: false });

      if (salesData && !salesErr) {
        // Fetch sale items
        const { data: itemsData } = await supabase
          .from('sale_items')
          .select('*')
          .eq('business_id', profile.id);

        const itemsBySaleId: Record<string, SaleItem[]> = {};
        if (itemsData) {
          itemsData.forEach((item) => {
            if (!itemsBySaleId[item.sale_id]) {
              itemsBySaleId[item.sale_id] = [];
            }
            itemsBySaleId[item.sale_id].push({
              id: item.id,
              sale_id: item.sale_id,
              business_id: item.business_id,
              product_id: item.product_id,
              name: item.name,
              quantity: item.quantity,
              unit_price: Number(item.unit_price) || 0,
              unit_cost: Number(item.unit_cost) || 0,
              line_total: Number(item.line_total) || 0,
            });
          });
        }

        const mappedSales: Sale[] = salesData.map((s) => ({
          id: s.id,
          business_id: s.business_id,
          sale_number: s.sale_number,
          customer_name: s.customer_name,
          subtotal: Number(s.subtotal) || 0,
          discount: Number(s.discount) || 0,
          total: Number(s.total) || 0,
          status: s.status || 'paid',
          payment_method: s.payment_method || 'cash',
          amount_received: Number(s.amount_received) || 0,
          notes: s.notes,
          items: itemsBySaleId[s.id] || [],
          created_at: s.created_at,
          updated_at: s.updated_at,
        }));

        setSales(mappedSales);
        localStorage.setItem('dc_sales', JSON.stringify(mappedSales));
      }
    } catch (err) {
      console.warn('Error fetching sales from Supabase:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    refreshSales();
  }, [user, profile.id]);

  // Cart operations
  const addToCart = (product: Product, quantity: number = 1) => {
    setCart((prev) => {
      const existing = prev.find((item) => item.product.id === product.id);
      if (existing) {
        return prev.map((item) =>
          item.product.id === product.id
            ? { ...item, quantity: item.quantity + quantity }
            : item
        );
      }
      return [
        ...prev,
        {
          product,
          quantity,
          unit_price: product.selling_price,
          unit_cost: product.cost_price,
          discount: 0,
        },
      ];
    });
  };

  const removeFromCart = (productId: string) => {
    setCart((prev) => prev.filter((item) => item.product.id !== productId));
  };

  const updateCartQuantity = (productId: string, quantity: number) => {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    setCart((prev) =>
      prev.map((item) =>
        item.product.id === productId ? { ...item, quantity } : item
      )
    );
  };

  const updateCartItemDiscount = (productId: string, discount: number) => {
    setCart((prev) =>
      prev.map((item) =>
        item.product.id === productId ? { ...item, discount: Math.max(0, discount) } : item
      )
    );
  };

  const clearCart = () => setCart([]);

  const cartSubtotal = cart.reduce(
    (sum, item) => sum + (item.unit_price * item.quantity),
    0
  );

  const cartDiscount = cart.reduce(
    (sum, item) => sum + (item.discount * item.quantity),
    0
  );

  const cartTotal = Math.max(0, cartSubtotal - cartDiscount);

  const cartItemCount = cart.reduce((sum, item) => sum + item.quantity, 0);

  // Process Checkout
  const processCheckout = async (options: CheckoutOptions): Promise<Sale> => {
    const saleId = `sale-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`;
    const saleNumber = `SALE-${1000 + sales.length + 1}`;
    const overallDiscount = (options.discount || 0) + cartDiscount;
    const finalTotal = Math.max(0, cartSubtotal - overallDiscount);

    const saleItems: SaleItem[] = cart.map((item) => ({
      id: `item-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
      sale_id: saleId,
      business_id: profile.id,
      product_id: item.product.id,
      name: item.product.name,
      quantity: item.quantity,
      unit_price: item.unit_price,
      unit_cost: item.unit_cost,
      line_total: item.unit_price * item.quantity - (item.discount * item.quantity),
    }));

    const status = options.paymentMethod === 'credit' ? 'unpaid' : 'paid';

    const newSale: Sale = {
      id: saleId,
      business_id: profile.id,
      sale_number: saleNumber,
      customer_name: options.customerName || 'Walk-in Customer',
      subtotal: cartSubtotal,
      discount: overallDiscount,
      total: finalTotal,
      status,
      payment_method: options.paymentMethod,
      amount_received: options.amountReceived,
      notes: options.notes || null,
      items: saleItems,
      created_at: new Date().toISOString(),
    };

    // 1. Deduct Stock for physical products
    for (const item of cart) {
      if (!item.product.is_service) {
        const currentProd = products.find((p) => p.id === item.product.id);
        if (currentProd) {
          const newStock = Math.max(0, currentProd.stock_on_hand - item.quantity);
          await updateProduct(item.product.id, { stock_on_hand: newStock });
        }
      }
    }

    // 2. Save Sale locally
    const updatedSales = [newSale, ...sales];
    setSales(updatedSales);
    localStorage.setItem('dc_sales', JSON.stringify(updatedSales));

    // 3. Clear Cart
    clearCart();

    // 4. Save Sale to Supabase
    if (user?.id) {
      try {
        await supabase.from('sales').insert({
          id: newSale.id,
          business_id: profile.id,
          sale_number: newSale.sale_number,
          customer_name: newSale.customer_name,
          subtotal: newSale.subtotal,
          discount: newSale.discount,
          total: newSale.total,
          status: newSale.status,
          payment_method: newSale.payment_method,
          amount_received: newSale.amount_received,
          notes: newSale.notes,
          created_at: newSale.created_at,
        });

        await supabase.from('sale_items').insert(
          saleItems.map((item) => ({
            id: item.id,
            sale_id: item.sale_id,
            business_id: profile.id,
            product_id: item.product_id || null,
            name: item.name,
            quantity: item.quantity,
            unit_price: item.unit_price,
            unit_cost: item.unit_cost,
            line_total: item.line_total,
          }))
        );
      } catch (err) {
        console.warn('Supabase checkout insert error:', err);
      }
    }

    return newSale;
  };

  const markSalePaid = async (saleId: string) => {
    const updated = sales.map((s) => (s.id === saleId ? { ...s, status: 'paid' as const } : s));
    setSales(updated);
    localStorage.setItem('dc_sales', JSON.stringify(updated));

    if (user?.id) {
      try {
        await supabase.from('sales').update({ status: 'paid' }).eq('id', saleId);
      } catch (err) {
        console.warn('Failed to update sale status in Supabase:', err);
      }
    }
  };

  const clearAllSales = () => {
    setSales([]);
    localStorage.removeItem('dc_sales');
  };

  const seedSampleSalesData = async () => {
    const now = new Date();
    const drafts: Sale[] = [
      {
        id: `sale-${Date.now()}-1`,
        business_id: profile.id,
        sale_number: 'SALE-1001',
        customer_name: 'Walk-in Customer',
        subtotal: 300,
        discount: 0,
        total: 300,
        status: 'paid',
        payment_method: 'cash',
        amount_received: 300,
        created_at: new Date(now.getTime() - 2 * 3600 * 1000).toISOString(),
        items: [
          {
            id: 'si-1',
            sale_id: `sale-${Date.now()}-1`,
            business_id: profile.id,
            name: 'NGK Spark Plug CPR8EA-9',
            quantity: 2,
            unit_price: 150,
            unit_cost: 95,
            line_total: 300,
          },
        ],
      },
      {
        id: `sale-${Date.now()}-2`,
        business_id: profile.id,
        sale_number: 'SALE-1002',
        customer_name: 'Mang Tonyo',
        subtotal: 1450,
        discount: 0,
        total: 1450,
        status: 'partial',
        payment_method: 'cash',
        amount_received: 500,
        created_at: new Date(now.getTime() - 27 * 3600 * 1000).toISOString(),
        items: [
          {
            id: 'si-2',
            sale_id: `sale-${Date.now()}-2`,
            business_id: profile.id,
            name: 'Tubeless Tire 90/80-17',
            quantity: 1,
            unit_price: 1450,
            unit_cost: 950,
            line_total: 1450,
          },
        ],
      },
      {
        id: `sale-${Date.now()}-3`,
        business_id: profile.id,
        sale_number: 'SALE-1003',
        customer_name: 'Aling Nena',
        subtotal: 380,
        discount: 0,
        total: 380,
        status: 'unpaid',
        payment_method: 'credit',
        amount_received: 0,
        created_at: new Date(now.getTime() - 96 * 3600 * 1000).toISOString(),
        items: [
          {
            id: 'si-3',
            sale_id: `sale-${Date.now()}-3`,
            business_id: profile.id,
            name: 'Brake Pad Set',
            quantity: 1,
            unit_price: 380,
            unit_cost: 220,
            line_total: 380,
          },
        ],
      },
    ];

    setSales(drafts);
    localStorage.setItem('dc_sales', JSON.stringify(drafts));
  };

  // Metrics calculation
  const getMetricsForFilter = (
    filter: DateFilterType,
    customStart?: string,
    customEnd?: string
  ): DashboardMetrics => {
    const filteredSales = sales.filter((s) => {
      if (!profile.include_unpaid_in_reports && s.status === 'unpaid') return false;
      return isDateInFilter(s.created_at, filter, customStart, customEnd);
    });

    const filteredExpenses = expenses.filter((e) => {
      if (!e.include_in_calculations) return false;
      return isDateInFilter(e.spent_on, filter, customStart, customEnd);
    });

    const revenue = filteredSales.reduce((sum, s) => sum + s.total, 0);
    const salesCount = filteredSales.length;
    const discounts = filteredSales.reduce((sum, s) => sum + s.discount, 0);
    const avgTicket = salesCount > 0 ? revenue / salesCount : 0;

    // COGS
    let cogs = 0;
    filteredSales.forEach((sale) => {
      sale.items?.forEach((item) => {
        cogs += item.unit_cost * item.quantity;
      });
    });

    const totalExp = filteredExpenses.reduce((sum, e) => sum + e.amount, 0);
    const grossProfit = revenue - cogs;
    const netProfit = grossProfit - totalExp;
    const grossMarginPercent = revenue > 0 ? (grossProfit / revenue) * 100 : 0;

    return {
      revenue,
      salesCount,
      avgTicket,
      grossProfit,
      netProfit,
      cogs,
      expenses: totalExp,
      discounts,
      grossMarginPercent,
    };
  };

  const getFilteredSales = (
    filter: DateFilterType,
    searchQuery?: string,
    customStart?: string,
    customEnd?: string
  ): Sale[] => {
    let result = sales.filter((s) => isDateInFilter(s.created_at, filter, customStart, customEnd));

    if (searchQuery && searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      result = result.filter(
        (s) =>
          s.sale_number.toLowerCase().includes(q) ||
          s.customer_name?.toLowerCase().includes(q) ||
          s.items?.some((i) => i.name.toLowerCase().includes(q))
      );
    }

    return result;
  };

  const exportSales = (filteredSales?: Sale[]) => {
    const listToExport = filteredSales || sales;
    exportSalesToExcel(listToExport, profile.business_name);
  };

  return (
    <SalesContext.Provider
      value={{
        sales,
        cart,
        loading,
        addToCart,
        removeFromCart,
        updateCartQuantity,
        updateCartItemDiscount,
        clearCart,
        cartSubtotal,
        cartDiscount,
        cartTotal,
        cartItemCount,
        processCheckout,
        getMetricsForFilter,
        getFilteredSales,
        exportSales,
        refreshSales,
        markSalePaid,
        clearAllSales,
        seedSampleSalesData,
      }}
    >
      {children}
    </SalesContext.Provider>
  );
};

export const useSales = (): SalesContextType => {
  const context = useContext(SalesContext);
  if (!context) {
    throw new Error('useSales must be used within a SalesProvider');
  }
  return context;
};
