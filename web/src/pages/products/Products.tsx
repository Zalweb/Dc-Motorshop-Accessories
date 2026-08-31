import React, { useState } from 'react';
import { 
  Search, 
  Plus, 
  Package, 
  Barcode, 
  Upload, 
  Camera, 
  Trash2, 
  Edit3, 
  Tags, 
  Layers, 
  Check, 
  Box,
  Sliders,
  Sparkles,
  X
} from 'lucide-react';
import { useInventory } from '../../context/InventoryContext';
import { formatMoney } from '../../core/utils/currency';
import { Product } from '../../core/types';
import { BarcodeScannerModal } from '../../components/ui/BarcodeScannerModal';
import { Modal } from '../../components/ui/Modal';

interface ProductsProps {
  onNavigate: (tab: string) => void;
}

export const Products: React.FC<ProductsProps> = ({ onNavigate }) => {
  const { 
    products, 
    categories, 
    addProduct, 
    updateProduct, 
    deleteProduct, 
    adjustStock, 
    uploadProductImage 
  } = useInventory();

  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedFilter, setSelectedFilter] = useState<string>('All');
  const [productModalOpen, setProductModalOpen] = useState<boolean>(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [scannerOpen, setScannerOpen] = useState<boolean>(false);
  const [speedDialOpen, setSpeedDialOpen] = useState<boolean>(false);

  // Add/Edit Product form state
  const [name, setName] = useState<string>('');
  const [barcode, setBarcode] = useState<string>('');
  const [partNumber, setPartNumber] = useState<string>('');
  const [brand, setBrand] = useState<string>('');
  const [category, setCategory] = useState<string>(categories[0]?.name || 'Engine Parts');
  const [description, setDescription] = useState<string>('');
  const [unit, setUnit] = useState<string>('piece');
  const [isService, setIsService] = useState<boolean>(false);
  const [costPrice, setCostPrice] = useState<string>('0');
  const [sellingPrice, setSellingPrice] = useState<string>('0');
  const [stockOnHand, setStockOnHand] = useState<number>(10);
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [uploadingImage, setUploadingImage] = useState<boolean>(false);

  const filterOptions = ['All', ...categories.map((c) => c.name)];

  const filteredProducts = products.filter((p) => {
    if (selectedFilter !== 'All') {
      if (p.category !== selectedFilter) return false;
    }
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      return (
        p.name.toLowerCase().includes(q) ||
        (p.barcode?.toLowerCase().includes(q) ?? false) ||
        (p.category?.toLowerCase().includes(q) ?? false)
      );
    }
    return true;
  });

  const openAddModal = () => {
    setEditingProduct(null);
    setName('');
    setBarcode('');
    setPartNumber('');
    setBrand('');
    setCategory(categories[0]?.name || 'Engine Parts');
    setDescription('');
    setUnit('piece');
    setIsService(false);
    setCostPrice('0');
    setSellingPrice('0');
    setStockOnHand(10);
    setImageUrl(null);
    setSpeedDialOpen(false);
    setProductModalOpen(true);
  };

  const openEditModal = (p: Product) => {
    setEditingProduct(p);
    setName(p.name);
    setBarcode(p.barcode || '');
    setPartNumber(p.part_number || '');
    setBrand(p.brand || '');
    setCategory(p.category || 'Engine Parts');
    setDescription(p.description || '');
    setUnit(p.unit || 'piece');
    setIsService(p.is_service);
    setCostPrice(p.cost_price.toString());
    setSellingPrice(p.selling_price.toString());
    setStockOnHand(p.stock_on_hand);
    setImageUrl(p.image_url || null);
    setProductModalOpen(true);
  };

  const handleImageFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setUploadingImage(true);
      const url = await uploadProductImage(e.target.files[0]);
      if (url) setImageUrl(url);
      setUploadingImage(false);
    }
  };

  const handleFormSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    const prodData = {
      name: name.trim(),
      barcode: barcode.trim() || null,
      part_number: partNumber.trim() || null,
      brand: brand.trim() || null,
      category: category,
      description: description.trim() || null,
      unit,
      is_service: isService,
      cost_price: parseFloat(costPrice) || 0,
      selling_price: parseFloat(sellingPrice) || 0,
      stock_on_hand: isService ? 999 : stockOnHand,
      image_url: imageUrl,
    };

    if (editingProduct) {
      await updateProduct(editingProduct.id, prodData);
    } else {
      await addProduct(prodData);
    }

    setProductModalOpen(false);
  };

  return (
    <div className="max-w-4xl mx-auto space-y-4 pb-32 animate-fade-in relative">
      {/* Header (Matching Image 12.jpg & products_screen.dart) */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-black text-white tracking-tight leading-none">
            Products
          </h1>
          <p className="text-xs text-gray-400 mt-1">
            {filteredProducts.length} {filteredProducts.length === 1 ? 'product' : 'products'}
          </p>
        </div>
      </div>

      {/* Search Bar */}
      <div className="relative">
        <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
        <input
          type="text"
          placeholder="Search products..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full pl-10 pr-4 py-3 bg-[#141414] border border-[#262626] rounded-2xl text-xs text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 shadow-sm"
        />
      </div>

      {/* Filter Chips Bar (Image 12.jpg) */}
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

      {/* Products List / Empty State (Image 12.jpg) */}
      {filteredProducts.length > 0 ? (
        <div className="space-y-2.5">
          {filteredProducts.map((p) => {
            const isOutOfStock = !p.is_service && p.stock_on_hand <= 0;
            const isLowStock = !p.is_service && p.stock_on_hand > 0 && p.stock_on_hand <= 5;

            return (
              <div
                key={p.id}
                onClick={() => openEditModal(p)}
                className="p-3.5 rounded-2xl bg-[#141414] border border-[#262626] hover:border-gray-600 transition-all flex items-center justify-between cursor-pointer group"
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
                        <span className="text-amber-400 font-bold">{p.stock_on_hand} left (Low)</span>
                      ) : (
                        <span className="text-emerald-400 font-semibold">{p.stock_on_hand} in stock</span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-3 shrink-0">
                  <div className="text-right">
                    <span className="text-sm font-black text-blue-400 block">
                      {formatMoney(p.selling_price)}
                    </span>
                    <span className="text-[10px] text-gray-500">
                      Cost: {formatMoney(p.cost_price)}
                    </span>
                  </div>

                  <div className="flex items-center gap-1">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        openEditModal(p);
                      }}
                      className="p-1.5 rounded-lg text-gray-400 hover:text-blue-400 hover:bg-[#222222] transition-colors"
                      title="Edit"
                    >
                      <Edit3 className="w-4 h-4" />
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        if (confirm(`Delete ${p.name}?`)) deleteProduct(p.id);
                      }}
                      className="p-1.5 rounded-lg text-gray-500 hover:text-red-400 hover:bg-red-500/10 transition-colors"
                      title="Delete"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        /* Empty State (Exact Reference Image 12.jpg) */
        <div className="py-20 text-center space-y-4">
          <div className="w-16 h-16 rounded-3xl bg-[#141414] border border-[#262626] flex items-center justify-center mx-auto text-gray-500">
            <Box className="w-8 h-8" />
          </div>
          <div>
            <h3 className="text-base font-bold text-white">No products found</h3>
            <p className="text-xs text-gray-400 mt-1">Add products to get started.</p>
          </div>
          <button
            onClick={openAddModal}
            className="px-5 py-2.5 bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs rounded-xl shadow-lg shadow-blue-600/30 transition-all"
          >
            Add a product
          </button>
        </div>
      )}

      {/* SPEED DIAL FAB BUTTON (Exact Reference Image 12.1.jpg) */}
      <div className="fixed bottom-20 lg:bottom-6 right-6 z-40">
        {/* Speed Dial Menu Items */}
        {speedDialOpen && (
          <div className="flex flex-col items-end gap-2.5 mb-3 animate-fade-in">
            {/* 1. Add Product */}
            <button
              onClick={openAddModal}
              className="flex items-center gap-2 px-3.5 py-2 rounded-2xl bg-[#171717] border border-[#2c2c2c] text-white text-xs font-bold shadow-xl hover:bg-[#222222] transition-all"
            >
              <span>Add Product</span>
              <div className="w-8 h-8 rounded-xl bg-blue-600 text-white flex items-center justify-center">
                <Plus className="w-4 h-4" />
              </div>
            </button>

            {/* 2. Bulk Add */}
            <button
              onClick={() => {
                setSpeedDialOpen(false);
                onNavigate('bulk-add');
              }}
              className="flex items-center gap-2 px-3.5 py-2 rounded-2xl bg-[#171717] border border-[#2c2c2c] text-white text-xs font-bold shadow-xl hover:bg-[#222222] transition-all"
            >
              <span>Bulk Add</span>
              <div className="w-8 h-8 rounded-xl bg-purple-600 text-white flex items-center justify-center">
                <Layers className="w-4 h-4" />
              </div>
            </button>

            {/* 3. Categories */}
            <button
              onClick={() => {
                setSpeedDialOpen(false);
                onNavigate('categories');
              }}
              className="flex items-center gap-2 px-3.5 py-2 rounded-2xl bg-[#171717] border border-[#2c2c2c] text-white text-xs font-bold shadow-xl hover:bg-[#222222] transition-all"
            >
              <span>Categories</span>
              <div className="w-8 h-8 rounded-xl bg-emerald-600 text-white flex items-center justify-center">
                <Tags className="w-4 h-4" />
              </div>
            </button>
          </div>
        )}

        {/* Main Blue Floating Action Button */}
        <button
          onClick={() => setSpeedDialOpen(!speedDialOpen)}
          className={`w-14 h-14 rounded-full bg-blue-600 hover:bg-blue-500 text-white flex items-center justify-center shadow-2xl shadow-blue-600/50 transition-all ${
            speedDialOpen ? 'rotate-45' : ''
          }`}
        >
          <Plus className="w-7 h-7" />
        </button>
      </div>

      {/* ADD / EDIT PRODUCT MODAL (Exact Reference Image 12.1.3.jpg) */}
      <Modal
        isOpen={productModalOpen}
        onClose={() => setProductModalOpen(false)}
        title={editingProduct ? 'Edit Product' : 'Add Product'}
        subtitle="Catalog & stock management"
        maxWidth="lg"
      >
        <form onSubmit={handleFormSubmit} className="space-y-4">
          {/* SECTION: PRODUCT IMAGE (12.1.3) */}
          <div>
            <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5">
              Product Image · Optional
            </label>
            <div className="flex items-center gap-3">
              <div className="w-20 h-20 rounded-2xl bg-[#1f1f1f] border-2 border-dashed border-[#333333] flex items-center justify-center overflow-hidden relative">
                {imageUrl ? (
                  <img src={imageUrl} alt="Product" className="w-full h-full object-cover" />
                ) : (
                  <Package className="w-8 h-8 text-gray-600" />
                )}
                {uploadingImage && (
                  <div className="absolute inset-0 bg-black/60 flex items-center justify-center">
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  </div>
                )}
              </div>
              <label className="cursor-pointer px-4 py-2 bg-[#1f1f1f] hover:bg-[#282828] border border-[#2e2e2e] text-xs font-bold text-gray-300 hover:text-white rounded-xl flex items-center gap-2 transition-colors">
                <Upload className="w-4 h-4 text-blue-400" />
                <span>Tap to add photo</span>
                <input type="file" accept="image/*" onChange={handleImageFileChange} className="hidden" />
              </label>
            </div>
          </div>

          {/* SECTION: BARCODE OPTIONAL (12.1.3) */}
          <div>
            <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5">
              Barcode (Optional)
            </label>
            <div className="flex gap-2">
              <input
                type="text"
                placeholder="Enter barcode"
                value={barcode}
                onChange={(e) => setBarcode(e.target.value)}
                className="flex-1 px-3.5 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-blue-500"
              />
              <button
                type="button"
                onClick={() => setScannerOpen(true)}
                className="px-3 bg-blue-600 hover:bg-blue-500 text-white rounded-xl flex items-center justify-center shadow-md shadow-blue-600/30"
              >
                <Barcode className="w-4 h-4" />
              </button>
            </div>
            <p className="text-[11px] text-gray-400 mt-1">
              Scan with camera or enter manually, then tap lookup to auto-fill
            </p>
          </div>

          {/* SECTION: PRODUCT DETAILS (12.1.3) */}
          <div className="space-y-3 pt-2 border-t border-[#242424]">
            <div>
              <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5">
                Name *
              </label>
              <input
                type="text"
                required
                placeholder="Product name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full px-3.5 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500 font-semibold"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5">
                  Category
                </label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="w-full px-3 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-blue-500"
                >
                  {categories.map((c) => (
                    <option key={c.id} value={c.name}>
                      {c.name} {c.is_service ? '(Service)' : ''}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5">
                  Brand
                </label>
                <input
                  type="text"
                  placeholder="e.g. NGK, Bendix, Motul"
                  value={brand}
                  onChange={(e) => setBrand(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-blue-500"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5">
                  Part Number
                </label>
                <input
                  type="text"
                  placeholder="OEM or aftermarket part #"
                  value={partNumber}
                  onChange={(e) => setPartNumber(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-blue-500"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5">
                  Unit
                </label>
                <select
                  value={unit}
                  onChange={(e) => setUnit(e.target.value)}
                  className="w-full px-3 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-blue-500"
                >
                  <option value="piece">piece</option>
                  <option value="liter">liter</option>
                  <option value="set">set</option>
                  <option value="pair">pair</option>
                  <option value="box">box</option>
                  <option value="service">service</option>
                </select>
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-1.5">
                Description
              </label>
              <textarea
                rows={2}
                placeholder="Product description (optional)..."
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full px-3.5 py-2 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-xs text-white focus:outline-none focus:border-blue-500"
              />
            </div>
          </div>

          {/* SECTION: PRICING (12.1.3.1) */}
          <div className="space-y-3 pt-2 border-t border-[#242424]">
            <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">Pricing</h4>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold text-gray-300 mb-1">
                  Cost Price (₱0.00)
                </label>
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  value={costPrice}
                  onChange={(e) => setCostPrice(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-300 mb-1">
                  Selling Price * (₱0.00)
                </label>
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  required
                  value={sellingPrice}
                  onChange={(e) => setSellingPrice(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-sm text-blue-400 font-bold focus:outline-none focus:border-blue-500"
                />
              </div>
            </div>
          </div>

          {/* SECTION: INVENTORY (12.1.3.2) */}
          {!isService && (
            <div className="space-y-3 pt-2 border-t border-[#242424]">
              <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">Inventory</h4>
              <div>
                <label className="block text-xs font-semibold text-gray-300 mb-1">
                  Stock Quantity
                </label>
                <input
                  type="number"
                  min="0"
                  value={stockOnHand}
                  onChange={(e) => setStockOnHand(parseInt(e.target.value) || 0)}
                  className="w-full px-3.5 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-sm text-white font-bold focus:outline-none focus:border-blue-500"
                />
              </div>

              {/* Quick Add Chips (12.1.3.2) */}
              <div className="flex items-center gap-1.5 flex-wrap">
                {[-1, 1, 5, 10, 50, 100].map((delta) => (
                  <button
                    key={delta}
                    type="button"
                    onClick={() => setStockOnHand(Math.max(0, stockOnHand + delta))}
                    className="px-2.5 py-1 rounded-lg bg-[#242424] hover:bg-[#2c2c2c] text-xs font-bold text-gray-300 hover:text-white border border-[#333333] transition-colors"
                  >
                    {delta > 0 ? `+${delta}` : delta}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Submit */}
          <div className="flex gap-2 pt-3">
            <button
              type="button"
              onClick={() => setProductModalOpen(false)}
              className="flex-1 py-3 bg-[#242424] text-gray-300 text-xs font-bold rounded-xl hover:bg-[#2a2a2a]"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 py-3 bg-blue-600 hover:bg-blue-500 text-white text-xs font-black rounded-xl shadow-lg shadow-blue-600/30 flex items-center justify-center gap-1.5"
            >
              <Check className="w-4 h-4" />
              <span>{editingProduct ? 'UPDATE PRODUCT' : 'ADD PRODUCT'}</span>
            </button>
          </div>
        </form>
      </Modal>

      {/* Barcode Scanner Modal */}
      <BarcodeScannerModal
        isOpen={scannerOpen}
        onClose={() => setScannerOpen(false)}
        onScan={(code) => {
          setBarcode(code);
          setSearchQuery(code);
        }}
      />
    </div>
  );
};
