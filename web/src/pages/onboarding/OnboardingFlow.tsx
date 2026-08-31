import React, { useState } from 'react';
import confetti from 'canvas-confetti';
import { 
  Check, 
  ChevronRight, 
  Upload, 
  Plus, 
  Trash2, 
  Layers, 
  Users, 
  Sparkles, 
  ArrowRight,
  Store,
  CheckCircle2
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useBusiness } from '../../context/BusinessContext';
import { useInventory } from '../../context/InventoryContext';
import { useTheme, THEME_SWATCHES } from '../../core/theme/ThemeContext';
import { ThemeColor } from '../../core/types';

interface OnboardingFlowProps {
  onFinish: () => void;
}

export const OnboardingFlow: React.FC<OnboardingFlowProps> = ({ onFinish }) => {
  const { user, updateUserMetadata } = useAuth();
  const { profile, updateProfile, uploadLogo } = useBusiness();
  const { categories, addCategory, deleteCategory } = useInventory();
  const { themeColor, setThemeColor } = useTheme();

  const [step, setStep] = useState<number>(1);
  const [shopName, setShopName] = useState<string>(profile.business_name || 'DC Motorshop & Accessories');
  const [newCatName, setNewCatName] = useState<string>('');
  const [isService, setIsService] = useState<boolean>(false);
  const [inviteEmail, setInviteEmail] = useState<string>('');
  const [staffList, setStaffList] = useState<string[]>([]);
  const [uploadingLogo, setUploadingLogo] = useState<boolean>(false);

  const handleLogoChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setUploadingLogo(true);
      await uploadLogo(e.target.files[0]);
      setUploadingLogo(false);
    }
  };

  const handleAddCategory = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newCatName.trim()) return;
    await addCategory(newCatName.trim(), isService);
    setNewCatName('');
    setIsService(false);
  };

  const handleAddStaff = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inviteEmail.trim()) return;
    setStaffList([...staffList, inviteEmail.trim()]);
    setInviteEmail('');
  };

  const handleComplete = async () => {
    await updateProfile({
      business_name: shopName,
      theme_color: themeColor,
      onboarding_complete: true,
    });
    await updateUserMetadata({
      onboardingComplete: true,
      newShopSetup: true,
    });

    confetti({
      particleCount: 100,
      spread: 70,
      origin: { y: 0.6 },
    });

    onFinish();
  };

  return (
    <div className="min-h-screen bg-[#0A0A0A] flex flex-col items-center justify-center p-4 selection:bg-blue-600 selection:text-white">
      <div className="w-full max-w-lg bg-[#141414] border border-[#262626] rounded-3xl p-6 sm:p-8 shadow-2xl animate-fade-in relative z-10">
        {/* Step Progress Bar (3 Segments) */}
        {step <= 3 && (
          <div className="mb-6">
            <div className="flex items-center justify-between text-xs font-semibold text-gray-400 mb-2">
              <span>Step {step} of 3</span>
              <span>
                {step === 1 && 'Shop & Theme'}
                {step === 2 && 'Review Categories'}
                {step === 3 && 'Invite Team'}
              </span>
            </div>
            <div className="grid grid-cols-3 gap-2">
              {[1, 2, 3].map((s) => (
                <div
                  key={s}
                  className={`h-1.5 rounded-full transition-all duration-300 ${
                    s <= step ? 'bg-blue-600' : 'bg-[#242424]'
                  }`}
                />
              ))}
            </div>
          </div>
        )}

        {/* STEP 1: Set up shop & Theme Picker */}
        {step === 1 && (
          <div className="space-y-6">
            <div>
              <h2 className="text-xl font-bold text-white tracking-tight">Set up your shop</h2>
              <p className="text-xs text-gray-400 mt-1">
                Customize your store name, logo, and brand theme color.
              </p>
            </div>

            {/* Shop Name */}
            <div>
              <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-2">
                Business Name
              </label>
              <input
                type="text"
                value={shopName}
                onChange={(e) => setShopName(e.target.value)}
                className="w-full px-4 py-3 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-sm text-white focus:outline-none focus:border-blue-500"
              />
            </div>

            {/* Logo Upload */}
            <div>
              <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-2">
                Shop Logo · Optional
              </label>
              <div className="flex items-center gap-4">
                <div className="w-16 h-16 rounded-2xl bg-[#1c1c1c] border border-[#2a2a2a] flex items-center justify-center overflow-hidden relative group">
                  {profile.logo_url && profile.logo_url !== '/logo.svg' ? (
                    <img src={profile.logo_url} alt="Logo" className="w-full h-full object-cover" />
                  ) : (
                    <Store className="w-6 h-6 text-gray-400" />
                  )}
                  {uploadingLogo && (
                    <div className="absolute inset-0 bg-black/60 flex items-center justify-center">
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    </div>
                  )}
                </div>
                <label className="cursor-pointer px-4 py-2.5 rounded-xl bg-[#1c1c1c] hover:bg-[#252525] border border-[#2e2e2e] text-xs font-semibold text-gray-300 hover:text-white flex items-center gap-2 transition-colors">
                  <Upload className="w-4 h-4 text-blue-400" />
                  <span>Choose Photo</span>
                  <input type="file" accept="image/*" onChange={handleLogoChange} className="hidden" />
                </label>
              </div>
            </div>

            {/* Theme Swatch Grid (3x3+1) */}
            <div>
              <label className="block text-xs font-semibold text-gray-300 uppercase tracking-wider mb-2">
                Brand Accent Color
              </label>
              <div className="grid grid-cols-5 gap-2.5">
                {THEME_SWATCHES.map((swatch) => {
                  const isSelected = themeColor === swatch.name;
                  return (
                    <button
                      key={swatch.name}
                      type="button"
                      onClick={() => setThemeColor(swatch.name)}
                      className={`h-11 rounded-xl flex items-center justify-center relative transition-all border ${
                        isSelected ? 'border-white scale-105 shadow-md shadow-black' : 'border-transparent hover:scale-102'
                      }`}
                      style={{ backgroundColor: swatch.hex }}
                    >
                      {isSelected && <Check className="w-4 h-4 text-white drop-shadow" />}
                    </button>
                  );
                })}
              </div>
              <p className="text-[11px] text-gray-400 mt-2 text-center">
                Selected Theme: <b className="text-white">{themeColor}</b>
              </p>
            </div>

            {/* Action Buttons */}
            <button
              onClick={() => setStep(2)}
              className="w-full py-3.5 bg-blue-600 hover:bg-blue-500 text-white font-bold text-sm rounded-xl shadow-lg shadow-blue-600/30 flex items-center justify-center gap-2 transition-all mt-4"
            >
              <span>Continue</span>
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* STEP 2: Review Categories */}
        {step === 2 && (
          <div className="space-y-5">
            <div>
              <h2 className="text-xl font-bold text-white tracking-tight">Review Categories</h2>
              <p className="text-xs text-gray-400 mt-1">
                MoSPAMS default motorcycle shop categories are preloaded. You can add or remove categories.
              </p>
            </div>

            {/* Add Category Form */}
            <form onSubmit={handleAddCategory} className="space-y-2">
              <div className="flex gap-2">
                <input
                  type="text"
                  placeholder="Add custom category..."
                  value={newCatName}
                  onChange={(e) => setNewCatName(e.target.value)}
                  className="flex-1 px-3.5 py-2.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-xs text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
                />
                <button
                  type="submit"
                  disabled={!newCatName.trim()}
                  className="px-4 py-2.5 bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white text-xs font-semibold rounded-xl flex items-center gap-1 transition-colors"
                >
                  <Plus className="w-4 h-4" />
                  <span>Add</span>
                </button>
              </div>
              <label className="flex items-center gap-2 text-[11px] text-gray-400 cursor-pointer">
                <input
                  type="checkbox"
                  checked={isService}
                  onChange={(e) => setIsService(e.target.checked)}
                  className="rounded bg-[#1c1c1c] border-gray-700 text-blue-600 focus:ring-0"
                />
                <span>This is a labor / service category (doesn't track stock quantity)</span>
              </label>
            </form>

            {/* Category List */}
            <div className="max-h-56 overflow-y-auto space-y-1.5 pr-1">
              {categories.map((cat) => (
                <div
                  key={cat.id}
                  className="flex items-center justify-between px-3.5 py-2.5 bg-[#1c1c1c] border border-[#262626] rounded-xl text-xs"
                >
                  <div className="flex items-center gap-2">
                    <span className="font-semibold text-white">{cat.name}</span>
                    {cat.is_service && (
                      <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-purple-500/20 text-purple-300 border border-purple-500/30">
                        Service
                      </span>
                    )}
                  </div>
                  <button
                    onClick={() => deleteCategory(cat.id)}
                    className="text-gray-500 hover:text-red-400 p-1 transition-colors"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              ))}
            </div>

            {/* Footer Buttons */}
            <div className="flex gap-2 pt-2">
              <button
                onClick={() => setStep(1)}
                className="px-4 py-3 bg-[#242424] hover:bg-[#2c2c2c] text-gray-300 font-semibold text-xs rounded-xl"
              >
                Back
              </button>
              <button
                onClick={() => setStep(3)}
                className="flex-1 py-3 bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs rounded-xl shadow-lg shadow-blue-600/30 flex items-center justify-center gap-1.5"
              >
                <span>Looks Good</span>
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* STEP 3: Invite Team (Optional) */}
        {step === 3 && (
          <div className="space-y-5">
            <div>
              <h2 className="text-xl font-bold text-white tracking-tight">Invite Staff & Mechanics</h2>
              <p className="text-xs text-gray-400 mt-1">
                Collaborate with your shop staff. You can also do this anytime in Settings.
              </p>
            </div>

            <form onSubmit={handleAddStaff} className="flex gap-2">
              <input
                type="email"
                placeholder="staff@example.com"
                value={inviteEmail}
                onChange={(e) => setInviteEmail(e.target.value)}
                className="flex-1 px-3.5 py-2.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-xs text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
              />
              <button
                type="submit"
                disabled={!inviteEmail.trim()}
                className="px-4 py-2.5 bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white text-xs font-semibold rounded-xl flex items-center gap-1"
              >
                <Plus className="w-4 h-4" />
                <span>Invite</span>
              </button>
            </form>

            {staffList.length > 0 ? (
              <div className="space-y-2">
                {staffList.map((st, i) => (
                  <div key={i} className="flex items-center justify-between p-2.5 bg-[#1c1c1c] rounded-xl text-xs text-gray-300">
                    <span>{st}</span>
                    <span className="text-[10px] text-amber-400 bg-amber-400/10 px-2 py-0.5 rounded">Invited</span>
                  </div>
                ))}
              </div>
            ) : (
              <div className="p-6 text-center border border-dashed border-[#2a2a2a] rounded-2xl">
                <Users className="w-8 h-8 text-gray-500 mx-auto mb-2" />
                <p className="text-xs text-gray-400">No staff invited yet. You can skip this step.</p>
              </div>
            )}

            {/* Footer */}
            <div className="flex gap-2 pt-2">
              <button
                onClick={() => setStep(2)}
                className="px-4 py-3 bg-[#242424] hover:bg-[#2c2c2c] text-gray-300 font-semibold text-xs rounded-xl"
              >
                Back
              </button>
              <button
                onClick={() => setStep(4)}
                className="flex-1 py-3 bg-blue-600 hover:bg-blue-500 text-white font-bold text-xs rounded-xl shadow-lg shadow-blue-600/30 flex items-center justify-center gap-1.5"
              >
                <span>Finish Setup</span>
                <Check className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}

        {/* STEP 4: Complete Celebration Screen */}
        {step === 4 && (
          <div className="text-center py-4 space-y-6 animate-fade-in">
            <div className="w-20 h-20 rounded-full bg-gradient-to-tr from-blue-600 to-emerald-500 flex items-center justify-center mx-auto shadow-2xl shadow-blue-600/40 border-4 border-[#141414]">
              <Sparkles className="w-10 h-10 text-white" />
            </div>

            <div>
              <h2 className="text-2xl font-black text-white tracking-tight">You're All Set!</h2>
              <p className="text-sm text-gray-300 mt-2 max-w-xs mx-auto">
                <b className="text-white">{shopName}</b> is ready for your first sale.
              </p>
            </div>

            <div className="p-4 bg-[#1c1c1c] border border-[#2a2a2a] rounded-2xl text-left space-y-2">
              <div className="flex items-center gap-2 text-xs text-emerald-400 font-semibold">
                <CheckCircle2 className="w-4 h-4" />
                <span>Shop profile initialized</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-emerald-400 font-semibold">
                <CheckCircle2 className="w-4 h-4" />
                <span>Motorcycle catalog categories ready</span>
              </div>
              <div className="flex items-center gap-2 text-xs text-emerald-400 font-semibold">
                <CheckCircle2 className="w-4 h-4" />
                <span>Theme customized ({themeColor})</span>
              </div>
            </div>

            <button
              onClick={handleComplete}
              className="w-full py-4 bg-blue-600 hover:bg-blue-500 text-white font-black text-sm rounded-2xl shadow-xl shadow-blue-600/40 flex items-center justify-center gap-2 transition-all active:scale-[0.99]"
            >
              <span>Go to Dashboard</span>
              <ArrowRight className="w-4 h-4" />
            </button>
            <p className="text-[11px] text-gray-400">You can update settings anytime from the More menu.</p>
          </div>
        )}
      </div>
    </div>
  );
};
