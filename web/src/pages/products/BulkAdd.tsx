import React, { useState } from 'react';
import { 
  Barcode, 
  ChevronLeft, 
  Plus, 
  Trash2, 
  Check, 
  Layers, 
  Camera, 
  Sparkles,
  PackageCheck
} from 'lucide-react';
import { useInventory } from '../../context/InventoryContext';
import { formatMoney } from '../../core/utils/currency';
import { BarcodeScannerModal } from '../../components/ui/BarcodeScannerModal';

interface BulkAddProps {
  onBack: () => void;
}

interface QueueItem {
  id: string;
  barcode: string;
  name: string;
  category: string;
  costPrice: number;
  sellingPrice: number;
  stockQty: number;
  brand: string;
}

export const BulkAdd: React.FC<BulkAddProps> = ({ onBack }) => {
  const { categories, bulkAddProducts, getProductByBarcode } = useInventory();

  const [scannerOpen, setScannerOpen] = useState<boolean>(false);
  const [manualBarcode, setManualBarcode] = useState<string>('');
  const [queue, setQueue] = useState<QueueItem[]>([]);
  const [isCommitting, setIsCommitting] = useState<boolean>(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const addItemToQueue = (barcodeValue: string) => {
    const cleanBarcode = barcodeValue.trim();
    if (!cleanBarcode) return;

    // Check if barcode already exists in database
    const existing = getProductByBarcode(cleanBarcode);

    const newItem: QueueItem = {
      id: `queue-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      barcode: cleanBarcode,
      name: existing ? existing.name : `New Scanned Part (${cleanBarcode.slice(-4)})`,
      category: existing ? existing.category || categories[0]?.name || 'Engine Parts' : categories[0]?.name || 'Engine Parts',
      costPrice: existing ? existing.cost_price : 100,
      sellingPrice: existing ? existing.selling_price : 150,
      stockQty: 10,
      brand: existing ? existing.brand || '' : '',
    };

    setQueue((prev) => [newItem, ...prev]);
    setManualBarcode('');
  };

  const updateQueueItem = (id: string, updates: Partial<QueueItem>) => {
    setQueue((prev) => prev.map((item) => (item.id === id ? { ...item, ...updates } : item)));
  };

  const removeItem = (id: string) => {
    setQueue((prev) => prev.filter((item) => item.id !== id));
  };

  const handleCommitQueue = async () => {
    if (queue.length === 0) return;
    setIsCommitting(true);

    const productsToAdd = queue.map((item) => ({
      name: item.name,
      barcode: item.barcode,
      category: item.category,
      brand: item.brand || null,
      unit: 'piece',
      is_service: false,
      cost_price: item.costPrice,
      selling_price: item.sellingPrice,
      stock_on_hand: item.stockQty,
    }));

    await bulkAddProducts(productsToAdd);
    setIsCommitting(false);
    setSuccessMessage(`Successfully added ${queue.length} items to inventory!`);
    setQueue([]);
  };

  return (
    <div className="max-w-4xl mx-auto space-y-5 pb-24 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={onBack}
            className="p-2 rounded-xl bg-[#1c1c1c] hover:bg-[#252525] border border-[#2a2a2a] text-gray-300 transition-colors"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <div>
            <h1 className="text-xl font-black text-white tracking-tight">Bulk Add Products</h1>
            <p className="text-xs text-gray-400">Scan barcodes in succession to rapidly stock products</p>
          </div>
        </div>

        {queue.length > 0 && (
          <button
            onClick={handleCommitQueue}
            disabled={isCommitting}
            className="px-4 py-2.5 bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs rounded-xl shadow-lg shadow-blue-600/30 flex items-center gap-2 transition-all active:scale-95"
          >
            <Check className="w-4 h-4" />
            <span>Commit All ({queue.length})</span>
          </button>
        )}
      </div>

      {successMessage && (
        <div className="p-4 bg-emerald-500/10 border border-emerald-500/30 rounded-2xl text-xs font-bold text-emerald-400 flex items-center gap-2">
          <PackageCheck className="w-5 h-5" />
          <span>{successMessage}</span>
        </div>
      )}

      {/* Blue Full-Width Scan Button */}
      <button
        onClick={() => setScannerOpen(true)}
        className="w-full py-4 bg-blue-600 hover:bg-blue-500 active:scale-[0.99] text-white font-black text-sm tracking-wider uppercase rounded-2xl shadow-xl shadow-blue-600/30 flex items-center justify-center gap-2 transition-all"
      >
        <Camera className="w-5 h-5" />
        <span>📷 SCAN BARCODES</span>
      </button>

      {/* Manual Input Field */}
      <div className="p-4 bg-[#141414] border border-[#262626] rounded-2xl">
        <form
          onSubmit={(e) => {
            e.preventDefault();
            addItemToQueue(manualBarcode);
          }}
          className="flex gap-2"
        >
          <input
            type="text"
            placeholder="Enter barcode or SKU number manually..."
            value={manualBarcode}
            onChange={(e) => setManualBarcode(e.target.value)}
            className="flex-1 px-4 py-2.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-xs text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 font-medium"
          />
          <button
            type="submit"
            disabled={!manualBarcode.trim()}
            className="px-5 py-2.5 bg-[#242424] hover:bg-blue-600 hover:text-white disabled:opacity-50 text-gray-300 text-xs font-bold rounded-xl transition-all flex items-center gap-1"
          >
            <Plus className="w-4 h-4" />
            <span>Add to Queue</span>
          </button>
        </form>
      </div>

      {/* Queue List */}
      <div className="space-y-3">
        <div className="flex items-center justify-between px-1">
          <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider">
            Queue List ({queue.length})
          </h3>
          {queue.length > 0 && (
            <button
              onClick={() => setQueue([])}
              className="text-[11px] font-semibold text-gray-500 hover:text-red-400"
            >
              Clear Queue
            </button>
          )}
        </div>

        {queue.length > 0 ? (
          <div className="space-y-2.5">
            {queue.map((item) => (
              <div
                key={item.id}
                className="p-4 bg-[#141414] border border-[#262626] rounded-2xl space-y-3"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="flex-1 space-y-1">
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-blue-500/10 text-blue-400 border border-blue-500/20">
                      Barcode: {item.barcode}
                    </span>
                    <input
                      type="text"
                      value={item.name}
                      onChange={(e) => updateQueueItem(item.id, { name: e.target.value })}
                      className="w-full mt-1 px-3 py-1.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-xs text-white font-bold focus:outline-none focus:border-blue-500"
                      placeholder="Product Name"
                    />
                  </div>

                  <button
                    onClick={() => removeItem(item.id)}
                    className="p-2 text-gray-500 hover:text-red-400 transition-colors"
                    title="Remove from queue"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>

                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 pt-1">
                  <div>
                    <span className="text-[10px] text-gray-400 font-bold block mb-1">Category</span>
                    <select
                      value={item.category}
                      onChange={(e) => updateQueueItem(item.id, { category: e.target.value })}
                      className="w-full px-2.5 py-1.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-[11px] text-white focus:outline-none"
                    >
                      {categories.map((c) => (
                        <option key={c.id} value={c.name}>
                          {c.name}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <span className="text-[10px] text-gray-400 font-bold block mb-1">Cost (₱)</span>
                    <input
                      type="number"
                      step="0.01"
                      value={item.costPrice}
                      onChange={(e) => updateQueueItem(item.id, { costPrice: parseFloat(e.target.value) || 0 })}
                      className="w-full px-2.5 py-1.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-[11px] text-white focus:outline-none"
                    />
                  </div>

                  <div>
                    <span className="text-[10px] text-gray-400 font-bold block mb-1">Selling (₱)</span>
                    <input
                      type="number"
                      step="0.01"
                      value={item.sellingPrice}
                      onChange={(e) => updateQueueItem(item.id, { sellingPrice: parseFloat(e.target.value) || 0 })}
                      className="w-full px-2.5 py-1.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-[11px] text-blue-400 font-bold focus:outline-none"
                    />
                  </div>

                  <div>
                    <span className="text-[10px] text-gray-400 font-bold block mb-1">Stock Qty</span>
                    <input
                      type="number"
                      min="1"
                      value={item.stockQty}
                      onChange={(e) => updateQueueItem(item.id, { stockQty: parseInt(e.target.value) || 1 })}
                      className="w-full px-2.5 py-1.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-[11px] text-emerald-400 font-bold focus:outline-none"
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="p-16 text-center bg-[#141414] border border-[#262626] rounded-3xl space-y-2">
            <div className="w-12 h-12 rounded-2xl bg-[#1e1e1e] flex items-center justify-center mx-auto text-gray-500">
              <Barcode className="w-6 h-6" />
            </div>
            <h4 className="text-sm font-bold text-white">No products in queue</h4>
            <p className="text-xs text-gray-400 max-w-sm mx-auto">
              Tap "SCAN BARCODES" or manually type barcode numbers above to build your batch queue.
            </p>
          </div>
        )}
      </div>

      {/* Barcode Scanner Modal */}
      <BarcodeScannerModal
        isOpen={scannerOpen}
        onClose={() => setScannerOpen(false)}
        onScan={addItemToQueue}
      />
    </div>
  );
};
