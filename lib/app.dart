import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/addresses/addresses_screen.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/cart/cart_screen.dart';
import 'features/checkout/checkout_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/shell_screen.dart';
import 'features/location/location_controller.dart';
import 'features/location/location_screen.dart';
import 'features/loyalty/loyalty_screen.dart';
import 'features/menu/menu_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/offers_coupons/offers_screen.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/order_tracking/order_tracking_screen.dart';
import 'features/orders/order_confirm_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/product_detail/product_detail_screen.dart';
import 'features/profile/policies_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/support/support_screen.dart';
import 'features/wishlist/wishlist_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  final loc = ref.watch(locationControllerProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    redirect: (context, state) {
      if (auth.isLoading) return null;
      final user = auth.valueOrNull;
      final path = state.matchedLocation;
      final public = path == '/login' || path == '/register' || path == '/forgot';
      if (user == null) return public ? null : '/login';
      if (path == '/login' || path == '/register' || path == '/' || path == '/forgot') {
        if (loc.outlet == null) return '/location';
        return '/home';
      }
      if (loc.outlet == null && path != '/location' && path != '/addresses') {
        return '/location';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/location', builder: (_, __) => const LocationScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => ShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/menu', builder: (_, __) => const MenuScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/cart', builder: (_, __) => const CartScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: '/product/:id', builder: (_, s) => ProductDetailScreen(productId: s.pathParameters['id']!)),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/order-confirm/:id', builder: (_, s) => OrderConfirmScreen(orderId: s.pathParameters['id']!)),
      GoRoute(path: '/order/:id', builder: (_, s) => OrderTrackingScreen(orderId: s.pathParameters['id']!)),
      GoRoute(path: '/addresses', builder: (_, __) => const AddressesScreen()),
      GoRoute(path: '/wishlist', builder: (_, __) => const WishlistScreen()),
      GoRoute(path: '/loyalty', builder: (_, __) => const LoyaltyScreen()),
      GoRoute(path: '/offers', builder: (_, __) => const OffersScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),
      GoRoute(path: '/policies', builder: (_, __) => const PoliciesScreen()),
    ],
  );
});

class BriskoApp extends ConsumerWidget {
  const BriskoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
