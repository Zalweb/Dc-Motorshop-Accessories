import React, { useState } from 'react';
import { 
  Search, 
  Barcode, 
  ShoppingCart, 
  Plus, 
  Minus, 
  Trash2, 
  Check, 
  CreditCard, 
  Banknote, 
  Smartphone, 
  Building2, 
  Box,
  Package,
  AlertCircle
} from 'lucide-react';
import { useInventory } from '../../context/InventoryContext';
import { useSales } from '../../context/SalesContext';
import { useBusiness } from '../../context/BusinessContext';
import { formatMoney } from '../../core/utils/currency';
import { Product, Sale } from '../../core/types';
import { BarcodeScannerModal } from '../../components/ui/BarcodeScannerModal';
import { ReceiptModal } from '../../components/ui/ReceiptModal';
import { Modal } from '../../components/ui/Modal';

export const NewSale: React.FC = () => {
  const { products, categories, getProductByBarcode } = useInventory();
  const { 
    cart, 
    addToCart, 
    removeFromCart, 
    updateCartQuantity, 
    clearCart, 
    cartSubtotal, 
    cartDiscount, 
    cartTotal, 
    cartItemCount, 
    processCheckout 
  } = useSales();
  const { profile } = useBusiness();

  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedFilter, setSelectedFilter] = useState<string>('All');
  const [scannerOpen, setScannerOpen] = useState<boolean>(false);
  const [cartDrawerOpen, setCartDrawerOpen] = useState<boolean>(false);
  const [checkoutModalOpen, setCheckoutModalOpen] = useState<boolean>(false);
  const [completedSale, setCompletedSale] = useState<Sale | null>(null);

  // Checkout form state
  const [customerName, setCustomerName] = useState<string>('');
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'gcash' | 'maya' | 'bank_transfer' | 'credit'>('cash');
  const [amountReceived, setAmountReceived] = useState<string>('');
  const [saleDiscount, setSaleDiscount] = useState<string>('0');
  const [checkoutNotes, setCheckoutNotes] = useState<string>('');
  const [checkoutError, setCheckoutError] = useState<string | null>(null);

  // Filter options: All + categories
  const filterOptions = ['All', ...categories.map((c) => c.name)];

  const filteredProducts = products.filter((p) => {
    // Category filter
    if (selectedFilter !== 'All') {
      if (p.category !== selectedFilter) return false;
    }

    // Search query filter
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      const matchName = p.name.toLowerCase().includes(q);
      const matchBarcode = p.barcode?.toLowerCase().includes(q);
      const matchPart = p.part_number?.toLowerCase().includes(q);
      const matchBrand = p.brand?.toLowerCase().includes(q);
      return matchName || matchBarcode || matchPart || matchBrand;
    }
    return true;
  });

  const handleBarcodeScanned = (barcode: string) => {
    const found = getProductByBarcode(barcode);
    if (found) {
      addToCart(found, 1);
    } else {
      setSearchQuery(barcode);
    }
  };

  const handleQuickCash = (extra: number) => {
    const current = parseFloat(amountReceived) || 0;
    const finalAmount = extra === 0 ? cartTotal : current + extra;
    setAmountReceived(finalAmount.toString());
  };

  const handleCheckoutSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setCheckoutError(null);

    const received = parseFloat(amountReceived) || 0;
    const discountVal = parseFloat(saleDiscount) || 0;
    const finalTotal = Math.max(0, cartSubtotal - cartDiscount - discountVal);

    if (paymentMethod === 'cash' && received < finalTotal) {
      setCheckoutError(`Amount received (₱${received.toFixed(2)}) is less than total due (₱${finalTotal.toFixed(2)}).`);
      return;
    }

    const sale = await processCheckout({
      customerName: customerName.trim() || 'Walk-in Customer',
      paymentMethod,
      amountReceived: paymentMethod === 'cash' ? received : finalTotal,
      discount: discountVal,
      notes: checkoutNotes,
    });

    setCompletedSale(sale);
    setCheckoutModalOpen(false);
    setCartDrawerOpen(false);
    // Reset form
    setCustomerName('');
    setAmountReceived('');
    setSaleDiscount('0');
    setCheckoutNotes('');
  };

  const totalCalculated = Math.max(0, cartTotal - (parseFloat(saleDiscount) || 0));
  const changeCalculated = Math.max(0, (parseFloat(amountReceived) || 0) - totalCalculated);

  return (
    <div className="max-w-4xl mx-auto space-y-4 pb-32 animate-fade-in relative">
      {/* Header (Matching Image 11.jpg & new_sale_screen.dart) */}
      <div>
        <h1 className="text-2xl font-black text-white tracking-tight leading-none">
          New Sale
        </h1>
        <p className="text-xs text-gray-400 mt-1">Select items to add to cart</p>
      </div>

      {/* Search Bar + Barcode Scanner Button */}
      <div className="flex gap-2">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search products..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-3 bg-[#141414] border border-[#262626] rounded-2xl text-xs text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 shadow-sm"
          />
        </div>
        <button
          onClick={() => setScannerOpen(true)}
          className="px-4 bg-blue-600 hover:bg-blue-500 active:scale-95 text-white rounded-2xl flex items-center justify-center shadow-lg shadow-blue-600/30 transition-all"
          title="Open Barcode Scanner"
        >
          <Barcode className="w-5 h-5" />
        </button>
      </div>

      {/* Filter Chips Bar (Image 11.jpg) */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none">
        {filterOptions.map((filter) => {
          const isSelected = selectedFilter === filter;
          return (
            <button
              key={filter}
              onClick={() => setSelectedFilter(filter)}
              className={`px-3.5 py-1.5 rounded-full text-xs font-bold whitespace-nowrap transition-all border ${
                isSelected
                  ? 'bg-blue-600 border-blue-500 text-white shadow-md shadow-blue-600/30'
                  : 'bg-[#181818] border-[#262626] text-gray-400 hover:text-white'
              }`}
            >
              {filter}
            </button>
          );
        })}
      </div>

      {/* Products List / Empty State */}
      {filteredProducts.length > 0 ? (
        <div className="space-y-2.5">
          {filteredProducts.map((p) => {
            const isOutOfStock = !p.is_service && p.stock_on_hand <= 0;
            const isLowStock = !p.is_service && p.stock_on_hand > 0 && p.stock_on_hand <= 5;
            const inCart = cart.find((item) => item.product.id === p.id);

            return (
              <div
                key={p.id}
                onClick={() => {
                  if (!isOutOfStock || profile.allow_sell_when_out_of_stock) {
                    addToCart(p, 1);
                  }
                }}
                className={`p-3.5 rounded-2xl bg-[#141414] border transition-all flex items-center justify-between cursor-pointer ${
                  inCart
                    ? 'border-blue-500/50 bg-[#161d2d]'
                    : isOutOfStock && !profile.allow_sell_when_out_of_stock
                    ? 'border-[#222222] opacity-50 cursor-not-allowed'
                    : 'border-[#262626] hover:border-gray-600 hover:bg-[#181818]'
                }`}
              >
                <div className="flex items-center gap-3 min-w-0">
                  <div className="w-11 h-11 rounded-xl bg-[#1f1f1f] border border-[#2e2e2e] flex items-center justify-center shrink-0 overflow-hidden">
                    {p.image_url ? (
                      <img src={p.image_url} alt={p.name} className="w-full h-full object-cover" />
                    ) : (
                      <Package className="w-5 h-5 text-gray-500" />
                    )}
                  </div>

                  <div className="min-w-0">
                    <h3 className="text-xs sm:text-sm font-bold text-white leading-tight truncate">
                      {p.name}
                    </h3>
                    <div className="flex items-center gap-2 mt-0.5 text-[11px] text-gray-400">
                      <span>{p.category || 'General'}</span>
                      <span>•</span>
                      {p.is_service ? (
                        <span className="text-purple-400 font-semibold">Service</span>
                      ) : isOutOfStock ? (
                        <span className="text-red-400 font-bold">Out of stock</span>
                      ) : isLowStock ? (
                        <span className="text-amber-400 font-bold">{p.stock_on_hand} left</span>
                      ) : (
                        <span className="text-emerald-400 font-semibold">{p.stock_on_hand} in stock</span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-3 shrink-0">
                  <span className="text-sm font-black text-blue-400">
                    {formatMoney(p.selling_price)}
                  </span>
                  {inCart ? (
                    <div className="w-7 h-7 rounded-xl bg-blue-600 text-white font-bold text-xs flex items-center justify-center shadow-sm">
                      {inCart.quantity}
                    </div>
                  ) : (
                    <div className="w-7 h-7 rounded-xl bg-[#222222] text-gray-400 flex items-center justify-center">
                      <Plus className="w-3.5 h-3.5" />
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        /* Empty State (Exact Reference Image 11.jpg) */
        <div className="py-20 text-center space-y-3">
          <div className="w-16 h-16 rounded-3xl bg-[#141414] border border-[#262626] flex items-center justify-center mx-auto text-gray-500">
            <Box className="w-8 h-8" />
          </div>
          <div>
            <h3 className="text-base font-bold text-white">No products</h3>
            <p className="text-xs text-gray-400 mt-0.5">No products available.</p>
          </div>
        </div>
      )}

      {/* Bottom Cart Tray (Exact Reference Image 11.jpg) */}
      <div className="fixed bottom-20 lg:bottom-6 left-4 right-4 max-w-4xl mx-auto z-30">
        {cart.length > 0 ? (
          <div className="p-3.5 bg-[#171717] border border-[#2a2a2a] rounded-2xl shadow-2xl flex items-center justify-between backdrop-blur-md">
            <div
              onClick={() => setCartDrawerOpen(true)}
              className="flex items-center gap-3 cursor-pointer"
            >
              <div className="w-10 h-10 rounded-xl bg-blue-600 flex items-center justify-center text-white font-bold text-sm shadow-md shadow-blue-600/30">
                {cartItemCount}
              </div>
              <div>
                <span className="text-[11px] font-semibold text-gray-400 uppercase block">Cart Total</span>
                <span className="text-base font-black text-white">{formatMoney(cartTotal)}</span>
              </div>
            </div>

            <button
              onClick={() => setCheckoutModalOpen(true)}
              className="px-6 py-3 bg-blue-600 hover:bg-blue-500 text-white font-black text-xs rounded-xl shadow-lg shadow-blue-600/30 transition-all active:scale-95 flex items-center gap-2"
            >
              <span>Checkout</span>
              <Check className="w-4 h-4" />
            </button>
          </div>
        ) : (
          <div className="p-3.5 bg-[#141414] border border-[#262626] rounded-2xl flex items-center gap-3 text-xs text-gray-400 shadow-xl">
            <ShoppingCart className="w-5 h-5 text-gray-500 ml-1" />
            <span>No items yet — <b className="text-blue-400">Start with a product</b></span>
          </div>
        )}
      </div>

      {/* CART DRAWER MODAL */}
      <Modal
        isOpen={cartDrawerOpen}
        onClose={() => setCartDrawerOpen(false)}
        title="Cart Items"
        subtitle={`${cartItemCount} items in current sale`}
        maxWidth="md"
      >
        <div className="space-y-3">
          <div className="space-y-2 max-h-60 overflow-y-auto">
            {cart.map((item) => (
              <div
                key={item.product.id}
                className="p-3 bg-[#1f1f1f] rounded-xl border border-[#2e2e2e] flex items-center justify-between"
              >
                <div>
                  <h4 className="text-xs font-bold text-white">{item.product.name}</h4>
                  <p className="text-[11px] text-gray-400">{formatMoney(item.unit_price)} each</p>
                </div>
                <div className="flex items-center gap-2">
                  <div className="flex items-center gap-1 bg-[#141414] rounded-lg p-1 border border-[#2e2e2e]">
                    <button
                      onClick={() => updateCartQuantity(item.product.id, item.quantity - 1)}
                      className="w-5 h-5 rounded bg-[#242424] text-gray-300 flex items-center justify-center"
                    >
                      <Minus className="w-3 h-3" />
                    </button>
                    <span className="text-xs font-bold text-white px-2">{item.quantity}</span>
                    <button
                      onClick={() => updateCartQuantity(item.product.id, item.quantity + 1)}
                      className="w-5 h-5 rounded bg-[#242424] text-gray-300 flex items-center justify-center"
                    >
                      <Plus className="w-3 h-3" />
                    </button>
                  </div>
                  <button
                    onClick={() => removeFromCart(item.product.id)}
                    className="p-1 text-gray-500 hover:text-red-400"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            ))}
          </div>

          <div className="pt-2 border-t border-[#2a2a2a] flex justify-between font-black text-white text-sm">
            <span>Total:</span>
            <span className="text-blue-400">{formatMoney(cartTotal)}</span>
          </div>

          <button
            onClick={() => {
              setCartDrawerOpen(false);
              setCheckoutModalOpen(true);
            }}
            className="w-full py-3 bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs rounded-xl shadow-lg shadow-blue-600/30"
          >
            Proceed to Checkout
          </button>
        </div>
      </Modal>

      {/* CHECKOUT MODAL */}
      <Modal
        isOpen={checkoutModalOpen}
        onClose={() => setCheckoutModalOpen(false)}
        title="Complete Transaction"
        subtitle={`Total Due: ${formatMoney(totalCalculated)}`}
        maxWidth="md"
      >
        <form onSubmit={handleCheckoutSubmit} className="space-y-4">
          {checkoutError && (
            <div className="p-3 bg-red-500/10 border border-red-500/30 rounded-xl text-xs text-red-400 flex items-center gap-2">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{checkoutError}</span>
            </div>
          )}

          {/* Customer Name */}
          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
              Customer Name
            </label>
            <input
              type="text"
              placeholder="e.g. Juan Dela Cruz (or leave blank for Walk-in)"
              value={customerName}
              onChange={(e) => setCustomerName(e.target.value)}
              className="w-full px-4 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500"
            />
          </div>

          {/* Payment Method Selector */}
          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
              Payment Method
            </label>
            <div className="grid grid-cols-3 sm:grid-cols-5 gap-2">
              {[
                { id: 'cash', label: 'Cash', icon: Banknote },
                { id: 'gcash', label: 'GCash', icon: Smartphone },
                { id: 'maya', label: 'Maya', icon: Smartphone },
                { id: 'bank_transfer', label: 'Bank', icon: Building2 },
                { id: 'credit', label: 'Credit', icon: CreditCard },
              ].map((pm) => {
                const Icon = pm.icon;
                const isSelected = paymentMethod === pm.id;
                return (
                  <button
                    key={pm.id}
                    type="button"
                    onClick={() => {
                      setPaymentMethod(pm.id as any);
                      if (pm.id !== 'cash') {
                        setAmountReceived(totalCalculated.toString());
                      }
                    }}
                    className={`p-2.5 rounded-xl border flex flex-col items-center justify-center gap-1 transition-all ${
                      isSelected
                        ? 'bg-blue-600 border-blue-500 text-white shadow-md'
                        : 'bg-[#1f1f1f] border-[#2e2e2e] text-gray-400 hover:text-white'
                    }`}
                  >
                    <Icon className="w-4 h-4" />
                    <span className="text-[11px] font-bold">{pm.label}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Discount & Amount Received */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
                Extra Discount (₱)
              </label>
              <input
                type="number"
                min="0"
                step="0.01"
                value={saleDiscount}
                onChange={(e) => setSaleDiscount(e.target.value)}
                className="w-full px-4 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
                Amount Received (₱) *
              </label>
              <input
                type="number"
                min="0"
                step="0.01"
                required
                placeholder="0.00"
                value={amountReceived}
                onChange={(e) => setAmountReceived(e.target.value)}
                className="w-full px-4 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-sm text-white font-bold focus:outline-none focus:border-blue-500"
              />
            </div>
          </div>

          {/* Quick Cash Buttons */}
          {paymentMethod === 'cash' && (
            <div className="space-y-1.5">
              <span className="text-[11px] text-gray-400 font-semibold">Quick Cash:</span>
              <div className="flex gap-2">
                {[
                  { label: 'Exact', val: 0 },
                  { label: '+₱50', val: 50 },
                  { label: '+₱100', val: 100 },
                  { label: '+₱500', val: 500 },
                  { label: '+₱1,000', val: 1000 },
                ].map((btn, idx) => (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => handleQuickCash(btn.val)}
                    className="flex-1 py-1.5 bg-[#222222] hover:bg-[#2c2c2c] text-blue-400 font-bold text-xs rounded-lg border border-[#333333] transition-colors"
                  >
                    {btn.label}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Change Display */}
          <div className="p-3 bg-[#111111] rounded-xl border border-[#222222] flex items-center justify-between">
            <span className="text-xs font-bold text-gray-400">Change Due:</span>
            <span className="text-base font-black text-emerald-400">
              {formatMoney(changeCalculated)}
            </span>
          </div>

          {/* Checkout Notes */}
          <div>
            <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-1.5">
              Transaction Notes
            </label>
            <input
              type="text"
              placeholder="e.g. Plate # ABC-1234, Honda Click 125i"
              value={checkoutNotes}
              onChange={(e) => setCheckoutNotes(e.target.value)}
              className="w-full px-4 py-2 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-blue-500"
            />
          </div>

          {/* Footer Submit */}
          <div className="flex gap-2 pt-2">
            <button
              type="button"
              onClick={() => setCheckoutModalOpen(false)}
              className="flex-1 py-3 text-xs font-semibold text-gray-400 bg-[#222222] hover:bg-[#2a2a2a] rounded-xl"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 py-3 bg-blue-600 hover:bg-blue-500 text-white font-black text-xs rounded-xl shadow-lg shadow-blue-600/30 flex items-center justify-center gap-1.5"
            >
              <Check className="w-4 h-4" />
              <span>Confirm & Print Receipt</span>
            </button>
          </div>
        </form>
      </Modal>

      {/* Barcode Scanner Modal */}
      <BarcodeScannerModal
        isOpen={scannerOpen}
        onClose={() => setScannerOpen(false)}
        onScan={handleBarcodeScanned}
      />

      {/* Receipt Modal */}
      <ReceiptModal
        isOpen={!!completedSale}
        onClose={() => setCompletedSale(null)}
        sale={completedSale}
      />
    </div>
  );
};
