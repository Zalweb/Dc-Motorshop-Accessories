import React, { useState } from 'react';
import { Wallet, Plus, Trash2, Calendar, Search, Filter } from 'lucide-react';
import { useExpenses } from '../../context/ExpenseContext';
import { formatMoney } from '../../core/utils/currency';
import { formatDate } from '../../core/utils/date';
import { Expense } from '../../core/types';
import { Modal } from '../../components/ui/Modal';

export const Expenses: React.FC = () => {
  const { expenses, addExpense, deleteExpense, totalExpenses } = useExpenses();

  const [searchQuery, setSearchQuery] = useState<string>('');
  const [categoryFilter, setCategoryFilter] = useState<string>('ALL');
  const [modalOpen, setModalOpen] = useState<boolean>(false);

  // Form states
  const [label, setLabel] = useState<string>('');
  const [amount, setAmount] = useState<string>('');
  const [category, setCategory] = useState<string>('Utilities');
  const [type, setType] = useState<'fixed' | 'variable' | 'recurring'>('variable');
  const [spentOn, setSpentOn] = useState<string>(new Date().toISOString().split('T')[0]);
  const [note, setNote] = useState<string>('');

  const filteredExpenses = expenses.filter((e) => {
    if (categoryFilter !== 'ALL' && e.category !== categoryFilter) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      return e.label.toLowerCase().includes(q) || e.category?.toLowerCase().includes(q);
    }
    return true;
  });

  const handleAddSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!label.trim() || !amount) return;

    await addExpense({
      label: label.trim(),
      amount: parseFloat(amount) || 0,
      category,
      type,
      spent_on: spentOn,
      note: note.trim() || null,
      include_in_calculations: true,
    });

    setLabel('');
    setAmount('');
    setNote('');
    setModalOpen(false);
  };

  const categoriesList = ['ALL', 'Utilities', 'Supplies', 'Rent', 'Labor', 'Maintenance', 'Other'];

  return (
    <div className="max-w-5xl mx-auto space-y-6 pb-24 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-black text-white tracking-tight">Shop Expenses</h1>
          <p className="text-xs text-gray-400">
            Total recorded: <span className="text-amber-400 font-bold">{formatMoney(totalExpenses)}</span>
          </p>
        </div>

        <button
          onClick={() => setModalOpen(true)}
          className="px-4 py-2.5 bg-amber-500 hover:bg-amber-400 text-black font-bold text-xs rounded-xl shadow-lg shadow-amber-500/20 flex items-center gap-1.5 transition-all active:scale-95"
        >
          <Plus className="w-4 h-4" />
          <span>Record Expense</span>
        </button>
      </div>

      {/* Filter Bar */}
      <div className="p-4 bg-[#141414] border border-[#262626] rounded-2xl flex flex-col sm:flex-row items-center gap-3">
        <div className="relative flex-1 w-full">
          <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search expenses by label or category..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-xs text-white placeholder-gray-500 focus:outline-none focus:border-amber-500 transition-colors"
          />
        </div>

        <div className="flex items-center gap-2 overflow-x-auto w-full sm:w-auto pb-1 sm:pb-0 scrollbar-none">
          {categoriesList.map((cat) => (
            <button
              key={cat}
              onClick={() => setCategoryFilter(cat)}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
                categoryFilter === cat
                  ? 'bg-amber-500 text-black'
                  : 'bg-[#1c1c1c] text-gray-400 hover:text-white border border-[#2a2a2a]'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      {/* Expense List */}
      {filteredExpenses.length > 0 ? (
        <div className="bg-[#141414] border border-[#262626] rounded-3xl divide-y divide-[#222222] overflow-hidden shadow-xl">
          {filteredExpenses.map((exp) => (
            <div
              key={exp.id}
              className="p-4 flex items-center justify-between hover:bg-[#181818] transition-colors"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-400 flex items-center justify-center">
                  <Wallet className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="text-sm font-bold text-white">{exp.label}</h4>
                  <div className="flex items-center gap-2 mt-0.5 text-xs text-gray-400">
                    <span>{formatDate(exp.spent_on)}</span>
                    <span>•</span>
                    <span className="text-gray-300 font-semibold">{exp.category || 'General'}</span>
                    <span>•</span>
                    <span className="uppercase text-[10px] font-bold text-amber-400 bg-amber-400/10 px-1.5 py-0.2 rounded">
                      {exp.type}
                    </span>
                  </div>
                  {exp.note && <p className="text-[11px] text-gray-500 mt-1">{exp.note}</p>}
                </div>
              </div>

              <div className="flex items-center gap-3">
                <span className="text-base font-black text-amber-400">
                  {formatMoney(exp.amount)}
                </span>
                <button
                  onClick={() => {
                    if (confirm(`Delete expense "${exp.label}"?`)) deleteExpense(exp.id);
                  }}
                  className="p-2 text-gray-500 hover:text-red-400 transition-colors"
                  title="Delete"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="p-16 text-center bg-[#141414] border border-[#262626] rounded-3xl">
          <Wallet className="w-12 h-12 text-gray-600 mx-auto mb-3" />
          <h3 className="text-sm font-bold text-white">No expenses recorded</h3>
          <p className="text-xs text-gray-400 mt-1">
            Track overhead costs, supplies, and utilities by clicking "Record Expense".
          </p>
        </div>
      )}

      {/* ADD EXPENSE MODAL */}
      <Modal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        title="Record Shop Expense"
        subtitle="Track operating overhead, tools, and bills"
        maxWidth="md"
      >
        <form onSubmit={handleAddSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
              Expense Label *
            </label>
            <input
              type="text"
              required
              placeholder="e.g. Shop compressor maintenance, Shop rent"
              value={label}
              onChange={(e) => setLabel(e.target.value)}
              className="w-full px-4 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-sm text-white focus:outline-none focus:border-amber-500 font-medium"
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
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="w-full px-4 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-sm text-amber-400 font-bold focus:outline-none focus:border-amber-500"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
                Category
              </label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="w-full px-3 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-amber-500"
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

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
                Date Spent
              </label>
              <input
                type="date"
                required
                value={spentOn}
                onChange={(e) => setSpentOn(e.target.value)}
                className="w-full px-3.5 py-2 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-amber-500"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
                Type
              </label>
              <select
                value={type}
                onChange={(e) => setType(e.target.value as any)}
                className="w-full px-3 py-2 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-amber-500"
              >
                <option value="variable">Variable</option>
                <option value="fixed">Fixed</option>
                <option value="recurring">Recurring</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
              Note (Optional)
            </label>
            <textarea
              rows={2}
              placeholder="Additional expense details..."
              value={note}
              onChange={(e) => setNote(e.target.value)}
              className="w-full px-4 py-2 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-amber-500"
            />
          </div>

          <div className="flex gap-2 pt-2">
            <button
              type="button"
              onClick={() => setModalOpen(false)}
              className="flex-1 py-3 text-xs font-semibold text-gray-400 bg-[#222222] hover:bg-[#2a2a2a] rounded-xl"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 py-3 text-xs font-bold text-black bg-amber-400 hover:bg-amber-300 rounded-xl shadow-lg shadow-amber-500/20"
            >
              Save Expense
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
