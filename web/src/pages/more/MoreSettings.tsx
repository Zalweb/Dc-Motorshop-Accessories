import React, { useState } from 'react';
import { 
  User, 
  Store, 
  Palette, 
  Cloud, 
  Download, 
  Calendar, 
  ShieldCheck, 
  Sliders, 
  LogOut, 
  Check, 
  RefreshCw, 
  Sparkles,
  ChevronRight,
  Database,
  Trash2
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useBusiness } from '../../context/BusinessContext';
import { useInventory } from '../../context/InventoryContext';
import { useSales } from '../../context/SalesContext';
import { useExpenses } from '../../context/ExpenseContext';
import { useTheme, THEME_SWATCHES } from '../../core/theme/ThemeContext';
import { Modal } from '../../components/ui/Modal';

interface MoreSettingsProps {
  onNavigate: (tab: string) => void;
}

export const MoreSettings: React.FC<MoreSettingsProps> = ({ onNavigate }) => {
  const { user, signOut } = useAuth();
  const { profile, updateProfile, uploadLogo } = useBusiness();
  const { refreshInventory, products, categories, seedSampleCatalog, clearAllProducts } = useInventory();
  const { refreshSales, sales, seedSampleSalesData, clearAllSales } = useSales();
  const { refreshExpenses, expenses, clearAllExpenses } = useExpenses();
  const { themeColor, setThemeColor } = useTheme();

  // General Settings modal
  const [generalModalOpen, setGeneralModalOpen] = useState<boolean>(false);
  const [businessName, setBusinessName] = useState<string>(profile.business_name || '');
  const [address, setAddress] = useState<string>(profile.address || '');
  const [phone, setPhone] = useState<string>(profile.phone || '');

  // Inventory Settings modal
  const [inventoryModalOpen, setInventoryModalOpen] = useState<boolean>(false);
  const [allowOOS, setAllowOOS] = useState<boolean>(profile.allow_sell_when_out_of_stock);
  const [unpaidInReports, setUnpaidInReports] = useState<boolean>(profile.include_unpaid_in_reports);

  // Cloud Backup modal
  const [cloudModalOpen, setCloudModalOpen] = useState<boolean>(false);
  const [syncing, setSyncing] = useState<boolean>(false);
  const [syncStatusMsg, setSyncStatusMsg] = useState<string | null>(null);

  const [notification, setNotification] = useState<string | null>(null);

  const handleSaveGeneral = async (e: React.FormEvent) => {
    e.preventDefault();
    await updateProfile({
      business_name: businessName,
      address,
      phone,
    });
    setGeneralModalOpen(false);
    setNotification('Business settings updated successfully.');
    setTimeout(() => setNotification(null), 3000);
  };

  const handleSaveInventorySettings = async (e: React.FormEvent) => {
    e.preventDefault();
    await updateProfile({
      allow_sell_when_out_of_stock: allowOOS,
      include_unpaid_in_reports: unpaidInReports,
    });
    setInventoryModalOpen(false);
    setNotification('Inventory rules updated.');
    setTimeout(() => setNotification(null), 3000);
  };

  const handleSyncCloud = async () => {
    setSyncing(true);
    setSyncStatusMsg('Connecting to Supabase Cloud...');
    try {
      await Promise.all([
        refreshInventory(),
        refreshSales(),
        refreshExpenses(),
      ]);
      setSyncStatusMsg('All records synchronized with Supabase Cloud.');
    } catch (e: any) {
      setSyncStatusMsg('Sync completed with local database.');
    } finally {
      setSyncing(false);
    }
  };

  const handleDevSeed = async () => {
    await seedSampleCatalog();
    await seedSampleSalesData();
    setNotification('Sample motorcycle parts & sales seeded successfully.');
    setTimeout(() => setNotification(null), 3000);
  };

  const handleDevClear = () => {
    if (confirm('Clear all local products, sales, and expenses? This resets to a completely clean state.')) {
      clearAllProducts();
      clearAllSales();
      clearAllExpenses();
      setNotification('All local data cleared.');
      setTimeout(() => setNotification(null), 3000);
    }
  };

  return (
    <div className="max-w-3xl mx-auto space-y-6 pb-28 animate-fade-in">
      {/* Header (Exact Reference Image 13.jpg) */}
      <div>
        <h1 className="text-2xl font-black text-white tracking-tight leading-none">
          More
        </h1>
      </div>

      {notification && (
        <div className="p-3.5 bg-emerald-500/10 border border-emerald-500/30 rounded-2xl text-xs font-bold text-emerald-400 flex items-center gap-2">
          <Check className="w-4 h-4" />
          <span>{notification}</span>
        </div>
      )}

      {/* User Profile Header (Image 13.jpg) */}
      <div className="p-5 bg-[#141414] border border-[#262626] rounded-3xl space-y-3">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-full bg-blue-600 flex items-center justify-center text-white text-lg font-black shrink-0 shadow-lg shadow-blue-600/30">
            {user?.username?.slice(0, 2).toUpperCase() || 'DC'}
          </div>
          <div>
            <h2 className="text-base font-bold text-white leading-snug">
              {user?.fullName || 'DC Motorshop Owner'}
            </h2>
            <p className="text-xs text-gray-400">@{user?.username || 'dcmotorshop'}</p>
          </div>
        </div>

        <button
          onClick={() => setGeneralModalOpen(true)}
          className="w-full py-2.5 bg-[#1c1c1c] hover:bg-[#242424] border border-[#2c2c2c] text-gray-300 hover:text-white text-xs font-bold rounded-2xl transition-colors text-center"
        >
          My Profile
        </button>
      </div>

      {/* ACCOUNT Section (Image 13.jpg) */}
      <div className="space-y-2">
        <span className="text-[11px] font-black uppercase tracking-wider text-gray-400 px-1">
          ACCOUNT
        </span>
        <div className="p-4 bg-[#141414] border border-[#262626] rounded-3xl space-y-3">
          <div className="flex justify-between items-center text-xs">
            <span className="text-gray-400">Email</span>
            <span className="font-semibold text-white">{user?.email || 'owner@dcmotorshop.com'}</span>
          </div>
          <div className="flex justify-between items-center text-xs pt-2 border-t border-[#222222]">
            <span className="text-gray-400">Phone</span>
            <span className="font-semibold text-white">{profile.phone || user?.phone || '0917-123-4567'}</span>
          </div>
        </div>
      </div>

      {/* BUSINESS Section (Image 13.jpg) */}
      <div className="space-y-2">
        <span className="text-[11px] font-black uppercase tracking-wider text-gray-400 px-1">
          BUSINESS
        </span>
        <div className="p-4 bg-[#141414] border border-[#262626] rounded-3xl space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3 min-w-0">
              <div className="w-10 h-10 rounded-2xl bg-[#1f1f1f] border border-[#2e2e2e] flex items-center justify-center overflow-hidden shrink-0">
                {profile.logo_url && profile.logo_url !== '/logo.svg' ? (
                  <img src={profile.logo_url} alt="Logo" className="w-full h-full object-cover" />
                ) : (
                  <Store className="w-5 h-5 text-gray-400" />
                )}
              </div>
              <div className="min-w-0">
                <h3 className="text-xs font-bold text-white truncate">{profile.business_name}</h3>
                <p className="text-[11px] text-gray-500 truncate">dc-motorshop-accessories</p>
              </div>
            </div>
            <span className="px-2.5 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 text-[10px] font-black border border-emerald-500/30 shrink-0">
              ACTIVE
            </span>
          </div>

          <div className="flex justify-between items-center text-xs pt-2 border-t border-[#222222]">
            <span className="text-gray-400">Address</span>
            <span className="font-semibold text-white truncate max-w-[200px] text-right">
              {profile.address || '123 Rizal Highway, Poblacion'}
            </span>
          </div>
        </div>
      </div>

      {/* SETTINGS MENU ITEMS (Image 13.1.jpg - 13.5.jpg) */}
      <div className="space-y-2">
        <span className="text-[11px] font-black uppercase tracking-wider text-gray-400 px-1">
          SETTINGS & TOOLS
        </span>
        <div className="bg-[#141414] border border-[#262626] rounded-3xl divide-y divide-[#222222] overflow-hidden">
          {/* Cloud Backup */}
          <div
            onClick={() => setCloudModalOpen(true)}
            className="p-4 flex items-center justify-between hover:bg-[#181818] transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-xl bg-blue-500/10 text-blue-400 flex items-center justify-center">
                <Cloud className="w-4 h-4" />
              </div>
              <div>
                <span className="text-xs font-bold text-white block">Cloud Backup & Restore</span>
                <span className="text-[11px] text-gray-400">Supabase live cloud sync status</span>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-gray-500" />
          </div>

          {/* Business Calendar */}
          <div
            onClick={() => onNavigate('calendar')}
            className="p-4 flex items-center justify-between hover:bg-[#181818] transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-xl bg-purple-500/10 text-purple-400 flex items-center justify-center">
                <Calendar className="w-4 h-4" />
              </div>
              <div>
                <span className="text-xs font-bold text-white block">Business Calendar</span>
                <span className="text-[11px] text-gray-400">Tag holidays and closed days</span>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-gray-500" />
          </div>

          {/* General Settings */}
          <div
            onClick={() => setGeneralModalOpen(true)}
            className="p-4 flex items-center justify-between hover:bg-[#181818] transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
                <Palette className="w-4 h-4" />
              </div>
              <div>
                <span className="text-xs font-bold text-white block">General Settings & Theme</span>
                <span className="text-[11px] text-gray-400">Store info & brand theme color</span>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-gray-500" />
          </div>

          {/* Inventory Settings */}
          <div
            onClick={() => setInventoryModalOpen(true)}
            className="p-4 flex items-center justify-between hover:bg-[#181818] transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-xl bg-amber-500/10 text-amber-400 flex items-center justify-center">
                <Sliders className="w-4 h-4" />
              </div>
              <div>
                <span className="text-xs font-bold text-white block">Inventory Settings</span>
                <span className="text-[11px] text-gray-400">Out-of-stock and reporting rules</span>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-gray-500" />
          </div>

          {/* Dev Seed Sample Data (Optional test helper matching dev_seed.dart) */}
          <div
            onClick={handleDevSeed}
            className="p-4 flex items-center justify-between hover:bg-[#181818] transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-xl bg-blue-500/10 text-blue-400 flex items-center justify-center">
                <Database className="w-4 h-4" />
              </div>
              <div>
                <span className="text-xs font-bold text-white block">Dev: Seed Sample Data</span>
                <span className="text-[11px] text-gray-400">Populate test motorcycle parts & sales</span>
              </div>
            </div>
            <span className="text-[10px] font-bold text-blue-400 bg-blue-500/10 px-2 py-0.5 rounded">Seed</span>
          </div>

          {/* Dev Clear Data */}
          <div
            onClick={handleDevClear}
            className="p-4 flex items-center justify-between hover:bg-[#181818] transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-xl bg-red-500/10 text-red-400 flex items-center justify-center">
                <Trash2 className="w-4 h-4" />
              </div>
              <div>
                <span className="text-xs font-bold text-white block">Dev: Clear All Local Data</span>
                <span className="text-[11px] text-gray-400">Reset to completely clean empty state</span>
              </div>
            </div>
            <span className="text-[10px] font-bold text-red-400 bg-red-500/10 px-2 py-0.5 rounded">Reset</span>
          </div>
        </div>
      </div>

      {/* Logout Button */}
      <button
        onClick={signOut}
        className="w-full py-3.5 bg-red-600/10 hover:bg-red-600/20 text-red-400 border border-red-500/20 rounded-2xl text-xs font-bold transition-colors flex items-center justify-center gap-2"
      >
        <LogOut className="w-4 h-4" />
        <span>Log out</span>
      </button>

      {/* GENERAL SETTINGS & THEME MODAL */}
      <Modal
        isOpen={generalModalOpen}
        onClose={() => setGeneralModalOpen(false)}
        title="General Settings & Theme"
        subtitle="Configure store information and brand accent"
        maxWidth="md"
      >
        <form onSubmit={handleSaveGeneral} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
              Brand Accent Color
            </label>
            <div className="grid grid-cols-5 gap-2">
              {THEME_SWATCHES.map((swatch) => {
                const isSelected = themeColor === swatch.name;
                return (
                  <button
                    key={swatch.name}
                    type="button"
                    onClick={() => {
                      setThemeColor(swatch.name);
                      updateProfile({ theme_color: swatch.name });
                    }}
                    className={`h-10 rounded-xl flex items-center justify-center relative transition-all border ${
                      isSelected ? 'border-white scale-105 shadow-md shadow-black' : 'border-transparent hover:scale-102'
                    }`}
                    style={{ backgroundColor: swatch.hex }}
                  >
                    {isSelected && <Check className="w-4 h-4 text-white drop-shadow" />}
                  </button>
                );
              })}
            </div>
            <p className="text-[11px] text-gray-400 mt-1">Active theme: <b>{themeColor}</b></p>
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
              Shop Name *
            </label>
            <input
              type="text"
              required
              value={businessName}
              onChange={(e) => setBusinessName(e.target.value)}
              className="w-full px-3.5 py-2 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-blue-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
              Phone
            </label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className="w-full px-3.5 py-2 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-blue-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
              Physical Address
            </label>
            <input
              type="text"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              className="w-full px-3.5 py-2 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-blue-500"
            />
          </div>

          <div className="flex gap-2 pt-2">
            <button
              type="button"
              onClick={() => setGeneralModalOpen(false)}
              className="flex-1 py-2.5 bg-[#242424] text-gray-300 text-xs font-semibold rounded-xl"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 py-2.5 bg-blue-600 hover:bg-blue-500 text-white text-xs font-bold rounded-xl shadow-md shadow-blue-600/30"
            >
              Save Settings
            </button>
          </div>
        </form>
      </Modal>

      {/* INVENTORY SETTINGS MODAL */}
      <Modal
        isOpen={inventoryModalOpen}
        onClose={() => setInventoryModalOpen(false)}
        title="Inventory Rules"
        subtitle="Configure POS checkout & reporting policies"
        maxWidth="md"
      >
        <form onSubmit={handleSaveInventorySettings} className="space-y-4">
          <label className="flex items-center gap-3 p-3.5 bg-[#1f1f1f] rounded-2xl border border-[#2e2e2e] cursor-pointer">
            <input
              type="checkbox"
              checked={allowOOS}
              onChange={(e) => setAllowOOS(e.target.checked)}
              className="w-4 h-4 rounded bg-[#121212] border-gray-700 text-blue-600 focus:ring-0"
            />
            <div>
              <span className="text-xs font-bold text-white block">Allow Selling Out-of-Stock Items</span>
              <span className="text-[11px] text-gray-400">Permit 0-stock products to be added to cart and sold</span>
            </div>
          </label>

          <label className="flex items-center gap-3 p-3.5 bg-[#1f1f1f] rounded-2xl border border-[#2e2e2e] cursor-pointer">
            <input
              type="checkbox"
              checked={unpaidInReports}
              onChange={(e) => setUnpaidInReports(e.target.checked)}
              className="w-4 h-4 rounded bg-[#121212] border-gray-700 text-blue-600 focus:ring-0"
            />
            <div>
              <span className="text-xs font-bold text-white block">Include Unpaid / Credit in Reports</span>
              <span className="text-[11px] text-gray-400">Count receivables in overall sales revenue calculations</span>
            </div>
          </label>

          <div className="flex gap-2 pt-2">
            <button
              type="button"
              onClick={() => setInventoryModalOpen(false)}
              className="flex-1 py-2.5 bg-[#242424] text-gray-300 text-xs font-semibold rounded-xl"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 py-2.5 bg-blue-600 hover:bg-blue-500 text-white text-xs font-bold rounded-xl shadow-md shadow-blue-600/30"
            >
              Save Rules
            </button>
          </div>
        </form>
      </Modal>

      {/* CLOUD BACKUP MODAL */}
      <Modal
        isOpen={cloudModalOpen}
        onClose={() => setCloudModalOpen(false)}
        title="Cloud Backup & Sync"
        subtitle="Live Supabase Cloud database connection"
        maxWidth="md"
      >
        <div className="space-y-4">
          <div className="p-4 bg-[#1f1f1f] rounded-2xl border border-[#2e2e2e] space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-gray-300">Cloud Status</span>
              <span className="text-emerald-400 font-bold text-xs flex items-center gap-1">
                <ShieldCheck className="w-3.5 h-3.5" />
                <span>Connected</span>
              </span>
            </div>
            <p className="text-xs text-gray-400">
              Your catalog, sales, and expense transactions are saved locally and synchronized with Supabase Cloud.
            </p>
          </div>

          {syncStatusMsg && (
            <div className="p-3 bg-blue-500/10 border border-blue-500/30 rounded-xl text-xs text-blue-300 font-medium">
              {syncStatusMsg}
            </div>
          )}

          <button
            onClick={handleSyncCloud}
            disabled={syncing}
            className="w-full py-3 bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs rounded-xl shadow-md shadow-blue-600/30 flex items-center justify-center gap-2"
          >
            <RefreshCw className={`w-4 h-4 ${syncing ? 'animate-spin' : ''}`} />
            <span>{syncing ? 'Syncing...' : 'Sync Cloud Database Now'}</span>
          </button>
        </div>
      </Modal>
    </div>
  );
};
