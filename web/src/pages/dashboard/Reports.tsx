import React, { useState } from 'react';
import { BarChart3, Download, TrendingUp, DollarSign, PieChart, ShieldAlert, Award } from 'lucide-react';
import { useSales } from '../../context/SalesContext';
import { useExpenses } from '../../context/ExpenseContext';
import { formatMoney, formatPercent } from '../../core/utils/currency';
import { DateFilterType } from '../../core/utils/date';
import { MetricCard } from '../../components/ui/MetricCard';

export const Reports: React.FC = () => {
  const { getMetricsForFilter, getFilteredSales, exportSales } = useSales();
  const { expenses } = useExpenses();

  const [dateFilter, setDateFilter] = useState<DateFilterType>('this_month');

  const metrics = getMetricsForFilter(dateFilter);
  const filteredSales = getFilteredSales(dateFilter);

  // Compute Top Selling Products
  const productSalesMap: Record<string, { name: string; quantity: number; revenue: number; profit: number }> = {};
  filteredSales.forEach((sale) => {
    sale.items?.forEach((item) => {
      if (!productSalesMap[item.name]) {
        productSalesMap[item.name] = {
          name: item.name,
          quantity: 0,
          revenue: 0,
          profit: 0,
        };
      }
      productSalesMap[item.name].quantity += item.quantity;
      productSalesMap[item.name].revenue += item.line_total;
      productSalesMap[item.name].profit += item.line_total - item.unit_cost * item.quantity;
    });
  });

  const topProducts = Object.values(productSalesMap)
    .sort((a, b) => b.revenue - a.revenue)
    .slice(0, 8);

  // Payment Method Breakdown
  const paymentMap: Record<string, { count: number; total: number }> = {};
  filteredSales.forEach((sale) => {
    const method = sale.payment_method || 'cash';
    if (!paymentMap[method]) {
      paymentMap[method] = { count: 0, total: 0 };
    }
    paymentMap[method].count += 1;
    paymentMap[method].total += sale.total;
  });

  // Expense Category Breakdown
  const expenseCatMap: Record<string, number> = {};
  expenses.forEach((e) => {
    const cat = e.category || 'General';
    expenseCatMap[cat] = (expenseCatMap[cat] || 0) + e.amount;
  });

  return (
    <div className="max-w-6xl mx-auto space-y-6 pb-24 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-black text-white tracking-tight">Financial Reports & Analytics</h1>
          <p className="text-xs text-gray-400">Profit & loss, item velocity, and expense breakdowns</p>
        </div>

        <div className="flex items-center gap-2">
          <select
            value={dateFilter}
            onChange={(e) => setDateFilter(e.target.value as DateFilterType)}
            className="appearance-none bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl px-3.5 py-2 text-xs font-bold text-gray-300 focus:outline-none focus:border-blue-500 cursor-pointer"
          >
            <option value="today">Today</option>
            <option value="yesterday">Yesterday</option>
            <option value="this_week">This Week</option>
            <option value="this_month">This Month</option>
            <option value="this_year">This Year</option>
            <option value="all">All Time</option>
          </select>

          <button
            onClick={() => exportSales(filteredSales)}
            className="px-3.5 py-2 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs flex items-center gap-1.5 shadow-md shadow-blue-600/30 transition-all active:scale-95"
          >
            <Download className="w-4 h-4" />
            <span>Export Excel</span>
          </button>
        </div>
      </div>

      {/* KPI Overview Grid */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <MetricCard
          label="Total Revenue"
          value={formatMoney(metrics.revenue)}
          subValue={`${metrics.salesCount} transactions`}
          colorType="primary"
        />
        <MetricCard
          label="Gross Profit"
          value={formatMoney(metrics.grossProfit)}
          subValue={`${formatPercent(metrics.grossMarginPercent)} margin`}
          colorType="profit"
        />
        <MetricCard
          label="Operating Expenses"
          value={formatMoney(metrics.expenses)}
          subValue="Overhead & utilities"
          colorType="expense"
        />
        <MetricCard
          label="Net Profit"
          value={formatMoney(metrics.netProfit)}
          subValue="Take-home earnings"
          colorType="profit"
          highlight={true}
        />
      </div>

      {/* 2-Column Analytics */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top Selling Products */}
        <div className="p-5 rounded-3xl bg-[#141414] border border-[#262626] space-y-4 shadow-xl">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-white flex items-center gap-2">
              <Award className="w-4 h-4 text-amber-400" />
              <span>Top Selling Products & Services</span>
            </h3>
            <span className="text-[11px] text-gray-500 font-semibold">Ranked by revenue</span>
          </div>

          {topProducts.length > 0 ? (
            <div className="space-y-3">
              {topProducts.map((prod, idx) => (
                <div
                  key={prod.name}
                  className="p-3 bg-[#191919] border border-[#262626] rounded-2xl flex items-center justify-between text-xs"
                >
                  <div className="flex items-center gap-3">
                    <span className="w-6 h-6 rounded-lg bg-[#222222] font-black text-gray-400 flex items-center justify-center text-[10px]">
                      #{idx + 1}
                    </span>
                    <div>
                      <h4 className="font-bold text-white leading-tight truncate max-w-[200px]">{prod.name}</h4>
                      <p className="text-[11px] text-gray-400 mt-0.5">
                        {prod.quantity} units sold · Profit: {formatMoney(prod.profit)}
                      </p>
                    </div>
                  </div>
                  <span className="font-black text-blue-400">{formatMoney(prod.revenue)}</span>
                </div>
              ))}
            </div>
          ) : (
            <div className="py-12 text-center text-xs text-gray-500">
              No product sales recorded for this timeframe.
            </div>
          )}
        </div>

        {/* Payment Methods & Expense Distribution */}
        <div className="space-y-6">
          {/* Payment Methods */}
          <div className="p-5 rounded-3xl bg-[#141414] border border-[#262626] space-y-3 shadow-xl">
            <h3 className="text-sm font-bold text-white flex items-center gap-2">
              <PieChart className="w-4 h-4 text-blue-400" />
              <span>Payment Method Distribution</span>
            </h3>

            {Object.keys(paymentMap).length > 0 ? (
              <div className="space-y-2">
                {Object.entries(paymentMap).map(([method, data]) => {
                  const percent = metrics.revenue > 0 ? (data.total / metrics.revenue) * 100 : 0;
                  return (
                    <div key={method} className="space-y-1">
                      <div className="flex justify-between text-xs font-semibold">
                        <span className="text-gray-300 uppercase">{method} ({data.count} sales)</span>
                        <span className="text-white font-bold">{formatMoney(data.total)} ({percent.toFixed(0)}%)</span>
                      </div>
                      <div className="w-full h-2 bg-[#222222] rounded-full overflow-hidden">
                        <div
                          className="h-full bg-blue-500 rounded-full"
                          style={{ width: `${percent}%` }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="py-6 text-center text-xs text-gray-500">No payment records yet.</div>
            )}
          </div>

          {/* Expense Categories */}
          <div className="p-5 rounded-3xl bg-[#141414] border border-[#262626] space-y-3 shadow-xl">
            <h3 className="text-sm font-bold text-white flex items-center gap-2">
              <DollarSign className="w-4 h-4 text-amber-400" />
              <span>Expense Categories</span>
            </h3>

            {Object.keys(expenseCatMap).length > 0 ? (
              <div className="space-y-2">
                {Object.entries(expenseCatMap).map(([cat, total]) => (
                  <div
                    key={cat}
                    className="p-3 bg-[#191919] border border-[#262626] rounded-xl flex items-center justify-between text-xs"
                  >
                    <span className="font-semibold text-gray-300">{cat}</span>
                    <span className="font-black text-amber-400">{formatMoney(total)}</span>
                  </div>
                ))}
              </div>
            ) : (
              <div className="py-6 text-center text-xs text-gray-500">No expenses recorded yet.</div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
