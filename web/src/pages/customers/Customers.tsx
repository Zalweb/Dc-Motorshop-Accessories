import React, { useState } from 'react';
import { Users, Search, CreditCard, CheckCircle2, AlertCircle, ArrowUpRight, Phone, Receipt } from 'lucide-react';
import { useSales } from '../../context/SalesContext';
import { formatMoney } from '../../core/utils/currency';
import { formatDateTime } from '../../core/utils/date';
import { Sale } from '../../core/types';
import { Modal } from '../../components/ui/Modal';

interface CustomerSummary {
  name: string;
  totalSpent: number;
  unpaidBalance: number;
  salesCount: number;
  lastPurchaseDate: string;
  sales: Sale[];
}

export const Customers: React.FC = () => {
  const { sales, markSalePaid } = useSales();
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedCustomer, setSelectedCustomer] = useState<CustomerSummary | null>(null);

  // Group sales by customer
  const customerMap: Record<string, CustomerSummary> = {};

  sales.forEach((s) => {
    const name = s.customer_name?.trim() || 'Walk-in Customer';
    if (!customerMap[name]) {
      customerMap[name] = {
        name,
        totalSpent: 0,
        unpaidBalance: 0,
        salesCount: 0,
        lastPurchaseDate: s.created_at,
        sales: [],
      };
    }

    customerMap[name].totalSpent += s.total;
    if (s.status === 'unpaid') {
      customerMap[name].unpaidBalance += s.total;
    }
    customerMap[name].salesCount += 1;
    customerMap[name].sales.push(s);
  });

  const customerList = Object.values(customerMap).filter((c) => {
    if (!searchQuery.trim()) return true;
    return c.name.toLowerCase().includes(searchQuery.toLowerCase().trim());
  });

  const totalOutstanding = Object.values(customerMap).reduce((sum, c) => sum + c.unpaidBalance, 0);

  return (
    <div className="max-w-6xl mx-auto space-y-6 pb-24 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-black text-white tracking-tight">Customer Receivables Ledger</h1>
          <p className="text-xs text-gray-400">
            Total Outstanding Credit:{' '}
            <span className="text-amber-400 font-bold">{formatMoney(totalOutstanding)}</span>
          </p>
        </div>
      </div>

      {/* Search Bar */}
      <div className="p-4 bg-[#141414] border border-[#262626] rounded-2xl flex items-center gap-3">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search customers by name..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-xs text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
          />
        </div>
      </div>

      {/* Customers Table / Grid */}
      {customerList.length > 0 ? (
        <div className="bg-[#141414] border border-[#262626] rounded-3xl overflow-hidden shadow-xl">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs text-gray-300">
              <thead className="bg-[#1a1a1a] text-gray-400 font-bold uppercase tracking-wider text-[10px] border-b border-[#262626]">
                <tr>
                  <th className="px-5 py-3.5">Customer Name</th>
                  <th className="px-5 py-3.5">Total Orders</th>
                  <th className="px-5 py-3.5">Total Spent</th>
                  <th className="px-5 py-3.5">Outstanding Balance</th>
                  <th className="px-5 py-3.5 text-center">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#222222]">
                {customerList.map((c) => (
                  <tr
                    key={c.name}
                    onClick={() => setSelectedCustomer(c)}
                    className="hover:bg-[#181818] transition-colors cursor-pointer"
                  >
                    <td className="px-5 py-4 font-bold text-white flex items-center gap-2.5">
                      <div className="w-8 h-8 rounded-full bg-blue-600/20 text-blue-400 border border-blue-500/30 flex items-center justify-center font-bold text-xs">
                        {c.name.slice(0, 2).toUpperCase()}
                      </div>
                      <span>{c.name}</span>
                    </td>
                    <td className="px-5 py-4 text-gray-400">
                      {c.salesCount} {c.salesCount === 1 ? 'sale' : 'sales'}
                    </td>
                    <td className="px-5 py-4 font-bold text-white">
                      {formatMoney(c.totalSpent)}
                    </td>
                    <td className="px-5 py-4">
                      {c.unpaidBalance > 0 ? (
                        <span className="font-bold text-amber-400 bg-amber-400/10 px-2.5 py-1 rounded-full border border-amber-400/20">
                          {formatMoney(c.unpaidBalance)} Unpaid
                        </span>
                      ) : (
                        <span className="font-bold text-emerald-400 bg-emerald-400/10 px-2.5 py-1 rounded-full border border-emerald-400/20">
                          Settled
                        </span>
                      )}
                    </td>
                    <td className="px-5 py-4 text-center">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setSelectedCustomer(c);
                        }}
                        className="px-3 py-1.5 rounded-xl bg-[#222222] hover:bg-blue-600 hover:text-white text-gray-300 text-xs font-semibold transition-colors"
                      >
                        View Ledger
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div className="p-16 text-center bg-[#141414] border border-[#262626] rounded-3xl">
          <Users className="w-12 h-12 text-gray-600 mx-auto mb-3" />
          <h3 className="text-sm font-bold text-white">No customer records</h3>
          <p className="text-xs text-gray-400 mt-1">Customer profiles are created automatically upon checkout.</p>
        </div>
      )}

      {/* CUSTOMER LEDGER MODAL */}
      <Modal
        isOpen={!!selectedCustomer}
        onClose={() => setSelectedCustomer(null)}
        title={`Customer Ledger — ${selectedCustomer?.name}`}
        subtitle={`${selectedCustomer?.salesCount} orders recorded`}
        maxWidth="lg"
      >
        {selectedCustomer && (
          <div className="space-y-4">
            {/* KPI Cards */}
            <div className="grid grid-cols-2 gap-3">
              <div className="p-3 bg-[#1f1f1f] rounded-2xl border border-[#2e2e2e]">
                <span className="text-[10px] font-bold text-gray-400 uppercase">Total Lifetime Sales</span>
                <p className="text-base font-black text-white mt-0.5">{formatMoney(selectedCustomer.totalSpent)}</p>
              </div>
              <div className="p-3 bg-[#1f1f1f] rounded-2xl border border-[#2e2e2e]">
                <span className="text-[10px] font-bold text-gray-400 uppercase">Current Credit Balance</span>
                <p className="text-base font-black text-amber-400 mt-0.5">{formatMoney(selectedCustomer.unpaidBalance)}</p>
              </div>
            </div>

            {/* Sales History */}
            <div className="space-y-2">
              <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">Purchase History</h4>
              <div className="bg-[#1c1c1c] border border-[#2a2a2a] rounded-2xl divide-y divide-[#262626] overflow-hidden max-h-64 overflow-y-auto">
                {selectedCustomer.sales.map((sale) => (
                  <div key={sale.id} className="p-3.5 flex items-center justify-between text-xs">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-white">{sale.sale_number}</span>
                        {sale.status === 'unpaid' ? (
                          <span className="text-[10px] font-bold px-2 py-0.2 rounded-full bg-amber-500/20 text-amber-400 border border-amber-500/30">
                            UNPAID
                          </span>
                        ) : (
                          <span className="text-[10px] font-bold px-2 py-0.2 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                            PAID
                          </span>
                        )}
                      </div>
                      <p className="text-[11px] text-gray-400 mt-0.5">
                        {formatDateTime(sale.created_at)} · {sale.items?.length || 0} items
                      </p>
                    </div>

                    <div className="flex items-center gap-3">
                      <span className="font-bold text-white">{formatMoney(sale.total)}</span>
                      {sale.status === 'unpaid' && (
                        <button
                          onClick={async () => {
                            await markSalePaid(sale.id);
                            // update local customer modal state
                            setSelectedCustomer({
                              ...selectedCustomer,
                              unpaidBalance: Math.max(0, selectedCustomer.unpaidBalance - sale.total),
                              sales: selectedCustomer.sales.map((s) => (s.id === sale.id ? { ...s, status: 'paid' } : s)),
                            });
                          }}
                          className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-[10px] rounded-lg shadow-sm transition-colors"
                        >
                          Mark Paid
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};
