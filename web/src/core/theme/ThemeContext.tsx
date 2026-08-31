import React, { createContext, useContext, useEffect, useState } from 'react';
import { ThemeColor } from '../types';

interface ThemeContextType {
  themeColor: ThemeColor;
  setThemeColor: (color: ThemeColor) => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export const THEME_SWATCHES: Array<{ name: ThemeColor; hex: string; lightHex: string }> = [
  { name: 'Blue', hex: '#2563EB', lightHex: '#3B82F6' },
  { name: 'Green', hex: '#16A34A', lightHex: '#22C55E' },
  { name: 'Purple', hex: '#7C3AED', lightHex: '#8B5CF6' },
  { name: 'Orange', hex: '#EA580C', lightHex: '#F97316' },
  { name: 'Rose', hex: '#E11D48', lightHex: '#F43F5E' },
  { name: 'Slate', hex: '#475569', lightHex: '#64748B' },
  { name: 'Teal', hex: '#0D9488', lightHex: '#14B8A6' },
  { name: 'Indigo', hex: '#4F46E5', lightHex: '#6366F1' },
  { name: 'Amber', hex: '#D97706', lightHex: '#F59E0B' },
  { name: 'Cyan', hex: '#0891B2', lightHex: '#06B6D4' },
];

export const ThemeProvider: React.FC<{ children: React.ReactNode; initialTheme?: ThemeColor }> = ({
  children,
  initialTheme = 'Blue',
}) => {
  const [themeColor, setThemeColorState] = useState<ThemeColor>(() => {
    return (localStorage.getItem('dc_theme_color') as ThemeColor) || initialTheme;
  });

  const setThemeColor = (color: ThemeColor) => {
    setThemeColorState(color);
    localStorage.setItem('dc_theme_color', color);
    document.documentElement.setAttribute('data-theme', color);
  };

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', themeColor);
  }, [themeColor]);

  return (
    <ThemeContext.Provider value={{ themeColor, setThemeColor }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = (): ThemeContextType => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
};
