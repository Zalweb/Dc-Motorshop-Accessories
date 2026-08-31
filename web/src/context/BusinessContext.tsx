import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase, kProductImagesBucket } from '../core/supabase/supabaseClient';
import { BusinessProfile, ClosedDay, ThemeColor } from '../core/types';
import { INITIAL_BUSINESS_PROFILE } from '../core/storage/seedData';
import { useAuth } from './AuthContext';
import { useTheme } from '../core/theme/ThemeContext';

interface BusinessContextType {
  profile: BusinessProfile;
  updateProfile: (updates: Partial<BusinessProfile>) => Promise<void>;
  uploadLogo: (file: File) => Promise<string | null>;
  toggleChecklistItem: (itemId: string) => Promise<void>;
  addClosedDay: (day: Omit<ClosedDay, 'id'>) => Promise<void>;
  removeClosedDay: (id: string) => Promise<void>;
  isChecklistDone: (itemId: string) => boolean;
  completedChecklistCount: number;
}

const BusinessContext = createContext<BusinessContextType | undefined>(undefined);

export const BusinessProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user } = useAuth();
  const { setThemeColor } = useTheme();

  const [profile, setProfile] = useState<BusinessProfile>(() => {
    const saved = localStorage.getItem('dc_business_profile');
    return saved ? JSON.parse(saved) : INITIAL_BUSINESS_PROFILE;
  });

  // Fetch business profile from Supabase on login
  useEffect(() => {
    if (!user) return;

    const fetchProfile = async () => {
      try {
        const { data, error } = await supabase
          .from('business_profiles')
          .select('*')
          .eq('owner_id', user.id)
          .maybeSingle();

        if (data && !error) {
          const loaded: BusinessProfile = {
            id: data.id,
            owner_id: data.owner_id,
            business_name: data.business_name || 'DC Motorshop & Accessories',
            business_type: data.business_type || 'Motorcycle Shop',
            address: data.address || '',
            phone: data.phone || '',
            email: data.email || user.email,
            timezone: data.timezone || 'Asia/Manila (GMT+8)',
            currency: data.currency || 'PHP — Philippine Peso',
            theme_color: (data.theme_color as ThemeColor) || 'Blue',
            logo_url: data.logo_url || '/logo.svg',
            receipt_qr_link: data.receipt_qr_link || '',
            onboarding_complete: data.onboarding_complete ?? true,
            onboarding_checklist: Array.isArray(data.onboarding_checklist)
              ? data.onboarding_checklist
              : typeof data.onboarding_checklist === 'string'
              ? JSON.parse(data.onboarding_checklist)
              : [],
            allow_sell_when_out_of_stock: data.allow_sell_when_out_of_stock ?? false,
            track_partial_change: data.track_partial_change ?? false,
            include_unpaid_in_reports: data.include_unpaid_in_reports ?? true,
            closed_days: data.closed_days || [],
          };
          setProfile(loaded);
          setThemeColor(loaded.theme_color);
          localStorage.setItem('dc_business_profile', JSON.stringify(loaded));
        }
      } catch (err) {
        console.warn('Could not fetch Supabase business profile:', err);
      }
    };

    fetchProfile();
  }, [user]);

  const updateProfile = async (updates: Partial<BusinessProfile>) => {
    const updated: BusinessProfile = { ...profile, ...updates };
    setProfile(updated);
    localStorage.setItem('dc_business_profile', JSON.stringify(updated));

    if (updates.theme_color) {
      setThemeColor(updates.theme_color);
    }

    if (user?.id) {
      try {
        await supabase.from('business_profiles').upsert({
          id: updated.id,
          owner_id: user.id,
          business_name: updated.business_name,
          business_type: updated.business_type,
          address: updated.address,
          phone: updated.phone,
          email: updated.email,
          timezone: updated.timezone,
          currency: updated.currency,
          theme_color: updated.theme_color,
          logo_url: updated.logo_url,
          receipt_qr_link: updated.receipt_qr_link,
          onboarding_complete: updated.onboarding_complete,
          onboarding_checklist: updated.onboarding_checklist,
          allow_sell_when_out_of_stock: updated.allow_sell_when_out_of_stock,
          track_partial_change: updated.track_partial_change,
          include_unpaid_in_reports: updated.include_unpaid_in_reports,
          updated_at: new Date().toISOString(),
        });
      } catch (err) {
        console.warn('Failed to upsert Supabase business profile:', err);
      }
    }
  };

  const uploadLogo = async (file: File): Promise<string | null> => {
    try {
      const fileExt = file.name.split('.').pop();
      const fileName = `logo_${Date.now()}.${fileExt}`;
      const filePath = `logos/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from(kProductImagesBucket)
        .upload(filePath, file, { upsert: true });

      if (uploadError) {
        console.warn('Storage upload error:', uploadError);
        // Fallback to local Data URL
        return new Promise((resolve) => {
          const reader = new FileReader();
          reader.onloadend = () => {
            const dataUrl = reader.result as string;
            updateProfile({ logo_url: dataUrl });
            resolve(dataUrl);
          };
          reader.readAsDataURL(file);
        });
      }

      const { data } = supabase.storage.from(kProductImagesBucket).getPublicUrl(filePath);
      const publicUrl = data.publicUrl;
      await updateProfile({ logo_url: publicUrl });
      return publicUrl;
    } catch (e) {
      console.warn('Upload exception:', e);
      return null;
    }
  };

  const toggleChecklistItem = async (itemId: string) => {
    const currentList = profile.onboarding_checklist || [];
    let updatedList: string[];
    if (currentList.includes(itemId)) {
      updatedList = currentList.filter((id) => id !== itemId);
    } else {
      updatedList = [...currentList, itemId];
    }
    await updateProfile({ onboarding_checklist: updatedList });
  };

  const addClosedDay = async (day: Omit<ClosedDay, 'id'>) => {
    const newDay: ClosedDay = {
      ...day,
      id: `cd-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
    };
    const updatedDays = [...(profile.closed_days || []), newDay];
    await updateProfile({ closed_days: updatedDays });
  };

  const removeClosedDay = async (id: string) => {
    const updatedDays = (profile.closed_days || []).filter((d) => d.id !== id);
    await updateProfile({ closed_days: updatedDays });
  };

  const isChecklistDone = (itemId: string): boolean => {
    return (profile.onboarding_checklist || []).includes(itemId);
  };

  const completedChecklistCount = (profile.onboarding_checklist || []).length;

  return (
    <BusinessContext.Provider
      value={{
        profile,
        updateProfile,
        uploadLogo,
        toggleChecklistItem,
        addClosedDay,
        removeClosedDay,
        isChecklistDone,
        completedChecklistCount,
      }}
    >
      {children}
    </BusinessContext.Provider>
  );
};

export const useBusiness = (): BusinessContextType => {
  const context = useContext(BusinessContext);
  if (!context) {
    throw new Error('useBusiness must be used within a BusinessProvider');
  }
  return context;
};
