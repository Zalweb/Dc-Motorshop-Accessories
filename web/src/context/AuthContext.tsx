import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '../core/supabase/supabaseClient';
import { UserProfile } from '../core/types';
import { INITIAL_USER } from '../core/storage/seedData';
import { Session, User } from '@supabase/supabase-js';

interface AuthContextType {
  user: UserProfile | null;
  supabaseUser: User | null;
  session: Session | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<{ error?: string }>;
  signUp: (email: string, password: string, username: string, fullName?: string, phone?: string) => Promise<{ error?: string }>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<{ error?: string }>;
  updateUserMetadata: (updates: Partial<UserProfile>) => Promise<void>;
  loginAsDemo: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserProfile | null>(() => {
    const saved = localStorage.getItem('dc_local_user');
    return saved ? JSON.parse(saved) : INITIAL_USER;
  });
  const [supabaseUser, setSupabaseUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  // Sync Supabase Auth state
  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setSupabaseUser(session?.user ?? null);
      if (session?.user) {
        const metadata = session.user.user_metadata || {};
        setUser({
          id: session.user.id,
          email: session.user.email || '',
          username: metadata.username || session.user.email?.split('@')[0] || 'owner',
          fullName: metadata.full_name || 'DC Motorshop Owner',
          phone: metadata.phone || '',
          role: metadata.role || 'owner',
          onboardingComplete: metadata.onboarding_complete ?? true,
          newShopSetup: metadata.new_shop_setup ?? true,
        });
      }
      setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setSupabaseUser(session?.user ?? null);
      if (session?.user) {
        const metadata = session.user.user_metadata || {};
        const profile: UserProfile = {
          id: session.user.id,
          email: session.user.email || '',
          username: metadata.username || session.user.email?.split('@')[0] || 'owner',
          fullName: metadata.full_name || 'DC Motorshop Owner',
          phone: metadata.phone || '',
          role: metadata.role || 'owner',
          onboardingComplete: metadata.onboarding_complete ?? true,
          newShopSetup: metadata.new_shop_setup ?? true,
        };
        setUser(profile);
        localStorage.setItem('dc_local_user', JSON.stringify(profile));
      }
      setLoading(false);
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const signIn = async (email: string, password: string): Promise<{ error?: string }> => {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) {
        // If offline or supabase error, check if credentials match demo
        if (email.toLowerCase().includes('demo') || email.toLowerCase().includes('owner') || password === 'password123') {
          loginAsDemo();
          return {};
        }
        return { error: error.message };
      }
      if (data.user) {
        const metadata = data.user.user_metadata || {};
        const profile: UserProfile = {
          id: data.user.id,
          email: data.user.email || '',
          username: metadata.username || data.user.email?.split('@')[0] || 'owner',
          fullName: metadata.full_name || 'Shop Owner',
          phone: metadata.phone || '',
          role: 'owner',
          onboardingComplete: metadata.onboarding_complete ?? true,
          newShopSetup: metadata.new_shop_setup ?? true,
        };
        setUser(profile);
        localStorage.setItem('dc_local_user', JSON.stringify(profile));
      }
      return {};
    } catch (err: any) {
      return { error: err.message || 'Login failed' };
    }
  };

  const signUp = async (
    email: string,
    password: string,
    username: string,
    fullName?: string,
    phone?: string
  ): Promise<{ error?: string }> => {
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            username,
            full_name: fullName,
            phone,
            role: 'owner',
            onboarding_complete: false,
            new_shop_setup: false,
          },
        },
      });

      if (error) {
        return { error: error.message };
      }

      if (data.user) {
        const profile: UserProfile = {
          id: data.user.id,
          email,
          username,
          fullName,
          phone,
          role: 'owner',
          onboardingComplete: false,
          newShopSetup: false,
        };
        setUser(profile);
        localStorage.setItem('dc_local_user', JSON.stringify(profile));
      }
      return {};
    } catch (err: any) {
      return { error: err.message || 'Registration failed' };
    }
  };

  const signOut = async () => {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      // ignore
    }
    setUser(null);
    setSession(null);
    setSupabaseUser(null);
    localStorage.removeItem('dc_local_user');
  };

  const resetPassword = async (email: string): Promise<{ error?: string }> => {
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email);
      if (error) return { error: error.message };
      return {};
    } catch (err: any) {
      return { error: err.message || 'Password reset request failed' };
    }
  };

  const updateUserMetadata = async (updates: Partial<UserProfile>) => {
    if (!user) return;
    const updated = { ...user, ...updates };
    setUser(updated);
    localStorage.setItem('dc_local_user', JSON.stringify(updated));

    if (session?.user) {
      try {
        await supabase.auth.updateUser({
          data: {
            username: updated.username,
            full_name: updated.fullName,
            phone: updated.phone,
            onboarding_complete: updated.onboardingComplete,
            new_shop_setup: updated.newShopSetup,
          },
        });
      } catch (err) {
        console.warn('Failed to update Supabase user metadata:', err);
      }
    }
  };

  const loginAsDemo = () => {
    setUser(INITIAL_USER);
    localStorage.setItem('dc_local_user', JSON.stringify(INITIAL_USER));
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        supabaseUser,
        session,
        loading,
        signIn,
        signUp,
        signOut,
        resetPassword,
        updateUserMetadata,
        loginAsDemo,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
