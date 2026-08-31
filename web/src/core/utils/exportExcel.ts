import * as XLSX from 'xlsx';
import { Sale } from '../types';
import { formatDateTime } from './date';

export function exportSalesToExcel(sales: Sale[], shopName: string = 'DC Motorshop & Accessories') {
  // 1. Prepare Sales Overview Rows
  const summaryRows = sales.map((sale) => {
    const totalItems = sale.items?.reduce((sum, item) => sum + item.quantity, 0) || 0;
    const totalCost = sale.items?.reduce((sum, item) => sum + (item.unit_cost * item.quantity), 0) || 0;
    const grossProfit = sale.total - totalCost;

    return {
      'Sale Number': sale.sale_number,
      'Date & Time': formatDateTime(sale.created_at),
      'Customer': sale.customer_name || 'Walk-in Customer',
      'Payment Method': (sale.payment_method || 'cash').toUpperCase(),
      'Status': (sale.status || 'paid').toUpperCase(),
      'Items Count': totalItems,
      'Subtotal (PHP)': sale.subtotal,
      'Discount (PHP)': sale.discount,
      'Total Amount (PHP)': sale.total,
      'Amount Received (PHP)': sale.amount_received,
      'Estimated COGS (PHP)': totalCost,
      'Estimated Profit (PHP)': grossProfit,
      'Notes': sale.notes || '',
    };
  });

  // 2. Prepare Itemized Line Items Rows
  const itemRows: Array<Record<string, string | number>> = [];
  sales.forEach((sale) => {
    if (sale.items && sale.items.length > 0) {
      sale.items.forEach((item) => {
        itemRows.push({
          'Sale Number': sale.sale_number,
          'Date': formatDateTime(sale.created_at),
          'Product / Service': item.name,
          'Quantity': item.quantity,
          'Unit Price (PHP)': item.unit_price,
          'Unit Cost (PHP)': item.unit_cost,
          'Line Total (PHP)': item.line_total,
          'Line Profit (PHP)': item.line_total - (item.unit_cost * item.quantity),
        });
      });
    }
  });

  // 3. Create Workbook & Sheets
  const wb = XLSX.utils.book_new();

  const wsSummary = XLSX.utils.json_to_sheet(summaryRows);
  const wsItems = XLSX.utils.json_to_sheet(itemRows);

  XLSX.utils.book_append_sheet(wb, wsSummary, 'Sales Summary');
  XLSX.utils.book_append_sheet(wb, wsItems, 'Itemized Sales');

  // 4. Generate File Name & Download
  const timestamp = new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14);
  const filename = `${shopName.replace(/[^a-zA-Z0-9]/g, '_')}_sales_${timestamp}.xlsx`;

  XLSX.writeFile(wb, filename);
}
