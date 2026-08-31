import React, { useState } from 'react';
import { 
  Wallet, 
  TrendingUp, 
  Box, 
  PlusSquare, 
  ShoppingCart, 
  AlertTriangle, 
  Percent, 
  ChevronRight, 
  Calendar as CalendarIcon,
  ListChecks,
  FileText,
  Layers,
  Store
} from 'lucide-react';
import { useSales } from '../../context/SalesContext';
import { useBusiness } from '../../context/BusinessContext';
import { useInventory } from '../../context/InventoryContext';
import { useExpenses } from '../../context/ExpenseContext';
import { DateFilterType } from '../../core/utils/date';
import { formatMoney } from '../../core/utils/currency';
import { Modal } from '../../components/ui/Modal';

interface DashboardProps {
  onNavigate: (tab: string) => void;
}

export const Dashboard: React.FC<DashboardProps> = ({ onNavigate }) => {
  const { getMetricsForFilter, sales } = useSales();
  const { profile } = useBusiness();
  const { products } = useInventory();
  const { expenses, addExpense } = useExpenses();

  const [dateFilter, setDateFilter] = useState<DateFilterType>('today');
  const [addExpenseModalOpen, setAddExpenseModalOpen] = useState<boolean>(false);

  // Expense form fields
  const [expLabel, setExpLabel] = useState<string>('');
  const [expAmount, setExpAmount] = useState<string>('');
  const [expCategory, setExpCategory] = useState<string>('Utilities');
  const [expType, setExpType] = useState<'fixed' | 'variable' | 'recurring'>('variable');
  const [expNote, setExpNote] = useState<string>('');

  const metrics = getMetricsForFilter(dateFilter);

  // Checklist dynamic calculation (matching Flutter dashboard_screen.dart)
  const productCount = products.length;
  const expenseCount = expenses.length;
  const hasClosedDays = (profile.closed_days || []).length > 0;

  let doneCount = 0;
  if (profile.logo_url && profile.logo_url !== '/logo.svg') doneCount++;
  if (profile.address && profile.phone) doneCount++;
  if (productCount > 0) doneCount++;
  doneCount++; // default order workflow
  if (expenseCount > 0) doneCount++;
  if (hasClosedDays) doneCount++;

  const totalChecklistItems = 6;
  const checklistComplete = doneCount >= totalChecklistItems;
  const progressPercent = Math.round((doneCount / totalChecklistItems) * 100);

  // Low stock calculation
  const lowStockCount = products.filter((p) => !p.is_service && p.stock_on_hand > 0 && p.stock_on_hand <= 5).length;
  const totalItemsSold = sales.reduce((sum, s) => sum + (s.items?.reduce((iSum, item) => iSum + item.quantity, 0) || 0), 0);

  const handleAddExpenseSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!expLabel || !expAmount) return;

    await addExpense({
      label: expLabel,
      amount: parseFloat(expAmount),
      category: expCategory,
      type: expType,
      spent_on: new Date().toISOString().split('T')[0],
      note: expNote,
      include_in_calculations: true,
    });

    setExpLabel('');
    setExpAmount('');
    setExpNote('');
    setAddExpenseModalOpen(false);
  };

  const periodOptions: Array<{ id: DateFilterType; label: string }> = [
    { id: 'today', label: 'Today' },
    { id: 'yesterday', label: 'Yesterday' },
    { id: 'this_week', label: 'Week' },
    { id: 'this_month', label: 'Month' },
    { id: 'all', label: 'Custom' },
  ];

  const getPeriodLabel = () => {
    switch (dateFilter) {
      case 'today': return 'TODAY';
      case 'yesterday': return 'YESTERDAY';
      case 'this_week': return 'WEEK';
      case 'this_month': return 'MONTH';
      default: return 'TODAY';
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-5 pb-24 animate-fade-in">
      {/* 1. Header: Logo Avatar + Shop Name */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-blue-600 to-blue-800 flex items-center justify-center shadow-lg shadow-blue-600/20 overflow-hidden border border-blue-400/30">
            {profile.logo_url && profile.logo_url !== '/logo.svg' ? (
              <img src={profile.logo_url} alt="Logo" className="w-full h-full object-cover" />
            ) : (
              <Store className="w-5 h-5 text-white" />
            )}
          </div>
          <div>
            <h1 className="text-xl font-extrabold text-white tracking-tight leading-none">
              {profile.business_name || 'DC Motorshop & Accessories'}
            </h1>
          </div>
        </div>

        <button
          onClick={() => onNavigate('reports')}
          className="px-3 py-1.5 rounded-xl bg-[#1c1c1c] hover:bg-[#252525] border border-[#2a2a2a] text-xs font-bold text-gray-300 hover:text-white flex items-center gap-1.5 transition-colors"
        >
          <FileText className="w-3.5 h-3.5 text-blue-400" />
          <span>Reports</span>
        </button>
      </div>

      {/* 2. Setup Checklist Banner (if not complete) */}
      {!checklistComplete && (
        <div
          onClick={() => onNavigate('checklist')}
          className="p-4 rounded-2xl bg-[#1a1814] border border-amber-500/30 hover:border-amber-500/50 transition-all cursor-pointer space-y-2.5 shadow-md shadow-amber-500/5"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="p-1.5 rounded-lg bg-amber-500/20 text-amber-400">
                <Store className="w-4 h-4" />
              </div>
              <span className="text-sm font-bold text-white">Finish setting up your shop</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="px-2.5 py-0.5 rounded-full bg-amber-500/20 text-amber-400 text-xs font-bold border border-amber-500/30">
                {progressPercent}%
              </span>
              <ChevronRight className="w-4 h-4 text-amber-400" />
            </div>
          </div>

          <div className="w-full h-1.5 bg-[#2a251e] rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-amber-500 to-amber-400 rounded-full transition-all duration-500"
              style={{ width: `${progressPercent}%` }}
            />
          </div>

          <p className="text-xs text-gray-400">
            {doneCount} of {totalChecklistItems} steps complete — tap to continue
          </p>
        </div>
      )}

      {/* 3. Period Selector (Horizontal Pill Scroll) */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none">
        {periodOptions.map((opt) => {
          const isSelected = dateFilter === opt.id;
          return (
            <button
              key={opt.id}
              onClick={() => setDateFilter(opt.id)}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all border ${
                isSelected
                  ? 'bg-blue-600 border-blue-500 text-white shadow-md shadow-blue-600/30'
                  : 'bg-blue-500/10 border-blue-500/20 text-gray-300 hover:text-white hover:bg-blue-500/20'
              }`}
            >
              {opt.label}
            </button>
          );
        })}
      </div>

      {/* 4. Revenue Hero Card (Exact Reference Image 9.jpg) */}
      <div
        onClick={() => onNavigate('reports')}
        className="p-6 rounded-3xl bg-gradient-to-br from-blue-600 via-blue-700 to-blue-900 border border-blue-400/30 shadow-2xl shadow-blue-600/25 text-white relative overflow-hidden cursor-pointer group transition-all"
      >
        <div className="flex items-center justify-between">
          <span className="text-[11px] font-bold tracking-widest text-white/80 uppercase">
            REVENUE · {getPeriodLabel()}
          </span>
          <ChevronRight className="w-5 h-5 text-white/80 group-hover:translate-x-1 transition-transform" />
        </div>

        <div className="mt-2.5">
          <div className="text-4xl sm:text-5xl font-black tracking-tight text-white drop-shadow-sm">
            {formatMoney(metrics.revenue)}
          </div>
          <div className="flex items-center gap-2 mt-2 text-xs font-medium text-white/80">
            <span>{metrics.salesCount} {metrics.salesCount === 1 ? 'sale' : 'sales'}</span>
            <span>·</span>
            <span>{formatMoney(metrics.avgTicket)} avg</span>
          </div>
        </div>

        {/* Sparkline curve visualization */}
        <div className="mt-5 pt-3 border-t border-white/10 flex items-end justify-between gap-1 h-10">
          {[25, 40, 30, 55, 45, 70, 60, 75, 90, metrics.revenue > 0 ? 100 : 20].map((h, idx) => (
            <div
              key={idx}
              className="flex-1 bg-white/20 hover:bg-white/40 rounded-t transition-all"
              style={{ height: `${h}%` }}
            />
          ))}
        </div>
      </div>

      {/* 5. AT A GLANCE (2x2 Grid, childAspectRatio: 1.15) */}
      <div className="space-y-3 pt-2">
        <h2 className="text-[11px] font-black uppercase tracking-widest text-gray-400">
          AT A GLANCE
        </h2>

        <div className="grid grid-cols-2 gap-3 sm:gap-4">
          {/* Gross Profit */}
          <div className="p-4 sm:p-5 rounded-2xl bg-[#141414] border border-[#262626] flex flex-col justify-between min-h-[120px] transition-all">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-gray-400">Gross Profit</span>
              <div className="p-1.5 rounded-xl bg-blue-500/10 text-blue-400 border border-blue-500/20">
                <Wallet className="w-4 h-4" />
              </div>
            </div>
            <span className="text-lg sm:text-xl font-black text-white">
              {formatMoney(metrics.grossProfit)}
            </span>
          </div>

          {/* Net Profit */}
          <div className="p-4 sm:p-5 rounded-2xl bg-[#141414] border border-[#262626] flex flex-col justify-between min-h-[120px] transition-all">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-gray-400">Net Profit</span>
              <div className="p-1.5 rounded-xl bg-blue-500/10 text-blue-400 border border-blue-500/20">
                <TrendingUp className="w-4 h-4" />
              </div>
            </div>
            <span className="text-lg sm:text-xl font-black text-white">
              {formatMoney(metrics.netProfit)}
            </span>
          </div>

          {/* Cost of Goods */}
          <div className="p-4 sm:p-5 rounded-2xl bg-[#141414] border border-[#262626] flex flex-col justify-between min-h-[120px] transition-all">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-gray-400">Cost of Goods</span>
              <div className="p-1.5 rounded-xl bg-blue-500/10 text-blue-400 border border-blue-500/20">
                <Box className="w-4 h-4" />
              </div>
            </div>
            <span className="text-lg sm:text-xl font-black text-white">
              {formatMoney(metrics.cogs)}
            </span>
          </div>

          {/* Expenses */}
          <div
            onClick={() => onNavigate('expenses')}
            className="p-4 sm:p-5 rounded-2xl bg-[#141414] border border-[#262626] hover:border-blue-500/40 flex flex-col justify-between min-h-[120px] transition-all cursor-pointer group"
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-gray-400">Expenses</span>
              <div className="p-1.5 rounded-xl bg-blue-500/10 text-blue-400 border border-blue-500/20 group-hover:bg-blue-600 group-hover:text-white transition-colors">
                <PlusSquare className="w-4 h-4" />
              </div>
            </div>
            <span className="text-base sm:text-lg font-black text-white">
              {metrics.expenses === 0 ? (
                <span className="text-xs font-semibold text-blue-400 group-hover:underline">
                  View details →
                </span>
              ) : (
                formatMoney(metrics.expenses)
              )}
            </span>
          </div>
        </div>
      </div>

      {/* 6. Bottom 3 Metric Cards Row (Items Sold, Low Stock, Margin) */}
      <div className="grid grid-cols-3 gap-2.5 sm:gap-3 pt-1">
        {/* Items Sold */}
        <div className="p-3.5 rounded-2xl bg-[#141414] border border-[#262626] flex items-center gap-2.5">
          <div className="p-2 rounded-xl bg-blue-500/10 text-blue-400 shrink-0">
            <ShoppingCart className="w-4 h-4" />
          </div>
          <div className="min-w-0">
            <span className="text-[10px] font-semibold text-gray-400 block truncate">Items Sold</span>
            <span className="text-sm sm:text-base font-black text-white">{totalItemsSold}</span>
          </div>
        </div>

        {/* Low Stock */}
        <div className="p-3.5 rounded-2xl bg-[#141414] border border-[#262626] flex items-center gap-2.5">
          <div className="p-2 rounded-xl bg-blue-500/10 text-blue-400 shrink-0">
            <AlertTriangle className="w-4 h-4" />
          </div>
          <div className="min-w-0">
            <span className="text-[10px] font-semibold text-gray-400 block truncate">Low Stock</span>
            <span className="text-sm sm:text-base font-black text-white">{lowStockCount}</span>
          </div>
        </div>

        {/* Margin */}
        <div className="p-3.5 rounded-2xl bg-[#141414] border border-[#262626] flex items-center gap-2.5">
          <div className="p-2 rounded-xl bg-blue-500/10 text-blue-400 shrink-0">
            <Percent className="w-4 h-4" />
          </div>
          <div className="min-w-0">
            <span className="text-[10px] font-semibold text-gray-400 block truncate">Margin</span>
            <span className="text-sm sm:text-base font-black text-white">
              {metrics.grossMarginPercent.toFixed(1)}%
            </span>
          </div>
        </div>
      </div>

      {/* ADD EXPENSE MODAL */}
      <Modal
        isOpen={addExpenseModalOpen}
        onClose={() => setAddExpenseModalOpen(false)}
        title="Record New Expense"
        subtitle="Track shop utilities, supplies, or operating costs"
        maxWidth="md"
      >
        <form onSubmit={handleAddExpenseSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
              Expense Label *
            </label>
            <input
              type="text"
              required
              placeholder="e.g. Electricity bill, Air compressor oil, Shop rent"
              value={expLabel}
              onChange={(e) => setExpLabel(e.target.value)}
              className="w-full px-4 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
                Amount (₱) *
              </label>
              <input
                type="number"
                step="0.01"
                min="0"
                required
                placeholder="0.00"
                value={expAmount}
                onChange={(e) => setExpAmount(e.target.value)}
                className="w-full px-4 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
                Category
              </label>
              <select
                value={expCategory}
                onChange={(e) => setExpCategory(e.target.value)}
                className="w-full px-3 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs font-medium text-white focus:outline-none focus:border-blue-500"
              >
                <option value="Utilities">Utilities (Power/Water)</option>
                <option value="Supplies">Shop Supplies & Tools</option>
                <option value="Rent">Shop Rent</option>
                <option value="Labor">Mechanic / Staff Wages</option>
                <option value="Maintenance">Equipment Maintenance</option>
                <option value="Other">Other Expenses</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
              Expense Type
            </label>
            <div className="grid grid-cols-3 gap-2">
              {(['variable', 'fixed', 'recurring'] as const).map((t) => (
                <button
                  key={t}
                  type="button"
                  onClick={() => setExpType(t)}
                  className={`py-2 text-xs font-bold rounded-xl uppercase transition-all ${
                    expType === t
                      ? 'bg-blue-600 text-white shadow-md'
                      : 'bg-[#1f1f1f] text-gray-400 hover:text-white border border-[#2e2e2e]'
                  }`}
                >
                  {t}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
              Note (Optional)
            </label>
            <textarea
              rows={2}
              placeholder="Additional details..."
              value={expNote}
              onChange={(e) => setExpNote(e.target.value)}
              className="w-full px-4 py-2 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-blue-500"
            />
          </div>

          <div className="flex gap-2 pt-2">
            <button
              type="button"
              onClick={() => setAddExpenseModalOpen(false)}
              className="flex-1 py-3 text-xs font-semibold text-gray-400 bg-[#222222] hover:bg-[#2a2a2a] rounded-xl"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 py-3 text-xs font-bold text-white bg-blue-600 hover:bg-blue-500 rounded-xl shadow-lg shadow-blue-600/30"
            >
              Save Expense
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
