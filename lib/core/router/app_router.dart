import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_verify_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/onboarding/onboarding_complete_screen.dart';
import '../../features/onboarding/setup_checklist_screen.dart';
import '../../features/onboarding/step1_setup_shop_screen.dart';
import '../../features/onboarding/step2_review_setup_screen.dart';
import '../../features/onboarding/step3_invite_staff_screen.dart';
import '../../features/products/add_product_screen.dart';
import '../../features/products/bulk_add_screen.dart';
import '../../features/products/categories_screen.dart';
import '../../features/products/product_detail_screen.dart';
import '../../features/products/products_screen.dart';
import '../../features/sales/new_sale_screen.dart';
import '../../features/sales/sales_history_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import 'route_paths.dart';

/// App router with the auth guard and the 5-tab bottom-nav shell.
/// Routes follow SCREENS.md → Route Map.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final onSplash = location == RoutePaths.splash;
      final onAuthRoute = location == RoutePaths.login ||
          location == RoutePaths.register ||
          location == RoutePaths.forgotPassword ||
          location == RoutePaths.otpVerify ||
          location == RoutePaths.resetPassword;
      final onOnboarding = location.startsWith('/onboarding');

      return auth.when(
        loading: () => null,
        error: (_, _) => onAuthRoute ? null : RoutePaths.login,
        data: (user) {
          if (user == null) {
            return onAuthRoute ? null : RoutePaths.login;
          }
          if (!user.newShopSetup) {
            return onOnboarding ? null : RoutePaths.onboardingStep1;
          }
          if (onSplash || onAuthRoute) return RoutePaths.dashboard;
          return null;
        },
      );
    },
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: RoutePaths.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
          path: RoutePaths.register,
          builder: (_, _) => const LoginScreen(initialTab: AuthTab.register)),
      GoRoute(
          path: RoutePaths.forgotPassword,
          builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
          path: RoutePaths.otpVerify,
          builder: (_, state) =>
              OtpVerifyScreen(email: state.extra as String)),
      GoRoute(
        path: RoutePaths.resetPassword,
        builder: (_, state) {
          final data = state.extra as Map<String, dynamic>;
          return ResetPasswordScreen(
            email: data['email'] as String,
            otp: data['otp'] as String,
          );
        },
      ),

      // Onboarding flow.
      GoRoute(
          path: RoutePaths.onboardingStep1,
          builder: (_, _) => const OnboardingSetupShopScreen()),
      GoRoute(
          path: RoutePaths.onboardingStep2,
          builder: (_, _) => const OnboardingReviewSetupScreen()),
      GoRoute(
          path: RoutePaths.onboardingStep3,
          builder: (_, _) => const OnboardingInviteStaffScreen()),
      GoRoute(
          path: RoutePaths.onboardingComplete,
          builder: (_, _) => const OnboardingCompleteScreen()),
      GoRoute(
          path: RoutePaths.setupChecklist,
          builder: (_, _) => const SetupChecklistScreen()),

      // Product sub-screens (cover the bottom nav).
      GoRoute(
          path: RoutePaths.addProduct,
          builder: (_, state) {
            final args = state.extra as AddProductArgs?;
            return AddProductScreen(
              initialBarcode: args?.initialBarcode,
              stage: args?.stage ?? false,
              editProduct: args?.editProduct,
            );
          }),
      GoRoute(
          path: RoutePaths.productDetail,
          builder: (_, state) =>
              ProductDetailScreen(productId: state.extra as int)),
      GoRoute(
          path: RoutePaths.bulkAdd, builder: (_, _) => const BulkAddScreen()),
      GoRoute(
          path: RoutePaths.categories,
          builder: (_, _) => const CategoriesScreen()),

      // Main app shell with the 5 bottom-nav tabs.
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: RoutePaths.dashboard,
                builder: (_, _) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: RoutePaths.sales,
                builder: (_, _) => const SalesHistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: RoutePaths.newSale,
                builder: (_, _) => const NewSaleScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: RoutePaths.products,
                builder: (_, _) => const ProductsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: RoutePaths.more, builder: (_, _) => const MoreScreen()),
          ]),
        ],
      ),
    ],
  );
});
