import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '../core/supabase/supabaseClient';
import { Expense } from '../core/types';
import { INITIAL_EXPENSES } from '../core/storage/seedData';
import { useAuth } from './AuthContext';
import { useBusiness } from './BusinessContext';

interface ExpenseContextType {
  expenses: Expense[];
  loading: boolean;
  addExpense: (expense: Omit<Expense, 'id' | 'business_id' | 'created_at'>) => Promise<Expense>;
  deleteExpense: (id: string) => Promise<void>;
  totalExpenses: number;
  refreshExpenses: () => Promise<void>;
  clearAllExpenses: () => void;
}

const ExpenseContext = createContext<ExpenseContextType | undefined>(undefined);

export const ExpenseProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user } = useAuth();
  const { profile } = useBusiness();

  const [expenses, setExpenses] = useState<Expense[]>(() => {
    const saved = localStorage.getItem('dc_expenses');
    return saved ? JSON.parse(saved) : INITIAL_EXPENSES;
  });
  const [loading, setLoading] = useState<boolean>(false);

  const refreshExpenses = async () => {
    if (!user) return;
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('expenses')
        .select('*')
        .eq('business_id', profile.id)
        .is('deleted_at', null)
        .order('spent_on', { ascending: false });

      if (data && !error) {
        const mapped: Expense[] = data.map((e) => ({
          id: e.id,
          business_id: e.business_id,
          label: e.label,
          amount: Number(e.amount) || 0,
          note: e.note,
          type: e.type || 'variable',
          category: e.category,
          frequency: e.frequency,
          end_date: e.end_date,
          include_in_calculations: e.include_in_calculations ?? true,
          spent_on: e.spent_on || new Date().toISOString().split('T')[0],
          created_at: e.created_at,
          updated_at: e.updated_at,
          deleted_at: e.deleted_at,
        }));
        setExpenses(mapped);
        localStorage.setItem('dc_expenses', JSON.stringify(mapped));
      }
    } catch (err) {
      console.warn('Error fetching expenses from Supabase:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    refreshExpenses();
  }, [user, profile.id]);

  const addExpense = async (expenseData: Omit<Expense, 'id' | 'business_id' | 'created_at'>): Promise<Expense> => {
    const newExp: Expense = {
      ...expenseData,
      id: `exp-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      business_id: profile.id,
      created_at: new Date().toISOString(),
    };

    const updated = [newExp, ...expenses];
    setExpenses(updated);
    localStorage.setItem('dc_expenses', JSON.stringify(updated));

    if (user?.id) {
      try {
        await supabase.from('expenses').insert({
          id: newExp.id,
          business_id: profile.id,
          label: newExp.label,
          amount: newExp.amount,
          note: newExp.note || null,
          type: newExp.type,
          category: newExp.category || null,
          frequency: newExp.frequency || null,
          end_date: newExp.end_date || null,
          include_in_calculations: newExp.include_in_calculations,
          spent_on: newExp.spent_on,
        });
      } catch (err) {
        console.warn('Failed to insert expense in Supabase:', err);
      }
    }

    return newExp;
  };

  const deleteExpense = async (id: string) => {
    const updated = expenses.filter((e) => e.id !== id);
    setExpenses(updated);
    localStorage.setItem('dc_expenses', JSON.stringify(updated));

    if (user?.id) {
      try {
        await supabase
          .from('expenses')
          .update({ deleted_at: new Date().toISOString() })
          .eq('id', id);
      } catch (err) {
        console.warn('Failed to soft delete expense in Supabase:', err);
      }
    }
  };

  const clearAllExpenses = () => {
    setExpenses([]);
    localStorage.removeItem('dc_expenses');
  };

  const totalExpenses = expenses
    .filter((e) => e.include_in_calculations)
    .reduce((sum, e) => sum + e.amount, 0);

  return (
    <ExpenseContext.Provider
      value={{
        expenses,
        loading,
        addExpense,
        deleteExpense,
        totalExpenses,
        refreshExpenses,
        clearAllExpenses,
      }}
    >
      {children}
    </ExpenseContext.Provider>
  );
};

export const useExpenses = (): ExpenseContextType => {
  const context = useContext(ExpenseContext);
  if (!context) {
    throw new Error('useExpenses must be used within an ExpenseProvider');
  }
  return context;
};
