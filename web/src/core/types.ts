export type ThemeColor = 
  | 'Blue' 
  | 'Green' 
  | 'Purple' 
  | 'Orange' 
  | 'Rose' 
  | 'Slate' 
  | 'Teal' 
  | 'Indigo' 
  | 'Amber' 
  | 'Cyan';

export interface UserProfile {
  id: string;
  email: string;
  username: string;
  fullName?: string;
  phone?: string;
  role: 'owner' | 'manager' | 'staff';
  onboardingComplete: boolean;
  newShopSetup: boolean;
}

export interface BusinessProfile {
  id: string;
  owner_id: string;
  business_name: string;
  business_type: string;
  address?: string;
  phone?: string;
  email?: string;
  timezone: string;
  currency: string;
  theme_color: ThemeColor;
  logo_url?: string;
  receipt_qr_link?: string;
  onboarding_complete: boolean;
  onboarding_checklist: string[];
  allow_sell_when_out_of_stock: boolean;
  track_partial_change: boolean;
  include_unpaid_in_reports: boolean;
  closed_days?: ClosedDay[];
  created_at?: string;
  updated_at?: string;
}

export interface ClosedDay {
  id: string;
  date: string; // YYYY-MM-DD
  reason: 'holiday' | 'day_off' | 'maintenance' | 'other';
  note?: string;
}

export interface Category {
  id: string;
  business_id: string;
  name: string;
  is_service: boolean;
  parent_id?: string | null;
  created_at?: string;
  updated_at?: string;
  deleted_at?: string | null;
}

export interface Product {
  id: string;
  business_id: string;
  name: string;
  barcode?: string | null;
  part_number?: string | null;
  description?: string | null;
  category?: string | null;
  brand?: string | null;
  unit: string;
  is_service: boolean;
  cost_price: number;
  selling_price: number;
  stock_on_hand: number;
  image_url?: string | null;
  created_at?: string;
  updated_at?: string;
  deleted_at?: string | null;
}

export interface SaleItem {
  id: string;
  sale_id: string;
  business_id: string;
  product_id?: string | null;
  name: string;
  quantity: number;
  unit_price: number;
  unit_cost: number;
  line_total: number;
}

export interface Sale {
  id: string;
  business_id: string;
  sale_number: string;
  customer_name?: string | null;
  subtotal: number;
  discount: number;
  total: number;
  status: 'paid' | 'unpaid' | 'partial' | 'refunded';
  payment_method: 'cash' | 'gcash' | 'maya' | 'bank_transfer' | 'credit';
  amount_received: number;
  notes?: string | null;
  items?: SaleItem[];
  created_at: string;
  updated_at?: string;
}

export interface Expense {
  id: string;
  business_id: string;
  label: string;
  amount: number;
  note?: string | null;
  type: 'fixed' | 'variable' | 'recurring';
  category?: string | null;
  frequency?: string | null;
  end_date?: string | null;
  include_in_calculations: boolean;
  spent_on: string; // YYYY-MM-DD
  created_at?: string;
  updated_at?: string;
  deleted_at?: string | null;
}

export interface CartItem {
  product: Product;
  quantity: number;
  unit_price: number;
  unit_cost: number;
  discount: number;
  note?: string;
}

export interface DashboardMetrics {
  revenue: number;
  salesCount: number;
  avgTicket: number;
  grossProfit: number;
  netProfit: number;
  cogs: number;
  expenses: number;
  discounts: number;
  grossMarginPercent: number;
}
