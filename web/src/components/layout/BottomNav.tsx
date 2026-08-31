import React from 'react';
import { LayoutGrid, Receipt, ShoppingCart, Package, Menu } from 'lucide-react';
import { useSales } from '../../context/SalesContext';

interface BottomNavProps {
  currentTab: string;
  onSelectTab: (tab: string) => void;
}

export const BottomNav: React.FC<BottomNavProps> = ({ currentTab, onSelectTab }) => {
  const { cartItemCount } = useSales();

  const tabs = [
    { id: 'dashboard', label: 'Dashboard', icon: LayoutGrid },
    { id: 'sales', label: 'Sales', icon: Receipt },
    { id: 'new-sale', label: 'New Sale', icon: ShoppingCart, isFab: true },
    { id: 'products', label: 'Products', icon: Package },
    { id: 'settings', label: 'More', icon: Menu },
  ];

  return (
    <nav className="lg:hidden fixed bottom-0 left-0 right-0 h-16 bg-[#121212] border-t border-[#222222] z-40 flex items-center justify-around px-2 safe-area-bottom">
      {tabs.map((tab) => {
        const Icon = tab.icon;
        const isActive = currentTab === tab.id;

        if (tab.isFab) {
          return (
            <button
              key={tab.id}
              onClick={() => onSelectTab(tab.id)}
              className="relative -top-5 flex flex-col items-center group"
            >
              <div className="w-13 h-13 rounded-full bg-blue-600 group-hover:bg-blue-500 text-white flex items-center justify-center shadow-lg shadow-blue-600/50 border-4 border-[#0a0a0a] transition-transform active:scale-95">
                <Icon className="w-6 h-6" />
                {cartItemCount > 0 && (
                  <span className="absolute -top-1 -right-1 bg-red-500 text-white text-[10px] font-bold w-5 h-5 rounded-full flex items-center justify-center border-2 border-[#0a0a0a]">
                    {cartItemCount}
                  </span>
                )}
              </div>
              <span className="text-[10px] font-semibold text-blue-400 mt-0.5">New Sale</span>
            </button>
          );
        }

        return (
          <button
            key={tab.id}
            onClick={() => onSelectTab(tab.id)}
            className={`flex flex-col items-center justify-center py-1 px-3 rounded-lg transition-colors ${
              isActive ? 'text-blue-500 font-semibold' : 'text-gray-400 hover:text-gray-200'
            }`}
          >
            <Icon className={`w-5 h-5 ${isActive ? 'text-blue-500' : 'text-gray-400'}`} />
            <span className="text-[10px] mt-1">{tab.label}</span>
          </button>
        );
      })}
    </nav>
  );
};
