import React, { useRef } from 'react';
import { Printer, CheckCircle, Share2, Download } from 'lucide-react';
import { Sale } from '../../core/types';
import { formatMoney } from '../../core/utils/currency';
import { formatDateTime } from '../../core/utils/date';
import { useBusiness } from '../../context/BusinessContext';
import { Modal } from './Modal';

interface ReceiptModalProps {
  isOpen: boolean;
  onClose: () => void;
  sale: Sale | null;
}

export const ReceiptModal: React.FC<ReceiptModalProps> = ({ isOpen, onClose, sale }) => {
  const { profile } = useBusiness();
  const receiptRef = useRef<HTMLDivElement>(null);

  if (!sale) return null;

  const handlePrint = () => {
    const printContent = receiptRef.current;
    if (!printContent) return;

    const printWindow = window.open('', '', 'width=400,height=650');
    if (!printWindow) return;

    printWindow.document.write(`
      <html>
        <head>
          <title>Receipt - ${sale.sale_number}</title>
          <style>
            body { font-family: monospace; font-size: 12px; padding: 15px; margin: 0; color: #000; }
            .text-center { text-align: center; }
            .bold { font-weight: bold; }
            .divider { border-bottom: 1px dashed #000; margin: 8px 0; }
            .row { display: flex; justify-content: space-between; margin: 3px 0; }
            .items-table { width: 100%; border-collapse: collapse; margin: 8px 0; }
            .items-table th, .items-table td { text-align: left; padding: 3px 0; }
            .text-right { text-align: right; }
          </style>
        </head>
        <body>
          ${printContent.innerHTML}
          <script>
            window.onload = function() { window.print(); window.close(); }
          </script>
        </body>
      </html>
    `);
    printWindow.document.close();
  };

  const changeDue = Math.max(0, (sale.amount_received || 0) - sale.total);

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Sale Completed Successfully"
      subtitle={`Sale Number: ${sale.sale_number}`}
      maxWidth="sm"
    >
      <div className="space-y-4">
        {/* Printable Receipt Paper View */}
        <div
          ref={receiptRef}
          className="bg-[#1f1f1f] text-gray-200 p-5 rounded-xl border border-[#2e2e2e] font-mono text-xs shadow-inner space-y-3"
        >
          {/* Header */}
          <div className="text-center pb-2 border-b border-dashed border-gray-700">
            <h4 className="font-bold text-sm text-white">{profile.business_name}</h4>
            <p className="text-[11px] text-gray-400">{profile.address || 'Philippines'}</p>
            <p className="text-[11px] text-gray-400">Tel: {profile.phone || '0917-123-4567'}</p>
            <p className="text-[10px] text-gray-400 mt-1">{formatDateTime(sale.created_at)}</p>
          </div>

          {/* Sale Info */}
          <div className="space-y-1 text-[11px] border-b border-dashed border-gray-700 pb-2">
            <div className="flex justify-between">
              <span className="text-gray-400">Receipt No:</span>
              <span className="font-bold text-white">{sale.sale_number}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Customer:</span>
              <span className="font-medium text-gray-200">{sale.customer_name || 'Walk-in'}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Payment:</span>
              <span className="font-bold text-emerald-400 uppercase">{sale.payment_method}</span>
            </div>
          </div>

          {/* Line Items */}
          <div className="space-y-2 py-1 border-b border-dashed border-gray-700">
            {sale.items?.map((item, idx) => (
              <div key={idx} className="space-y-0.5">
                <div className="flex justify-between font-medium text-white">
                  <span className="truncate max-w-[180px]">{item.name}</span>
                  <span>{formatMoney(item.line_total)}</span>
                </div>
                <div className="text-[10px] text-gray-400">
                  {item.quantity} x {formatMoney(item.unit_price)}
                </div>
              </div>
            ))}
          </div>

          {/* Financial Totals */}
          <div className="space-y-1 pt-1 text-[11px]">
            <div className="flex justify-between">
              <span className="text-gray-400">Subtotal</span>
              <span>{formatMoney(sale.subtotal)}</span>
            </div>
            {sale.discount > 0 && (
              <div className="flex justify-between text-purple-400">
                <span>Discount</span>
                <span>-{formatMoney(sale.discount)}</span>
              </div>
            )}
            <div className="flex justify-between text-sm font-bold text-white pt-1 border-t border-gray-700">
              <span>TOTAL DUE</span>
              <span className="text-blue-400">{formatMoney(sale.total)}</span>
            </div>
            <div className="flex justify-between text-gray-400 pt-1">
              <span>Amount Received</span>
              <span>{formatMoney(sale.amount_received)}</span>
            </div>
            <div className="flex justify-between font-bold text-emerald-400">
              <span>Change</span>
              <span>{formatMoney(changeDue)}</span>
            </div>
          </div>

          {/* Footer note */}
          <div className="text-center pt-3 border-t border-dashed border-gray-700 text-[10px] text-gray-400">
            <p>Thank you for your business!</p>
            <p>Please keep this receipt for warranty claims.</p>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-2 pt-2">
          <button
            onClick={handlePrint}
            className="flex-1 py-3 px-4 bg-blue-600 hover:bg-blue-500 text-white font-semibold text-xs rounded-xl flex items-center justify-center gap-2 shadow-lg shadow-blue-600/30 transition-all"
          >
            <Printer className="w-4 h-4" />
            <span>Print Receipt</span>
          </button>
          <button
            onClick={onClose}
            className="px-5 py-3 bg-[#242424] hover:bg-[#2e2e2e] text-gray-300 font-semibold text-xs rounded-xl transition-colors"
          >
            Done
          </button>
        </div>
      </div>
    </Modal>
  );
};
