import React, { useState } from 'react';
import { Eye, EyeOff, Lock, Mail, User, Phone, Check, ArrowRight, ShieldCheck, Zap } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useBusiness } from '../../context/BusinessContext';

export const Login: React.FC = () => {
  const { signIn, signUp, resetPassword, loginAsDemo } = useAuth();
  const { profile } = useBusiness();

  const [activeTab, setActiveTab] = useState<'login' | 'register'>('login');
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [forgotModalOpen, setForgotModalOpen] = useState<boolean>(false);
  const [forgotEmail, setForgotEmail] = useState<string>('');

  // Form states
  const [email, setEmail] = useState<string>('');
  const [password, setPassword] = useState<string>('');
  const [username, setUsername] = useState<string>('');
  const [confirmPassword, setConfirmPassword] = useState<string>('');
  const [fullName, setFullName] = useState<string>('');
  const [phone, setPhone] = useState<string>('');

  const handleLoginSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);
    setLoading(true);

    const res = await signIn(email, password);
    if (res.error) {
      setErrorMessage(res.error);
    }
    setLoading(false);
  };

  const handleRegisterSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    if (password.length < 8) {
      setErrorMessage('Password must be at least 8 characters long.');
      return;
    }
    if (password !== confirmPassword) {
      setErrorMessage('Passwords do not match.');
      return;
    }

    setLoading(true);
    const res = await signUp(email, password, username, fullName, phone);
    if (res.error) {
      setErrorMessage(res.error);
    }
    setLoading(false);
  };

  const handleForgotSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!forgotEmail) return;
    setLoading(true);
    const res = await resetPassword(forgotEmail);
    if (res.error) {
      setErrorMessage(res.error);
    } else {
      setSuccessMessage('Password reset link sent to your email.');
      setForgotModalOpen(false);
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-[#0A0A0A] flex flex-col items-center justify-center p-4 selection:bg-blue-600 selection:text-white">
      {/* Background radial glow */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-96 h-96 bg-blue-600/10 rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md bg-[#141414] border border-[#262626] rounded-3xl p-6 sm:p-8 shadow-2xl relative z-10 animate-fade-in">
        {/* App Logo & Branding */}
        <div className="flex flex-col items-center text-center mb-6">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-blue-600 to-blue-800 flex items-center justify-center shadow-xl shadow-blue-500/30 border border-blue-400/30 mb-3 overflow-hidden">
            <img src="/logo.svg" alt="DC Motorcycle Inventory" className="w-12 h-12 object-contain" onError={(e) => {
              (e.target as HTMLElement).style.display = 'none';
            }} />
          </div>
          <h1 className="text-xl sm:text-2xl font-bold tracking-tight text-white">
            {profile.business_name || 'DC Motorcycle Inventory'}
          </h1>
          <p className="text-xs text-gray-400 mt-1">Inventory made simple · MoSPAMS</p>
        </div>

        {/* Tab Switcher */}
        <div className="flex p-1 bg-[#1c1c1c] rounded-2xl border border-[#2a2a2a] mb-6">
          <button
            type="button"
            onClick={() => { setActiveTab('login'); setErrorMessage(null); }}
            className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all ${
              activeTab === 'login'
                ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            Sign In
          </button>
          <button
            type="button"
            onClick={() => { setActiveTab('register'); setErrorMessage(null); }}
            className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all ${
              activeTab === 'register'
                ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            Create Account
          </button>
        </div>

        {/* Alerts */}
        {errorMessage && (
          <div className="mb-4 p-3 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-xs font-medium flex items-center gap-2">
            <div className="w-1.5 h-1.5 rounded-full bg-red-400" />
            <span>{errorMessage}</span>
          </div>
        )}
        {successMessage && (
          <div className="mb-4 p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-medium flex items-center gap-2">
            <Check className="w-4 h-4" />
            <span>{successMessage}</span>
          </div>
        )}

        {/* Login Form */}
        {activeTab === 'login' && (
          <form onSubmit={handleLoginSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-gray-300 mb-1.5">
                Email Address or Username
              </label>
              <div className="relative">
                <Mail className="w-4 h-4 text-gray-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="email"
                  required
                  placeholder="owner@dcmotorshop.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full pl-10 pr-4 py-3 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-sm text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 transition-colors"
                />
              </div>
            </div>

            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="text-xs font-semibold text-gray-300">Password</label>
                <button
                  type="button"
                  onClick={() => setForgotModalOpen(true)}
                  className="text-xs text-blue-400 hover:underline font-medium"
                >
                  Forgot password?
                </button>
              </div>
              <div className="relative">
                <Lock className="w-4 h-4 text-gray-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  required
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full pl-10 pr-11 py-3 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-sm text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 transition-colors"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-white"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3.5 bg-blue-600 hover:bg-blue-500 active:scale-[0.99] disabled:opacity-50 text-white font-bold text-sm rounded-xl shadow-lg shadow-blue-600/30 transition-all flex items-center justify-center gap-2 mt-2"
            >
              {loading ? (
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <>
                  <span>Sign In</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>
        )}

        {/* Register Form */}
        {activeTab === 'register' && (
          <form onSubmit={handleRegisterSubmit} className="space-y-3.5">
            <div>
              <label className="block text-xs font-semibold text-gray-300 mb-1">Username *</label>
              <div className="relative">
                <User className="w-4 h-4 text-gray-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  required
                  placeholder="e.g. dcmotorshop"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-sm text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-300 mb-1">Email *</label>
              <div className="relative">
                <Mail className="w-4 h-4 text-gray-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="email"
                  required
                  placeholder="owner@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-sm text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-xs font-semibold text-gray-300 mb-1">Password *</label>
                <input
                  type={showPassword ? 'text' : 'password'}
                  required
                  placeholder="Min 8 chars"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-sm text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-300 mb-1">Confirm *</label>
                <input
                  type={showPassword ? 'text' : 'password'}
                  required
                  placeholder="Confirm password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-sm text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
                />
              </div>
            </div>

            {/* Optional Section */}
            <div className="pt-2 border-t border-[#242424]">
              <p className="text-[11px] font-bold text-gray-400 uppercase tracking-wider mb-2">
                About You · Optional
              </p>
              <div className="space-y-2">
                <input
                  type="text"
                  placeholder="Full Name (optional)"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  className="w-full px-3.5 py-2 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-xs text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
                />
                <input
                  type="tel"
                  placeholder="Phone Number (e.g. 09171234567)"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="w-full px-3.5 py-2 bg-[#1c1c1c] border border-[#2a2a2a] rounded-xl text-xs text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3.5 bg-blue-600 hover:bg-blue-500 active:scale-[0.99] disabled:opacity-50 text-white font-bold text-sm rounded-xl shadow-lg shadow-blue-600/30 transition-all flex items-center justify-center gap-2 mt-2"
            >
              {loading ? (
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <>
                  <span>Create Account</span>
                  <Check className="w-4 h-4" />
                </>
              )}
            </button>
          </form>
        )}

        {/* Demo 1-Click Access for quick test */}
        <div className="mt-6 pt-4 border-t border-[#242424] flex flex-col items-center">
          <button
            type="button"
            onClick={loginAsDemo}
            className="w-full py-2.5 px-4 rounded-xl bg-[#1c1c1c] hover:bg-[#252525] border border-[#2e2e2e] text-xs font-semibold text-blue-400 flex items-center justify-center gap-2 transition-colors"
          >
            <Zap className="w-3.5 h-3.5 text-amber-400" />
            <span>Instant Demo Access (Local Sandbox)</span>
          </button>
          <p className="text-[10px] text-gray-400 mt-2">DC Motorcycle Inventory v1.0.0 · Supabase Cloud</p>
        </div>
      </div>

      {/* Forgot Password Modal */}
      {forgotModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in">
          <div className="w-full max-w-sm bg-[#161616] border border-[#2a2a2a] rounded-2xl p-5 shadow-2xl">
            <h3 className="text-base font-bold text-white mb-1">Reset Password</h3>
            <p className="text-xs text-gray-400 mb-4">
              Enter your registered email and we will send you a password recovery link.
            </p>
            <form onSubmit={handleForgotSubmit} className="space-y-3">
              <input
                type="email"
                required
                placeholder="name@example.com"
                value={forgotEmail}
                onChange={(e) => setForgotEmail(e.target.value)}
                className="w-full px-3.5 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-sm text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
              />
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setForgotModalOpen(false)}
                  className="flex-1 py-2 text-xs font-semibold text-gray-400 hover:text-white bg-[#242424] rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="flex-1 py-2 text-xs font-bold text-white bg-blue-600 hover:bg-blue-500 rounded-xl shadow-md shadow-blue-600/30"
                >
                  Send Link
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
