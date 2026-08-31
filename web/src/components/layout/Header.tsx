import React from 'react';
import { Cloud, CheckCircle2, RefreshCw, ShoppingBag, Sparkles } from 'lucide-react';
import { useSales } from '../../context/SalesContext';
import { useBusiness } from '../../context/BusinessContext';
import { useTheme } from '../../core/theme/ThemeContext';

interface HeaderProps {
  currentTab: string;
  onSelectTab: (tab: string) => void;
  onOpenCart?: () => void;
}

export const Header: React.FC<HeaderProps> = ({ currentTab, onSelectTab, onOpenCart }) => {
  const { cartItemCount } = useSales();
  const { profile } = useBusiness();
  const { themeColor } = useTheme();

  const getTitle = () => {
    switch (currentTab) {
      case 'dashboard': return 'Dashboard Overview';
      case 'new-sale': return 'Point of Sale (New Sale)';
      case 'sales': return 'Sales History & Receipts';
      case 'products': return 'Product & Inventory Catalog';
      case 'categories': return 'Product Categories';
      case 'bulk-add': return 'Bulk Barcode Scanner';
      case 'expenses': return 'Expense Tracker';
      case 'customers': return 'Customer Receivables Ledger';
      case 'reports': return 'Financial Analytics & Reports';
      case 'calendar': return 'Business & Closed Days Calendar';
      case 'checklist': return 'Setup Checklist';
      case 'settings': return 'Shop & General Settings';
      default: return 'DC Motorcycle Inventory';
    }
  };

  return (
    <header className="h-16 bg-[#121212]/90 backdrop-blur-md border-b border-[#222222] px-4 md:px-6 flex items-center justify-between sticky top-0 z-20">
      {/* Left: Tab Title / Mobile Logo */}
      <div className="flex items-center gap-3">
        <div className="lg:hidden flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center font-bold text-xs text-white">
            DC
          </div>
        </div>
        <div>
          <h2 className="text-base md:text-lg font-bold text-white tracking-tight flex items-center gap-2">
            {getTitle()}
          </h2>
          <p className="text-[11px] text-gray-400 hidden sm:block">
            {profile.business_name} · {profile.currency}
          </p>
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-2 md:gap-3">
        {/* Live Cloud Status */}
        <div className="hidden sm:flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#1c1c1c] border border-[#2a2a2a] text-[11px] text-gray-300">
          <Cloud className="w-3.5 h-3.5 text-blue-400" />
          <span className="font-medium">Supabase Cloud</span>
          <CheckCircle2 className="w-3 h-3 text-emerald-400" />
        </div>

        {/* Theme indicator */}
        <div className="hidden md:flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-[#1c1c1c] border border-[#2a2a2a] text-[11px] text-gray-300">
          <Sparkles className="w-3.5 h-3.5 text-amber-400" />
          <span>Theme: <b>{themeColor}</b></span>
        </div>

        {/* Cart Button (for Mobile & quick POS access) */}
        {cartItemCount > 0 && (
          <button
            onClick={onOpenCart ? onOpenCart : () => onSelectTab('new-sale')}
            className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-semibold text-xs transition-all shadow-md shadow-blue-600/30 animate-fade-in"
          >
            <ShoppingBag className="w-4 h-4" />
            <span>Cart</span>
            <span className="w-5 h-5 rounded-full bg-white text-blue-600 flex items-center justify-center font-bold text-[10px]">
              {cartItemCount}
            </span>
          </button>
        )}
      </div>
    </header>
  );
};
