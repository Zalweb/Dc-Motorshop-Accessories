import { BusinessProfile, Category, Expense, Product, Sale, UserProfile } from '../types';

export const DEFAULT_BUSINESS_ID = '00000000-0000-0000-0000-000000000001';
export const DEFAULT_USER_ID = '00000000-0000-0000-0000-000000000002';

// Standard MoSPAMS Category List (from setup review)
export const DEFAULT_CATEGORIES: Category[] = [
  { id: 'cat-1', business_id: DEFAULT_BUSINESS_ID, name: 'Engine Parts', is_service: false },
  { id: 'cat-2', business_id: DEFAULT_BUSINESS_ID, name: 'Brakes', is_service: false },
  { id: 'cat-3', business_id: DEFAULT_BUSINESS_ID, name: 'Electrical', is_service: false },
  { id: 'cat-4', business_id: DEFAULT_BUSINESS_ID, name: 'Tires & Wheels', is_service: false },
  { id: 'cat-5', business_id: DEFAULT_BUSINESS_ID, name: 'Lubricants/Oils', is_service: false },
  { id: 'cat-6', business_id: DEFAULT_BUSINESS_ID, name: 'Accessories', is_service: false },
  { id: 'cat-7', business_id: DEFAULT_BUSINESS_ID, name: 'Services', is_service: true },
];

// Clean initial data - NO mock products, sales, or expenses
export const INITIAL_PRODUCTS: Product[] = [];
export const INITIAL_SALES: Sale[] = [];
export const INITIAL_EXPENSES: Expense[] = [];

export const INITIAL_USER: UserProfile = {
  id: DEFAULT_USER_ID,
  email: 'owner@dcmotorshop.com',
  username: 'dcmotorshop',
  fullName: 'DC Motorshop Owner',
  phone: '09171234567',
  role: 'owner',
  onboardingComplete: true,
  newShopSetup: true,
};

export const INITIAL_BUSINESS_PROFILE: BusinessProfile = {
  id: DEFAULT_BUSINESS_ID,
  owner_id: DEFAULT_USER_ID,
  business_name: 'DC Motorshop & Accessories',
  business_type: 'Motorcycle Shop',
  address: '123 Rizal Highway, Poblacion, Philippines',
  phone: '0917-123-4567',
  email: 'contact@dcmotorshop.com',
  timezone: 'Asia/Manila (GMT+8)',
  currency: 'PHP — Philippine Peso',
  theme_color: 'Blue',
  logo_url: '/logo.svg',
  onboarding_complete: true,
  onboarding_checklist: [],
  allow_sell_when_out_of_stock: false,
  track_partial_change: false,
  include_unpaid_in_reports: true,
  closed_days: [],
};

/**
 * Dev-only helper: populates sample motorcycle catalog and sales for testing (matching dev_seed.dart)
 */
export const SAMPLE_DEV_PRODUCTS: Product[] = [
  {
    id: 'prod-1',
    business_id: DEFAULT_BUSINESS_ID,
    name: 'NGK Spark Plug CPR8EA-9',
    barcode: '4961263000123',
    part_number: 'CPR8EA-9',
    brand: 'NGK',
    category: 'Electrical',
    unit: 'piece',
    is_service: false,
    cost_price: 95,
    selling_price: 150,
    stock_on_hand: 40,
  },
  {
    id: 'prod-2',
    business_id: DEFAULT_BUSINESS_ID,
    name: 'Brake Pad Set',
    barcode: '9312567845210',
    part_number: 'BP-CLK125',
    brand: 'Bendix',
    category: 'Brakes',
    unit: 'set',
    is_service: false,
    cost_price: 220,
    selling_price: 380,
    stock_on_hand: 18,
  },
  {
    id: 'prod-3',
    business_id: DEFAULT_BUSINESS_ID,
    name: 'Engine Oil 10W-40 1L',
    barcode: '3374650238124',
    part_number: 'MOT-3000',
    brand: 'Motul',
    category: 'Lubricants/Oils',
    unit: 'liter',
    is_service: false,
    cost_price: 280,
    selling_price: 420,
    stock_on_hand: 60,
  },
  {
    id: 'prod-4',
    business_id: DEFAULT_BUSINESS_ID,
    name: 'Tubeless Tire 90/80-17',
    barcode: '4712398471201',
    part_number: 'MICH-908017',
    brand: 'Michelin',
    category: 'Tires & Wheels',
    unit: 'piece',
    is_service: false,
    cost_price: 950,
    selling_price: 1450,
    stock_on_hand: 12,
  },
  {
    id: 'prod-5',
    business_id: DEFAULT_BUSINESS_ID,
    name: 'Change Oil (Labor)',
    barcode: '',
    part_number: 'SRV-OIL',
    brand: 'In-House',
    category: 'Services',
    unit: 'service',
    is_service: true,
    cost_price: 0,
    selling_price: 120,
    stock_on_hand: 999,
  },
];
