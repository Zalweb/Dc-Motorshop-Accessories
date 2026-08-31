import React, { useState } from 'react';
import { Tags, Plus, Trash2, ChevronLeft, Check, Sparkles } from 'lucide-react';
import { useInventory } from '../../context/InventoryContext';

interface CategoriesProps {
  onBack: () => void;
}

export const Categories: React.FC<CategoriesProps> = ({ onBack }) => {
  const { categories, addCategory, deleteCategory } = useInventory();
  const [newCatName, setNewCatName] = useState<string>('');
  const [isService, setIsService] = useState<boolean>(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newCatName.trim()) return;
    await addCategory(newCatName.trim(), isService);
    setNewCatName('');
    setIsService(false);
  };

  return (
    <div className="max-w-2xl mx-auto space-y-5 pb-20 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button
          onClick={onBack}
          className="p-2 rounded-xl bg-[#1c1c1c] hover:bg-[#252525] border border-[#2a2a2a] text-gray-300 transition-colors"
        >
          <ChevronLeft className="w-5 h-5" />
        </button>
        <div>
          <h1 className="text-xl font-black text-white tracking-tight">Categories</h1>
          <p className="text-xs text-gray-400">Manage catalog sections & labor categories</p>
        </div>
      </div>

      {/* Add Category Card */}
      <div className="p-5 rounded-3xl bg-[#141414] border border-[#262626] shadow-xl space-y-3">
        <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider">
          Add New Category
        </h3>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="flex gap-2">
            <input
              type="text"
              placeholder="e.g. Suspension & Shock Absorbers"
              value={newCatName}
              onChange={(e) => setNewCatName(e.target.value)}
              className="flex-1 px-4 py-2.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-xs text-white focus:outline-none focus:border-blue-500 font-medium"
            />
            <button
              type="submit"
              disabled={!newCatName.trim()}
              className="px-4 py-2.5 bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white font-bold text-xs rounded-xl shadow-md shadow-blue-600/30 flex items-center gap-1.5 transition-all"
            >
              <Plus className="w-4 h-4" />
              <span>Add</span>
            </button>
          </div>

          <label className="flex items-center gap-2 text-xs text-gray-400 cursor-pointer">
            <input
              type="checkbox"
              checked={isService}
              onChange={(e) => setIsService(e.target.checked)}
              className="rounded bg-[#1c1c1c] border-gray-700 text-blue-600 focus:ring-0"
            />
            <span>This is a Service / Labor fee category</span>
          </label>
        </form>
      </div>

      {/* Categories List */}
      <div className="space-y-2">
        <div className="flex justify-between items-center px-1 text-xs font-bold text-gray-400 uppercase">
          <span>Catalog Categories ({categories.length})</span>
        </div>

        <div className="bg-[#141414] border border-[#262626] rounded-3xl divide-y divide-[#222222] overflow-hidden shadow-xl">
          {categories.map((cat) => (
            <div
              key={cat.id}
              className="p-4 flex items-center justify-between hover:bg-[#181818] transition-colors"
            >
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-blue-500/10 border border-blue-500/20 text-blue-400 flex items-center justify-center">
                  <Tags className="w-4 h-4" />
                </div>
                <div>
                  <span className="font-bold text-sm text-white">{cat.name}</span>
                  <div className="flex items-center gap-2 mt-0.5">
                    <span className="text-[10px] font-bold px-1.5 py-0.2 rounded bg-blue-400/10 text-blue-400">
                      TOP
                    </span>
                    {cat.is_service && (
                      <span className="text-[10px] font-bold px-1.5 py-0.2 rounded bg-purple-500/20 text-purple-300">
                        Service
                      </span>
                    )}
                  </div>
                </div>
              </div>

              <button
                onClick={() => {
                  if (confirm(`Remove category "${cat.name}"?`)) deleteCategory(cat.id);
                }}
                className="text-gray-500 hover:text-red-400 p-2 rounded-xl hover:bg-red-500/10 transition-colors"
                title="Delete Category"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
