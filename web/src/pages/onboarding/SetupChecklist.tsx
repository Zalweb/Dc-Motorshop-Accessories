import React from 'react';
import { 
  CheckCircle2, 
  Circle, 
  Sparkles, 
  ArrowRight, 
  Image, 
  MapPin, 
  PackagePlus, 
  GitFork, 
  Wallet, 
  Clock, 
  BellRing, 
  Calendar 
} from 'lucide-react';
import { useBusiness } from '../../context/BusinessContext';

interface SetupChecklistProps {
  onNavigate: (tab: string) => void;
}

export const SetupChecklist: React.FC<SetupChecklistProps> = ({ onNavigate }) => {
  const { isChecklistDone, toggleChecklistItem, completedChecklistCount, profile } = useBusiness();

  const essentials = [
    {
      id: 'add_logo',
      label: 'Add your business logo',
      icon: Image,
      actionText: 'Update logo',
      tab: 'settings',
    },
    {
      id: 'add_address',
      label: 'Add address and phone number',
      icon: MapPin,
      actionText: 'Edit details',
      tab: 'settings',
    },
    {
      id: 'add_product',
      label: 'Add your first product',
      icon: PackagePlus,
      actionText: 'Add product',
      tab: 'products',
    },
    {
      id: 'order_workflow',
      label: 'Set up your order workflow',
      icon: GitFork,
      actionText: 'Review settings',
      tab: 'settings',
    },
  ];

  const fineTune = [
    {
      id: 'first_expense',
      label: 'Record your first expense',
      icon: Wallet,
      actionText: 'Add expense',
      tab: 'expenses',
    },
    {
      id: 'expense_window',
      label: 'Check expense averaging window',
      icon: Clock,
      actionText: 'Review settings',
      tab: 'settings',
    },
    {
      id: 'low_stock_alerts',
      label: 'Set up low-stock alerts',
      icon: BellRing,
      actionText: 'Review alerts',
      tab: 'settings',
    },
    {
      id: 'closed_days',
      label: 'Tell us your closed days',
      icon: Calendar,
      actionText: 'Open calendar',
      tab: 'calendar',
    },
  ];

  const totalCount = essentials.length + fineTune.length;
  const progressPercent = Math.round((completedChecklistCount / totalCount) * 100);

  return (
    <div className="max-w-3xl mx-auto space-y-6 pb-12 animate-fade-in">
      {/* Header Banner */}
      <div className="p-6 rounded-3xl bg-gradient-to-br from-[#161d33] to-[#12141c] border border-blue-500/20 shadow-xl relative overflow-hidden">
        <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-blue-500/10 border border-blue-500/30 text-blue-400 text-xs font-bold w-fit mb-3">
          <Sparkles className="w-3.5 h-3.5" />
          <span>Setup checklist</span>
        </div>

        <h1 className="text-xl sm:text-2xl font-black text-white tracking-tight">
          Finish setting up <span className="text-blue-400">{profile.business_name}</span>
        </h1>
        <p className="text-xs text-gray-300 mt-1 max-w-md">
          A few small steps so everything's ready for your first sale and complete financial tracking.
        </p>

        {/* Progress bar */}
        <div className="mt-5 space-y-2">
          <div className="flex justify-between text-xs font-bold text-gray-300">
            <span>{completedChecklistCount} of {totalCount} done</span>
            <span className="text-blue-400">{progressPercent}%</span>
          </div>
          <div className="w-full h-2.5 bg-[#1f2438] rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-blue-600 to-blue-400 transition-all duration-500 rounded-full"
              style={{ width: `${progressPercent}%` }}
            />
          </div>
        </div>
      </div>

      {/* ESSENTIALS SECTION */}
      <div className="space-y-3">
        <div className="flex items-center justify-between px-2">
          <h2 className="text-xs font-black uppercase tracking-wider text-gray-400">
            Essentials
          </h2>
          <span className="text-[11px] text-gray-400">Core setup</span>
        </div>

        <div className="space-y-2">
          {essentials.map((item) => {
            const isDone = isChecklistDone(item.id);
            const Icon = item.icon;
            return (
              <div
                key={item.id}
                className={`flex items-center justify-between p-4 rounded-2xl border transition-all ${
                  isDone
                    ? 'bg-[#141414] border-[#222222] opacity-80'
                    : 'bg-[#171717] border-[#2c2c2c] hover:border-blue-500/40 shadow-sm'
                }`}
              >
                <div className="flex items-center gap-3.5">
                  <button
                    onClick={() => toggleChecklistItem(item.id)}
                    className="text-gray-400 hover:text-blue-400 transition-colors"
                  >
                    {isDone ? (
                      <CheckCircle2 className="w-5 h-5 text-blue-500 fill-blue-500/20" />
                    ) : (
                      <Circle className="w-5 h-5 text-gray-500" />
                    )}
                  </button>
                  <div className="flex items-center gap-2.5">
                    <div className="p-2 rounded-xl bg-[#222222] text-gray-300">
                      <Icon className="w-4 h-4" />
                    </div>
                    <span className={`text-sm font-semibold ${isDone ? 'line-through text-gray-400' : 'text-white'}`}>
                      {item.label}
                    </span>
                  </div>
                </div>

                <button
                  onClick={() => onNavigate(item.tab)}
                  className="text-xs font-bold text-blue-400 hover:text-blue-300 flex items-center gap-1 transition-colors"
                >
                  <span>{item.actionText}</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            );
          })}
        </div>
      </div>

      {/* FINE-TUNE SECTION */}
      <div className="space-y-3 pt-2">
        <div className="flex items-center justify-between px-2">
          <h2 className="text-xs font-black uppercase tracking-wider text-gray-400">
            Fine-Tune
          </h2>
          <span className="text-[11px] text-gray-400">Advanced settings</span>
        </div>

        <div className="space-y-2">
          {fineTune.map((item) => {
            const isDone = isChecklistDone(item.id);
            const Icon = item.icon;
            return (
              <div
                key={item.id}
                className={`flex items-center justify-between p-4 rounded-2xl border transition-all ${
                  isDone
                    ? 'bg-[#141414] border-[#222222] opacity-80'
                    : 'bg-[#171717] border-[#2c2c2c] hover:border-amber-500/40 shadow-sm'
                }`}
              >
                <div className="flex items-center gap-3.5">
                  <button
                    onClick={() => toggleChecklistItem(item.id)}
                    className="text-gray-400 hover:text-blue-400 transition-colors"
                  >
                    {isDone ? (
                      <CheckCircle2 className="w-5 h-5 text-blue-500 fill-blue-500/20" />
                    ) : (
                      <Circle className="w-5 h-5 text-gray-500" />
                    )}
                  </button>
                  <div className="flex items-center gap-2.5">
                    <div className="p-2 rounded-xl bg-[#222222] text-gray-300">
                      <Icon className="w-4 h-4" />
                    </div>
                    <span className={`text-sm font-semibold ${isDone ? 'line-through text-gray-400' : 'text-white'}`}>
                      {item.label}
                    </span>
                  </div>
                </div>

                <button
                  onClick={() => onNavigate(item.tab)}
                  className="text-xs font-bold text-amber-400 hover:text-amber-300 flex items-center gap-1 transition-colors"
                >
                  <span>{item.actionText}</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
