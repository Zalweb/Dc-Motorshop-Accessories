import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase, kProductImagesBucket } from '../core/supabase/supabaseClient';
import { Category, Product } from '../core/types';
import { DEFAULT_CATEGORIES, INITIAL_PRODUCTS, SAMPLE_DEV_PRODUCTS } from '../core/storage/seedData';
import { useAuth } from './AuthContext';
import { useBusiness } from './BusinessContext';

interface InventoryContextType {
  categories: Category[];
  products: Product[];
  loading: boolean;
  addCategory: (name: string, isService?: boolean) => Promise<Category>;
  updateCategory: (id: string, updates: Partial<Category>) => Promise<void>;
  deleteCategory: (id: string) => Promise<void>;
  addProduct: (product: Omit<Product, 'id' | 'business_id'>) => Promise<Product>;
  updateProduct: (id: string, updates: Partial<Product>) => Promise<void>;
  deleteProduct: (id: string) => Promise<void>;
  adjustStock: (id: string, delta: number) => Promise<void>;
  uploadProductImage: (file: File) => Promise<string | null>;
  bulkAddProducts: (newProducts: Array<Omit<Product, 'id' | 'business_id'>>) => Promise<void>;
  getProductById: (id: string) => Product | undefined;
  getProductByBarcode: (barcode: string) => Product | undefined;
  refreshInventory: () => Promise<void>;
  seedSampleCatalog: () => Promise<void>;
  clearAllProducts: () => void;
}

const InventoryContext = createContext<InventoryContextType | undefined>(undefined);

export const InventoryProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user } = useAuth();
  const { profile } = useBusiness();

  const [categories, setCategories] = useState<Category[]>(() => {
    const saved = localStorage.getItem('dc_categories');
    return saved ? JSON.parse(saved) : DEFAULT_CATEGORIES;
  });

  const [products, setProducts] = useState<Product[]>(() => {
    const saved = localStorage.getItem('dc_products');
    return saved ? JSON.parse(saved) : INITIAL_PRODUCTS;
  });

  const [loading, setLoading] = useState<boolean>(false);

  // Sync with Supabase on load
  const refreshInventory = async () => {
    if (!user) return;
    setLoading(true);

    try {
      // 1. Fetch Categories
      const { data: catData } = await supabase
        .from('categories')
        .select('*')
        .eq('business_id', profile.id)
        .is('deleted_at', null);

      if (catData && catData.length > 0) {
        setCategories(catData);
        localStorage.setItem('dc_categories', JSON.stringify(catData));
      }

      // 2. Fetch Products
      const { data: prodData } = await supabase
        .from('products')
        .select('*')
        .eq('business_id', profile.id)
        .is('deleted_at', null);

      if (prodData) {
        const mappedProds: Product[] = prodData.map((p) => ({
          id: p.id,
          business_id: p.business_id,
          name: p.name,
          barcode: p.barcode,
          part_number: p.part_number,
          description: p.description,
          category: p.category,
          brand: p.brand,
          unit: p.unit || 'piece',
          is_service: p.is_service ?? false,
          cost_price: Number(p.cost_price) || 0,
          selling_price: Number(p.selling_price) || 0,
          stock_on_hand: Number(p.stock_on_hand) || 0,
          image_url: p.image_url,
          created_at: p.created_at,
          updated_at: p.updated_at,
          deleted_at: p.deleted_at,
        }));
        setProducts(mappedProds);
        localStorage.setItem('dc_products', JSON.stringify(mappedProds));
      }
    } catch (err) {
      console.warn('Error fetching inventory from Supabase:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    refreshInventory();
  }, [user, profile.id]);

  // Categories CRUD
  const addCategory = async (name: string, isService: boolean = false): Promise<Category> => {
    const newCat: Category = {
      id: `cat-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      business_id: profile.id,
      name,
      is_service: isService,
      created_at: new Date().toISOString(),
    };
    const updated = [...categories, newCat];
    setCategories(updated);
    localStorage.setItem('dc_categories', JSON.stringify(updated));

    if (user?.id) {
      try {
        await supabase.from('categories').insert({
          id: newCat.id,
          business_id: profile.id,
          name: newCat.name,
          is_service: newCat.is_service,
        });
      } catch (err) {
        console.warn('Failed to insert category in Supabase:', err);
      }
    }
    return newCat;
  };

  const updateCategory = async (id: string, updates: Partial<Category>) => {
    const updated = categories.map((c) => (c.id === id ? { ...c, ...updates } : c));
    setCategories(updated);
    localStorage.setItem('dc_categories', JSON.stringify(updated));

    if (user?.id) {
      try {
        await supabase.from('categories').update(updates).eq('id', id);
      } catch (err) {
        console.warn('Failed to update category in Supabase:', err);
      }
    }
  };

  const deleteCategory = async (id: string) => {
    const updated = categories.filter((c) => c.id !== id);
    setCategories(updated);
    localStorage.setItem('dc_categories', JSON.stringify(updated));

    if (user?.id) {
      try {
        await supabase.from('categories').update({ deleted_at: new Date().toISOString() }).eq('id', id);
      } catch (err) {
        console.warn('Failed to soft-delete category in Supabase:', err);
      }
    }
  };

  // Products CRUD
  const addProduct = async (productData: Omit<Product, 'id' | 'business_id'>): Promise<Product> => {
    const newProd: Product = {
      ...productData,
      id: `prod-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
      business_id: profile.id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const updated = [newProd, ...products];
    setProducts(updated);
    localStorage.setItem('dc_products', JSON.stringify(updated));

    if (user?.id) {
      try {
        await supabase.from('products').insert({
          id: newProd.id,
          business_id: profile.id,
          name: newProd.name,
          barcode: newProd.barcode || null,
          part_number: newProd.part_number || null,
          description: newProd.description || null,
          category: newProd.category || null,
          brand: newProd.brand || null,
          unit: newProd.unit,
          is_service: newProd.is_service,
          cost_price: newProd.cost_price,
          selling_price: newProd.selling_price,
          stock_on_hand: newProd.stock_on_hand,
          image_url: newProd.image_url || null,
        });
      } catch (err) {
        console.warn('Failed to insert product in Supabase:', err);
      }
    }

    return newProd;
  };

  const updateProduct = async (id: string, updates: Partial<Product>) => {
    const updated = products.map((p) => (p.id === id ? { ...p, ...updates, updated_at: new Date().toISOString() } : p));
    setProducts(updated);
    localStorage.setItem('dc_products', JSON.stringify(updated));

    if (user?.id) {
      try {
        await supabase
          .from('products')
          .update({
            ...updates,
            updated_at: new Date().toISOString(),
          })
          .eq('id', id);
      } catch (err) {
        console.warn('Failed to update product in Supabase:', err);
      }
    }
  };

  const deleteProduct = async (id: string) => {
    const updated = products.filter((p) => p.id !== id);
    setProducts(updated);
    localStorage.setItem('dc_products', JSON.stringify(updated));

    if (user?.id) {
      try {
        await supabase
          .from('products')
          .update({ deleted_at: new Date().toISOString() })
          .eq('id', id);
      } catch (err) {
        console.warn('Failed to soft delete product in Supabase:', err);
      }
    }
  };

  const adjustStock = async (id: string, delta: number) => {
    const prod = products.find((p) => p.id === id);
    if (!prod) return;
    const newStock = Math.max(0, prod.stock_on_hand + delta);
    await updateProduct(id, { stock_on_hand: newStock });
  };

  const uploadProductImage = async (file: File): Promise<string | null> => {
    try {
      const fileExt = file.name.split('.').pop();
      const fileName = `prod_${Date.now()}_${Math.random().toString(36).substring(2, 7)}.${fileExt}`;
      const filePath = `products/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from(kProductImagesBucket)
        .upload(filePath, file, { upsert: true });

      if (uploadError) {
        console.warn('Image upload error:', uploadError);
        return new Promise((resolve) => {
          const reader = new FileReader();
          reader.onloadend = () => {
            resolve(reader.result as string);
          };
          reader.readAsDataURL(file);
        });
      }

      const { data } = supabase.storage.from(kProductImagesBucket).getPublicUrl(filePath);
      return data.publicUrl;
    } catch (e) {
      console.warn('Product image upload failed:', e);
      return null;
    }
  };

  const bulkAddProducts = async (newProducts: Array<Omit<Product, 'id' | 'business_id'>>) => {
    const createdList: Product[] = newProducts.map((p, idx) => ({
      ...p,
      id: `prod-${Date.now()}-${idx}-${Math.random().toString(36).substring(2, 6)}`,
      business_id: profile.id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }));

    const updated = [...createdList, ...products];
    setProducts(updated);
    localStorage.setItem('dc_products', JSON.stringify(updated));

    if (user?.id) {
      try {
        await supabase.from('products').insert(
          createdList.map((p) => ({
            id: p.id,
            business_id: profile.id,
            name: p.name,
            barcode: p.barcode || null,
            part_number: p.part_number || null,
            description: p.description || null,
            category: p.category || null,
            brand: p.brand || null,
            unit: p.unit,
            is_service: p.is_service,
            cost_price: p.cost_price,
            selling_price: p.selling_price,
            stock_on_hand: p.stock_on_hand,
            image_url: p.image_url || null,
          }))
        );
      } catch (err) {
        console.warn('Bulk insert error in Supabase:', err);
      }
    }
  };

  const seedSampleCatalog = async () => {
    await bulkAddProducts(SAMPLE_DEV_PRODUCTS);
  };

  const clearAllProducts = () => {
    setProducts([]);
    localStorage.removeItem('dc_products');
  };

  const getProductById = (id: string) => products.find((p) => p.id === id);

  const getProductByBarcode = (barcode: string) => {
    if (!barcode) return undefined;
    const clean = barcode.trim().toLowerCase();
    return products.find((p) => p.barcode?.trim().toLowerCase() === clean);
  };

  return (
    <InventoryContext.Provider
      value={{
        categories,
        products,
        loading,
        addCategory,
        updateCategory,
        deleteCategory,
        addProduct,
        updateProduct,
        deleteProduct,
        adjustStock,
        uploadProductImage,
        bulkAddProducts,
        getProductById,
        getProductByBarcode,
        refreshInventory,
        seedSampleCatalog,
        clearAllProducts,
      }}
    >
      {children}
    </InventoryContext.Provider>
  );
};

export const useInventory = (): InventoryContextType => {
  const context = useContext(InventoryContext);
  if (!context) {
    throw new Error('useInventory must be used within an InventoryProvider');
  }
  return context;
};
