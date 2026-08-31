import React from 'react';
import { LucideIcon } from 'lucide-react';

interface MetricCardProps {
  label: string;
  value: string;
  subValue?: string;
  icon?: LucideIcon;
  colorType?: 'profit' | 'cogs' | 'expense' | 'discount' | 'margin' | 'neutral' | 'primary';
  onClick?: () => void;
  actionText?: string;
  highlight?: boolean;
}

export const MetricCard: React.FC<MetricCardProps> = ({
  label,
  value,
  subValue,
  icon: Icon,
  colorType = 'neutral',
  onClick,
  actionText,
  highlight = false,
}) => {
  const getColorClasses = () => {
    switch (colorType) {
      case 'profit':
      case 'primary':
        return {
          text: 'text-blue-400',
          bgIcon: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
          card: 'border-[#262626] hover:border-blue-500/40',
        };
      case 'cogs':
        return {
          text: 'text-emerald-400',
          bgIcon: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
          card: 'border-[#262626] hover:border-emerald-500/40',
        };
      case 'expense':
        return {
          text: 'text-amber-400',
          bgIcon: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
          card: 'border-[#262626] hover:border-amber-500/40',
        };
      case 'discount':
        return {
          text: 'text-purple-400',
          bgIcon: 'bg-purple-500/10 text-purple-400 border-purple-500/20',
          card: 'border-[#262626] hover:border-purple-500/40',
        };
      case 'margin':
        return {
          text: 'text-cyan-400',
          bgIcon: 'bg-cyan-500/10 text-cyan-400 border-cyan-500/20',
          card: 'border-[#262626] hover:border-cyan-500/40',
        };
      default:
        return {
          text: 'text-white',
          bgIcon: 'bg-gray-800 text-gray-400 border-gray-700',
          card: 'border-[#262626] hover:border-gray-600',
        };
    }
  };

  const colors = getColorClasses();

  return (
    <div
      onClick={onClick}
      className={`p-4 rounded-2xl bg-[#171717] border transition-all duration-200 ${colors.card} ${
        onClick ? 'cursor-pointer hover:bg-[#1f1f1f] active:scale-[0.99]' : ''
      } ${highlight ? 'bg-gradient-to-br from-[#1c2237] to-[#141724] border-blue-500/40 shadow-lg shadow-blue-500/5' : ''}`}
    >
      <div className="flex items-center justify-between mb-2">
        <span className="text-[11px] font-bold tracking-wider uppercase text-gray-400">
          {label}
        </span>
        {Icon && (
          <div className={`p-2 rounded-xl border ${colors.bgIcon}`}>
            <Icon className="w-4 h-4" />
          </div>
        )}
      </div>

      <div className="flex items-baseline justify-between mt-1">
        <div className={`text-xl md:text-2xl font-extrabold tracking-tight ${colors.text}`}>
          {value}
        </div>
        {actionText && (
          <span className="text-xs font-semibold text-amber-400 hover:underline">
            {actionText} →
          </span>
        )}
      </div>

      {subValue && (
        <p className="text-xs text-gray-400 mt-1 font-medium truncate">
          {subValue}
        </p>
      )}
    </div>
  );
};
