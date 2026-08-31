import React, { useState } from 'react';
import { 
  Search, 
  Receipt, 
  Download, 
  Printer, 
  CheckCircle2, 
  Filter
} from 'lucide-react';
import { useSales } from '../../context/SalesContext';
import { formatMoney } from '../../core/utils/currency';
import { formatDateTime, DateFilterType } from '../../core/utils/date';
import { Sale } from '../../core/types';
import { ReceiptModal } from '../../components/ui/ReceiptModal';
import { Modal } from '../../components/ui/Modal';

export const SalesHistory: React.FC = () => {
  const { getFilteredSales, exportSales, markSalePaid } = useSales();

  const [searchQuery, setSearchQuery] = useState<string>('');
  const [dateFilter, setDateFilter] = useState<DateFilterType>('today');
  const [statusFilter, setStatusFilter] = useState<'all' | 'paid' | 'unpaid'>('all');
  const [selectedSale, setSelectedSale] = useState<Sale | null>(null);
  const [receiptSale, setReceiptSale] = useState<Sale | null>(null);

  const filteredSales = getFilteredSales(dateFilter, searchQuery).filter((sale) => {
    if (statusFilter === 'all') return true;
    return sale.status === statusFilter;
  });

  const getEmptyTitle = () => {
    switch (dateFilter) {
      case 'today': return 'No sales today';
      case 'yesterday': return 'No sales yesterday';
      default: return 'No sales found';
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-4 pb-28 animate-fade-in">
      {/* Header (Image 10.jpg) */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-black text-white tracking-tight leading-none">
            Sales History
          </h1>
          <p className="text-xs text-gray-400 mt-1">
            {filteredSales.length} {filteredSales.length === 1 ? 'sale' : 'sales'} recorded
          </p>
        </div>

        {filteredSales.length > 0 && (
          <button
            onClick={() => exportSales(filteredSales)}
            className="px-3.5 py-2 rounded-xl bg-[#1c1c1c] hover:bg-[#252525] border border-[#2e2e2e] text-xs font-bold text-gray-300 hover:text-white flex items-center gap-1.5 transition-colors"
          >
            <Download className="w-4 h-4 text-emerald-400" />
            <span>Export Excel</span>
          </button>
        )}
      </div>

      {/* Search Bar + Period Filter (Image 10.jpg) */}
      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search by sale number or customer..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-3 bg-[#141414] border border-[#262626] rounded-2xl text-xs text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 shadow-sm"
          />
        </div>

        <select
          value={dateFilter}
          onChange={(e) => setDateFilter(e.target.value as DateFilterType)}
          className="appearance-none bg-[#141414] border border-[#262626] rounded-2xl px-3.5 py-3 text-xs font-bold text-gray-300 focus:outline-none focus:border-blue-500 cursor-pointer"
        >
          <option value="today">Today</option>
          <option value="yesterday">Yesterday</option>
          <option value="this_week">This Week</option>
          <option value="this_month">This Month</option>
          <option value="all">All Time</option>
        </select>
      </div>

      {/* Sales List / Empty State (Exact Reference Image 10.jpg) */}
      {filteredSales.length > 0 ? (
        <div className="space-y-2.5">
          {filteredSales.map((sale) => {
            const itemCount = sale.items?.reduce((sum, i) => sum + i.quantity, 0) || 0;

            return (
              <div
                key={sale.id}
                onClick={() => setSelectedSale(sale)}
                className="p-4 rounded-2xl bg-[#141414] border border-[#262626] hover:border-gray-600 transition-all flex items-center justify-between cursor-pointer group"
              >
                <div className="flex items-center gap-3 min-w-0">
                  <div className="w-10 h-10 rounded-xl bg-[#1f1f1f] border border-[#2e2e2e] flex items-center justify-center text-blue-400 shrink-0">
                    <Receipt className="w-5 h-5" />
                  </div>

                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-bold text-white">{sale.sale_number}</span>
                      {sale.status === 'unpaid' ? (
                        <span className="text-[10px] font-bold px-2 py-0.2 rounded bg-amber-500/20 text-amber-400 border border-amber-500/30">
                          UNPAID
                        </span>
                      ) : sale.status === 'partial' ? (
                        <span className="text-[10px] font-bold px-2 py-0.2 rounded bg-blue-500/20 text-blue-400 border border-blue-500/30">
                          PARTIAL
                        </span>
                      ) : (
                        <span className="text-[10px] font-bold px-2 py-0.2 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                          PAID
                        </span>
                      )}
                    </div>

                    <p className="text-xs text-gray-400 mt-0.5 truncate">
                      {sale.customer_name || 'Walk-in Customer'} · {itemCount} {itemCount === 1 ? 'item' : 'items'}
                    </p>
                    <p className="text-[10px] text-gray-500 mt-0.5">
                      {formatDateTime(sale.created_at)}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-3 shrink-0">
                  <div className="text-right">
                    <span className="text-base font-black text-blue-400 block">
                      {formatMoney(sale.total)}
                    </span>
                    <span className="text-[10px] font-semibold text-gray-500 uppercase">
                      {sale.payment_method}
                    </span>
                  </div>

                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      setReceiptSale(sale);
                    }}
                    className="p-2 rounded-xl bg-[#1f1f1f] hover:bg-blue-600 hover:text-white text-gray-400 transition-colors"
                    title="Print Receipt"
                  >
                    <Printer className="w-4 h-4" />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        /* Empty State (Exact Reference Image 10.jpg) */
        <div className="py-20 text-center space-y-3">
          <div className="w-16 h-16 rounded-3xl bg-[#141414] border border-[#262626] flex items-center justify-center mx-auto text-gray-500">
            <Receipt className="w-8 h-8" />
          </div>
          <div>
            <h3 className="text-base font-bold text-white">{getEmptyTitle()}</h3>
            <p className="text-xs text-gray-400 mt-0.5">New sales today will show up here.</p>
          </div>
        </div>
      )}

      {/* SALE DETAIL MODAL */}
      <Modal
        isOpen={!!selectedSale}
        onClose={() => setSelectedSale(null)}
        title={`Sale Details — ${selectedSale?.sale_number}`}
        subtitle={formatDateTime(selectedSale?.created_at)}
        maxWidth="lg"
      >
        {selectedSale && (
          <div className="space-y-4">
            <div className="p-3.5 bg-[#1f1f1f] rounded-2xl border border-[#2e2e2e] flex items-center justify-between">
              <div>
                <span className="text-[10px] text-gray-400 font-bold uppercase">Customer</span>
                <p className="text-sm font-bold text-white">{selectedSale.customer_name || 'Walk-in'}</p>
              </div>
              <div className="text-right">
                <span className="text-[10px] text-gray-400 font-bold uppercase">Payment</span>
                <p className="text-xs font-bold text-emerald-400 uppercase">{selectedSale.payment_method}</p>
              </div>
            </div>

            <div className="space-y-2">
              <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">Line Items</h4>
              <div className="bg-[#1c1c1c] border border-[#2a2a2a] rounded-2xl divide-y divide-[#262626] overflow-hidden">
                {selectedSale.items?.map((item) => (
                  <div key={item.id} className="p-3 flex items-center justify-between text-xs">
                    <div>
                      <p className="font-bold text-white">{item.name}</p>
                      <p className="text-[11px] text-gray-400">
                        {item.quantity} x {formatMoney(item.unit_price)} (Cost: {formatMoney(item.unit_cost)})
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="font-bold text-white">{formatMoney(item.line_total)}</p>
                      <p className="text-[10px] text-emerald-400">
                        Profit: +{formatMoney(item.line_total - item.unit_cost * item.quantity)}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="p-3.5 bg-[#191919] rounded-2xl border border-[#282828] space-y-1.5 text-xs">
              <div className="flex justify-between text-gray-400">
                <span>Subtotal</span>
                <span>{formatMoney(selectedSale.subtotal)}</span>
              </div>
              {selectedSale.discount > 0 && (
                <div className="flex justify-between text-purple-400">
                  <span>Discount</span>
                  <span>-{formatMoney(selectedSale.discount)}</span>
                </div>
              )}
              <div className="flex justify-between font-black text-white text-sm pt-2 border-t border-[#2a2a2a]">
                <span>Total Amount</span>
                <span className="text-blue-400">{formatMoney(selectedSale.total)}</span>
              </div>
            </div>

            {selectedSale.status === 'unpaid' && (
              <button
                onClick={async () => {
                  await markSalePaid(selectedSale.id);
                  setSelectedSale({ ...selectedSale, status: 'paid' });
                }}
                className="w-full py-3 bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs rounded-xl shadow-lg shadow-emerald-600/30 transition-all flex items-center justify-center gap-2"
              >
                <CheckCircle2 className="w-4 h-4" />
                <span>Mark as Fully Paid</span>
              </button>
            )}

            <div className="flex gap-2 pt-2">
              <button
                onClick={() => {
                  setReceiptSale(selectedSale);
                  setSelectedSale(null);
                }}
                className="flex-1 py-2.5 bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs rounded-xl flex items-center justify-center gap-2 shadow-md shadow-blue-600/30 transition-colors"
              >
                <Printer className="w-4 h-4" />
                <span>View & Print Receipt</span>
              </button>
              <button
                onClick={() => setSelectedSale(null)}
                className="px-5 py-2.5 bg-[#242424] text-gray-300 font-semibold text-xs rounded-xl hover:bg-[#2c2c2c]"
              >
                Close
              </button>
            </div>
          </div>
        )}
      </Modal>

      {/* Receipt Modal */}
      <ReceiptModal
        isOpen={!!receiptSale}
        onClose={() => setReceiptSale(null)}
        sale={receiptSale}
      />
    </div>
  );
};
