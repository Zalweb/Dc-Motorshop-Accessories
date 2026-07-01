/// Centralized UI strings. No hardcoded text in widgets (CLAUDE.md don'ts).
abstract final class AppStrings {
  static const appName = 'DC Motorcycle Inventory';
  static const businessName = 'DC Motorshop & Accessories';
  static const tagline = 'Inventory made simple';

  // Auth
  static const username = 'Username';
  static const password = 'Password';
  static const email = 'Email';
  static const confirmPassword = 'Confirm password';
  static const fullName = 'Full name';
  static const phoneNumber = 'Phone number';
  static const signIn = 'Sign in';
  static const createAccount = 'Create account';
  static const forgotPassword = 'Forgot password?';
  static const noAccountPrompt = "Don't have an account? ";
  static const createOne = 'Create one';
  static const haveAccountPrompt = 'Already have an account? ';

  // Splash
  static const preparingDashboard = 'Welcome back! Preparing your dashboard...';

  // Nav
  static const dashboard = 'Dashboard';
  static const sales = 'Sales';
  static const newSale = 'New Sale';
  static const products = 'Products';
  static const more = 'More';

  // Empty states
  static const noProductsTitle = 'No products found';
  static const noProductsBody = 'Add products to get started.';
  static const noSalesTitle = 'No sales today';
  static const noSalesBody = 'New sales today will show up here.';
}
