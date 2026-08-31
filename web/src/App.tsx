import React, { useState } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import { ThemeProvider } from './core/theme/ThemeContext';
import { BusinessProvider } from './context/BusinessContext';
import { InventoryProvider } from './context/InventoryContext';
import { ExpenseProvider } from './context/ExpenseContext';
import { SalesProvider } from './context/SalesContext';
import { Layout } from './components/layout/Layout';

// Pages
import { Login } from './pages/auth/Login';
import { OnboardingFlow } from './pages/onboarding/OnboardingFlow';
import { SetupChecklist } from './pages/onboarding/SetupChecklist';
import { Dashboard } from './pages/dashboard/Dashboard';
import { NewSale } from './pages/pos/NewSale';
import { SalesHistory } from './pages/sales/SalesHistory';
import { Products } from './pages/products/Products';
import { Categories } from './pages/products/Categories';
import { BulkAdd } from './pages/products/BulkAdd';
import { Expenses } from './pages/expenses/Expenses';
import { Customers } from './pages/customers/Customers';
import { Reports } from './pages/dashboard/Reports';
import { FinancialCalendar } from './pages/dashboard/FinancialCalendar';
import { MoreSettings } from './pages/more/MoreSettings';

const SplashScreen: React.FC = () => (
  <div className="min-h-screen bg-[#0A0A0A] flex flex-col items-center justify-center p-4 text-center selection:bg-blue-600">
    <div className="w-20 h-20 rounded-3xl bg-gradient-to-tr from-blue-600 to-blue-800 flex items-center justify-center shadow-2xl shadow-blue-600/40 border border-blue-400/30 mb-6 overflow-hidden animate-pulse-glow">
      <img src="/logo.svg" alt="DC" className="w-14 h-14 object-contain" onError={(e) => {
        (e.target as HTMLElement).style.display = 'none';
      }} />
    </div>
    <h1 className="text-2xl font-black text-white tracking-tight">DC Motorcycle Inventory</h1>
    <p className="text-xs text-gray-400 mt-1">Welcome back! Preparing your dashboard...</p>

    {/* 3-Dot Animated Loader */}
    <div className="flex items-center gap-2 mt-8">
      <div className="w-2.5 h-2.5 rounded-full bg-blue-500 animate-bounce [animation-delay:-0.3s]" />
      <div className="w-2.5 h-2.5 rounded-full bg-blue-500 animate-bounce [animation-delay:-0.15s]" />
      <div className="w-2.5 h-2.5 rounded-full bg-blue-500 animate-bounce" />
    </div>
  </div>
);

const AppContent: React.FC = () => {
  const { user, loading } = useAuth();
  const [currentTab, setCurrentTab] = useState<string>('dashboard');

  if (loading) {
    return <SplashScreen />;
  }

  if (!user) {
    return <Login />;
  }

  // If new user needs onboarding setup
  if (!user.onboardingComplete && !user.newShopSetup) {
    return <OnboardingFlow onFinish={() => setCurrentTab('dashboard')} />;
  }

  const renderTabContent = () => {
    switch (currentTab) {
      case 'dashboard':
        return <Dashboard onNavigate={setCurrentTab} />;
      case 'new-sale':
        return <NewSale />;
      case 'sales':
        return <SalesHistory />;
      case 'products':
        return <Products onNavigate={setCurrentTab} />;
      case 'categories':
        return <Categories onBack={() => setCurrentTab('products')} />;
      case 'bulk-add':
        return <BulkAdd onBack={() => setCurrentTab('products')} />;
      case 'expenses':
        return <Expenses />;
      case 'customers':
        return <Customers />;
      case 'reports':
        return <Reports />;
      case 'calendar':
        return <FinancialCalendar />;
      case 'checklist':
        return <SetupChecklist onNavigate={setCurrentTab} />;
      case 'settings':
        return <MoreSettings onNavigate={setCurrentTab} />;
      default:
        return <Dashboard onNavigate={setCurrentTab} />;
    }
  };

  return (
    <Layout currentTab={currentTab} onSelectTab={setCurrentTab}>
      {renderTabContent()}
    </Layout>
  );
};

export default function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <BusinessProvider>
          <InventoryProvider>
            <ExpenseProvider>
              <SalesProvider>
                <AppContent />
              </SalesProvider>
            </ExpenseProvider>
          </InventoryProvider>
        </BusinessProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}
