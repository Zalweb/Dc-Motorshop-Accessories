import React from 'react';
import { 
  LayoutDashboard, 
  Receipt, 
  ShoppingCart, 
  Package, 
  Tags, 
  Barcode, 
  Wallet, 
  Users, 
  BarChart3, 
  Calendar, 
  Settings, 
  LogOut,
  Sparkles,
  Layers
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useBusiness } from '../../context/BusinessContext';

interface SidebarProps {
  currentTab: string;
  onSelectTab: (tab: string) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ currentTab, onSelectTab }) => {
  const { user, signOut } = useAuth();
  const { profile } = useBusiness();

  const mainNavItems = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { id: 'new-sale', label: 'New Sale (POS)', icon: ShoppingCart, badge: 'POS' },
    { id: 'sales', label: 'Sales History', icon: Receipt },
    { id: 'products', label: 'Products', icon: Package },
    { id: 'categories', label: 'Categories', icon: Tags },
    { id: 'bulk-add', label: 'Bulk Scan / Add', icon: Barcode },
  ];

  const manageNavItems = [
    { id: 'expenses', label: 'Expenses', icon: Wallet },
    { id: 'customers', label: 'Customers Ledger', icon: Users },
    { id: 'reports', label: 'Financial Reports', icon: BarChart3 },
    { id: 'calendar', label: 'Business Calendar', icon: Calendar },
    { id: 'checklist', label: 'Setup Checklist', icon: Sparkles },
    { id: 'settings', label: 'Shop Settings', icon: Settings },
  ];

  return (
    <aside className="hidden lg:flex flex-col w-64 bg-[#121212] border-r border-[#222222] min-h-screen text-white select-none shrink-0 z-30">
      {/* Brand Header */}
      <div className="p-5 border-b border-[#222222] flex items-center gap-3">
        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-600 to-blue-800 flex items-center justify-center shadow-lg shadow-blue-500/20 overflow-hidden border border-blue-400/30">
          {profile.logo_url && profile.logo_url !== '/logo.svg' ? (
            <img src={profile.logo_url} alt="Logo" className="w-full h-full object-cover" />
          ) : (
            <Layers className="w-5 h-5 text-white" />
          )}
        </div>
        <div className="flex-1 min-w-0">
          <h1 className="font-bold text-sm leading-tight truncate text-white">
            {profile.business_name || 'DC Motorshop'}
          </h1>
          <p className="text-xs text-gray-400 truncate flex items-center gap-1.5 mt-0.5">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
            {profile.business_type || 'Motorcycle Shop'}
          </p>
        </div>
      </div>

      {/* Navigation List */}
      <div className="flex-1 overflow-y-auto px-3 py-4 space-y-6">
        {/* Main Section */}
        <div>
          <p className="px-3 text-[11px] font-semibold tracking-wider text-gray-400 uppercase mb-2">
            Store & POS
          </p>
          <div className="space-y-1">
            {mainNavItems.map((item) => {
              const Icon = item.icon;
              const isActive = currentTab === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => onSelectTab(item.id)}
                  className={`w-full flex items-center justify-between px-3 py-2.5 rounded-xl text-sm font-medium transition-all ${
                    isActive
                      ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30 font-semibold'
                      : 'text-gray-300 hover:bg-[#1c1c1c] hover:text-white'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-gray-400'}`} />
                    <span>{item.label}</span>
                  </div>
                  {item.badge && (
                    <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-blue-400/20 text-blue-300 border border-blue-400/30">
                      {item.badge}
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        </div>

        {/* Management Section */}
        <div>
          <p className="px-3 text-[11px] font-semibold tracking-wider text-gray-400 uppercase mb-2">
            Management & Finance
          </p>
          <div className="space-y-1">
            {manageNavItems.map((item) => {
              const Icon = item.icon;
              const isActive = currentTab === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => onSelectTab(item.id)}
                  className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all ${
                    isActive
                      ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30 font-semibold'
                      : 'text-gray-300 hover:bg-[#1c1c1c] hover:text-white'
                  }`}
                >
                  <Icon className={`w-4 h-4 ${isActive ? 'text-white' : 'text-gray-400'}`} />
                  <span>{item.label}</span>
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* User Footer */}
      <div className="p-3 border-t border-[#222222] bg-[#0d0d0d]">
        <div className="flex items-center justify-between p-2 rounded-xl bg-[#171717] border border-[#262626]">
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="w-8 h-8 rounded-full bg-blue-600/20 border border-blue-500/30 flex items-center justify-center text-xs font-bold text-blue-400">
              {user?.username?.slice(0, 2).toUpperCase() || 'DC'}
            </div>
            <div className="min-w-0">
              <p className="text-xs font-semibold text-white truncate">{user?.fullName || user?.username || 'Owner'}</p>
              <p className="text-[11px] text-gray-400 truncate">@{user?.username || 'owner'}</p>
            </div>
          </div>
          <button
            onClick={signOut}
            title="Sign out"
            className="p-1.5 text-gray-400 hover:text-red-400 hover:bg-red-500/10 rounded-lg transition-colors"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </div>
    </aside>
  );
};
