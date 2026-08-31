import React from 'react';
import { Sidebar } from './Sidebar';
import { Header } from './Header';
import { BottomNav } from './BottomNav';

interface LayoutProps {
  currentTab: string;
  onSelectTab: (tab: string) => void;
  children: React.ReactNode;
}

export const Layout: React.FC<LayoutProps> = ({ currentTab, onSelectTab, children }) => {
  return (
    <div className="min-h-screen bg-[#0A0A0A] text-white flex flex-row overflow-x-hidden selection:bg-blue-600 selection:text-white">
      {/* Desktop Sidebar */}
      <Sidebar currentTab={currentTab} onSelectTab={onSelectTab} />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0 min-h-screen">
        <Header currentTab={currentTab} onSelectTab={onSelectTab} />

        <main className="flex-1 p-4 sm:p-6 lg:p-8 max-w-7xl w-full mx-auto">
          {children}
        </main>

        {/* Mobile 5-Tab Bottom Navigation */}
        <BottomNav currentTab={currentTab} onSelectTab={onSelectTab} />
      </div>
    </div>
  );
};
