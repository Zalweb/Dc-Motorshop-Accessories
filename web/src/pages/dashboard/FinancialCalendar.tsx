import React, { useState } from 'react';
import { Calendar as CalendarIcon, ChevronLeft, ChevronRight, Plus, Trash2, Tag, AlertTriangle } from 'lucide-react';
import { useBusiness } from '../../context/BusinessContext';
import { useSales } from '../../context/SalesContext';
import { useExpenses } from '../../context/ExpenseContext';
import { formatMoney } from '../../core/utils/currency';
import { Modal } from '../../components/ui/Modal';
import { ClosedDay } from '../../core/types';

export const FinancialCalendar: React.FC = () => {
  const { profile, addClosedDay, removeClosedDay } = useBusiness();
  const { sales } = useSales();
  const { expenses } = useExpenses();

  const [currentDate, setCurrentDate] = useState<Date>(new Date());
  const [selectedDayString, setSelectedDayString] = useState<string | null>(null);
  const [addReasonModalOpen, setAddReasonModalOpen] = useState<boolean>(false);
  const [reasonType, setReasonType] = useState<ClosedDay['reason']>('holiday');
  const [reasonNote, setReasonNote] = useState<string>('');

  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();

  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  const firstDayIndex = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();

  const prevMonth = () => setCurrentDate(new Date(year, month - 1, 1));
  const nextMonth = () => setCurrentDate(new Date(year, month + 1, 1));

  // Map closed days
  const closedDaysMap: Record<string, ClosedDay> = {};
  (profile.closed_days || []).forEach((cd) => {
    closedDaysMap[cd.date] = cd;
  });

  // Map sales by YYYY-MM-DD
  const salesByDate: Record<string, number> = {};
  sales.forEach((s) => {
    const d = s.created_at.split('T')[0];
    salesByDate[d] = (salesByDate[d] || 0) + s.total;
  });

  // Map expenses by YYYY-MM-DD
  const expensesByDate: Record<string, number> = {};
  expenses.forEach((e) => {
    expensesByDate[e.spent_on] = (expensesByDate[e.spent_on] || 0) + e.amount;
  });

  const handleSaveClosedDay = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedDayString) return;

    await addClosedDay({
      date: selectedDayString,
      reason: reasonType,
      note: reasonNote.trim() || undefined,
    });

    setAddReasonModalOpen(false);
    setReasonNote('');
  };

  const selectedClosedDay = selectedDayString ? closedDaysMap[selectedDayString] : undefined;
  const selectedSalesTotal = selectedDayString ? salesByDate[selectedDayString] || 0 : 0;
  const selectedExpensesTotal = selectedDayString ? expensesByDate[selectedDayString] || 0 : 0;

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-24 animate-fade-in">
      {/* Header Bar */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-black text-white tracking-tight">Business & Financial Calendar</h1>
          <p className="text-xs text-gray-400">Track operating revenue, daily expenses, and scheduled shop closed days</p>
        </div>

        {/* Month Navigation */}
        <div className="flex items-center gap-2 bg-[#171717] border border-[#282828] p-1 rounded-2xl">
          <button
            onClick={prevMonth}
            className="p-2 text-gray-400 hover:text-white hover:bg-[#242424] rounded-xl transition-colors"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>
          <span className="text-xs font-bold text-white px-3">
            {monthNames[month]} {year}
          </span>
          <button
            onClick={nextMonth}
            className="p-2 text-gray-400 hover:text-white hover:bg-[#242424] rounded-xl transition-colors"
          >
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Calendar Grid */}
      <div className="p-5 rounded-3xl bg-[#141414] border border-[#262626] shadow-xl space-y-3">
        {/* Day Header */}
        <div className="grid grid-cols-7 gap-1 text-center text-[11px] font-bold text-gray-500 uppercase tracking-wider pb-2 border-b border-[#222222]">
          <span>Sun</span>
          <span>Mon</span>
          <span>Tue</span>
          <span>Wed</span>
          <span>Thu</span>
          <span>Fri</span>
          <span>Sat</span>
        </div>

        {/* Calendar Cells */}
        <div className="grid grid-cols-7 gap-1.5 sm:gap-2">
          {/* Empty cells for leading days */}
          {Array.from({ length: firstDayIndex }).map((_, i) => (
            <div key={`empty-${i}`} className="min-h-[70px] sm:min-h-[90px] rounded-2xl bg-[#0e0e0e]/50 border border-transparent" />
          ))}

          {/* Actual Month Days */}
          {Array.from({ length: daysInMonth }).map((_, i) => {
            const dayNum = i + 1;
            const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(dayNum).padStart(2, '0')}`;
            const closed = closedDaysMap[dateStr];
            const dayRevenue = salesByDate[dateStr] || 0;
            const dayExpense = expensesByDate[dateStr] || 0;
            const isToday = new Date().toISOString().split('T')[0] === dateStr;

            return (
              <div
                key={dateStr}
                onClick={() => setSelectedDayString(dateStr)}
                className={`min-h-[70px] sm:min-h-[90px] p-2 rounded-2xl border transition-all flex flex-col justify-between cursor-pointer group ${
                  isToday
                    ? 'border-blue-500 bg-[#1a2135]'
                    : closed
                    ? 'border-red-500/30 bg-red-950/20 hover:border-red-500/50'
                    : 'border-[#222222] bg-[#171717] hover:border-gray-600 hover:bg-[#1b1b1b]'
                }`}
              >
                <div className="flex items-center justify-between">
                  <span
                    className={`text-xs font-black ${
                      isToday
                        ? 'text-blue-400'
                        : closed
                        ? 'text-red-400'
                        : 'text-gray-300 group-hover:text-white'
                    }`}
                  >
                    {dayNum}
                  </span>
                  {closed && (
                    <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" title={closed.reason} />
                  )}
                </div>

                <div className="space-y-0.5 mt-1 text-[10px]">
                  {dayRevenue > 0 && (
                    <p className="font-bold text-emerald-400 truncate">
                      +{formatMoney(dayRevenue)}
                    </p>
                  )}
                  {dayExpense > 0 && (
                    <p className="font-bold text-amber-400 truncate">
                      -{formatMoney(dayExpense)}
                    </p>
                  )}
                  {closed && (
                    <p className="font-semibold text-red-300 uppercase text-[9px] truncate">
                      Closed
                    </p>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* DATE DETAILS / TAG CLOSED DAY MODAL */}
      <Modal
        isOpen={!!selectedDayString}
        onClose={() => setSelectedDayString(null)}
        title={`Date Details — ${selectedDayString}`}
        subtitle="Daily financial summary & operational status"
        maxWidth="md"
      >
        {selectedDayString && (
          <div className="space-y-4">
            {/* Financials for selected date */}
            <div className="grid grid-cols-2 gap-3">
              <div className="p-3.5 bg-[#1f1f1f] rounded-2xl border border-[#2e2e2e]">
                <span className="text-[10px] font-bold text-gray-400 uppercase">Sales Revenue</span>
                <p className="text-base font-black text-emerald-400 mt-0.5">{formatMoney(selectedSalesTotal)}</p>
              </div>
              <div className="p-3.5 bg-[#1f1f1f] rounded-2xl border border-[#2e2e2e]">
                <span className="text-[10px] font-bold text-gray-400 uppercase">Recorded Expenses</span>
                <p className="text-base font-black text-amber-400 mt-0.5">{formatMoney(selectedExpensesTotal)}</p>
              </div>
            </div>

            {/* Closed Day Status */}
            <div className="p-4 bg-[#1a1a1a] rounded-2xl border border-[#2a2a2a] space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-gray-300 uppercase tracking-wider">Shop Operating Status</span>
                {selectedClosedDay ? (
                  <span className="px-2.5 py-0.5 rounded-full bg-red-500/20 text-red-400 border border-red-500/30 text-[10px] font-bold uppercase">
                    Closed: {selectedClosedDay.reason}
                  </span>
                ) : (
                  <span className="px-2.5 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 text-[10px] font-bold">
                    Open for Business
                  </span>
                )}
              </div>

              {selectedClosedDay ? (
                <div className="space-y-2">
                  {selectedClosedDay.note && (
                    <p className="text-xs text-gray-300 bg-[#222222] p-2.5 rounded-xl">
                      {selectedClosedDay.note}
                    </p>
                  )}
                  <button
                    onClick={async () => {
                      await removeClosedDay(selectedClosedDay.id);
                      setSelectedDayString(null);
                    }}
                    className="w-full py-2.5 bg-red-600/20 hover:bg-red-600 text-red-400 hover:text-white text-xs font-bold rounded-xl border border-red-500/30 transition-colors flex items-center justify-center gap-1.5"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                    <span>Mark as Open Day</span>
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => setAddReasonModalOpen(true)}
                  className="w-full py-2.5 bg-[#242424] hover:bg-[#2e2e2e] text-gray-300 text-xs font-bold rounded-xl border border-[#333333] transition-colors flex items-center justify-center gap-1.5"
                >
                  <Tag className="w-3.5 h-3.5 text-amber-400" />
                  <span>Tag as Closed Day (Holiday / Day Off)</span>
                </button>
              )}
            </div>

            <button
              onClick={() => setSelectedDayString(null)}
              className="w-full py-2.5 bg-[#242424] hover:bg-[#2c2c2c] text-gray-300 text-xs font-bold rounded-xl transition-colors"
            >
              Done
            </button>
          </div>
        )}
      </Modal>

      {/* REASON MODAL */}
      <Modal
        isOpen={addReasonModalOpen}
        onClose={() => setAddReasonModalOpen(false)}
        title="Tag Closed Day Reason"
        subtitle={`Date: ${selectedDayString}`}
        maxWidth="sm"
      >
        <form onSubmit={handleSaveClosedDay} className="space-y-3">
          <div>
            <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5">
              Reason
            </label>
            <select
              value={reasonType}
              onChange={(e) => setReasonType(e.target.value as any)}
              className="w-full px-3.5 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none"
            >
              <option value="holiday">Official Holiday</option>
              <option value="day_off">Shop Weekly Day Off</option>
              <option value="maintenance">Shop Maintenance / Renovation</option>
              <option value="other">Other Reason</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5">
              Note (Optional)
            </label>
            <input
              type="text"
              placeholder="e.g. Rizal Day, Barangay Fiesta"
              value={reasonNote}
              onChange={(e) => setReasonNote(e.target.value)}
              className="w-full px-3.5 py-2 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none"
            />
          </div>

          <div className="flex gap-2 pt-2">
            <button
              type="button"
              onClick={() => setAddReasonModalOpen(false)}
              className="flex-1 py-2 text-xs text-gray-400 bg-[#222222] rounded-xl"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 py-2 text-xs font-bold text-white bg-red-600 hover:bg-red-500 rounded-xl"
            >
              Save Closed Day
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
