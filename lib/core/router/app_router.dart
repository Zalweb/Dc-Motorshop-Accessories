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
import 'page_transitions.dart';
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
      GoRoute(
        path: RoutePaths.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        pageBuilder: (_, state) => AppPageTransitions.fadeThroughTransition(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.register,
        pageBuilder: (_, state) => AppPageTransitions.fadeThroughTransition(
          state: state,
          child: const LoginScreen(initialTab: AuthTab.register),
        ),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        pageBuilder: (_, state) => AppPageTransitions.fadeThroughTransition(
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.otpVerify,
        pageBuilder: (_, state) => AppPageTransitions.fadeThroughTransition(
          state: state,
          child: OtpVerifyScreen(email: (state.extra as String?) ?? ''),
        ),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        pageBuilder: (_, state) {
          final data = state.extra as Map<String, dynamic>?;
          return AppPageTransitions.fadeThroughTransition(
            state: state,
            child: ResetPasswordScreen(
              email: (data?['email'] as String?) ?? '',
              otp: (data?['otp'] as String?) ?? '',
            ),
          );
        },
      ),

      // Onboarding flow (smooth slide transitions).
      GoRoute(
        path: RoutePaths.onboardingStep1,
        pageBuilder: (_, state) => AppPageTransitions.slideTransition(
          state: state,
          child: const OnboardingSetupShopScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.onboardingStep2,
        pageBuilder: (_, state) => AppPageTransitions.slideTransition(
          state: state,
          child: const OnboardingReviewSetupScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.onboardingStep3,
        pageBuilder: (_, state) => AppPageTransitions.slideTransition(
          state: state,
          child: const OnboardingInviteStaffScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.onboardingComplete,
        pageBuilder: (_, state) => AppPageTransitions.slideTransition(
          state: state,
          child: const OnboardingCompleteScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.setupChecklist,
        pageBuilder: (_, state) => AppPageTransitions.slideTransition(
          state: state,
          child: const SetupChecklistScreen(),
        ),
      ),

      // Product sub-screens (smooth modal slide & slide transitions).
      GoRoute(
        path: RoutePaths.addProduct,
        pageBuilder: (_, state) {
          final args = state.extra as AddProductArgs?;
          return AppPageTransitions.modalSlideTransition(
            state: state,
            child: AddProductScreen(
              initialBarcode: args?.initialBarcode,
              stage: args?.stage ?? false,
              editProduct: args?.editProduct,
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.productDetail,
        pageBuilder: (_, state) => AppPageTransitions.slideTransition(
          state: state,
          child: ProductDetailScreen(productId: (state.extra as int?) ?? 0),
        ),
      ),
      GoRoute(
        path: RoutePaths.bulkAdd,
        pageBuilder: (_, state) => AppPageTransitions.modalSlideTransition(
          state: state,
          child: const BulkAddScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.categories,
        pageBuilder: (_, state) => AppPageTransitions.slideTransition(
          state: state,
          child: const CategoriesScreen(),
        ),
      ),

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
