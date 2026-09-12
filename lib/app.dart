import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_motion.dart';
import 'core/theme/app_theme.dart';
import 'features/addresses/addresses_screen.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
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
import 'features/search/search_screen.dart';
import 'features/support/support_screen.dart';
import 'features/wishlist/wishlist_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(authStateProvider, (_, __) => refresh.ping());
  ref.listen(sessionRestoreProvider, (_, __) => refresh.ping());
  ref.listen(locationControllerProvider, (_, __) => refresh.ping());
  ref.onDispose(refresh.dispose);
  ref.read(sessionRestoreProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final restore = ref.read(sessionRestoreProvider);
      final auth = ref.read(authStateProvider);
      final loc = ref.read(locationControllerProvider);
      final path = state.matchedLocation;
      final user = FirebaseAuth.instance.currentUser ?? auth.valueOrNull;

      if ((restore.isLoading && user == null) || loc.restoring) {
        return path == '/' ? null : '/';
      }
      if (user == null) {
        return path == '/login' ? null : '/login';
      }
      if (restore.isLoading && (path == '/' || path == '/login')) {
        return '/';
      }
      if (path == '/login' || path == '/') {
        if (loc.outlet == null) return '/location';
        return '/home';
      }
      if (loc.outlet == null && path != '/location' && path != '/addresses') {
        return '/location';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const SplashScreen(), begin: Offset.zero)),
      GoRoute(path: '/login', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const LoginScreen())),
      GoRoute(path: '/location', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const LocationScreen())),
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
      GoRoute(path: '/search', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const SearchScreen())),
      GoRoute(path: '/product/:id', pageBuilder: (_, s) => modalUpPage(key: s.pageKey, child: ProductDetailScreen(productId: s.pathParameters['id']!))),
      GoRoute(path: '/checkout', pageBuilder: (_, s) => modalUpPage(key: s.pageKey, child: const CheckoutScreen())),
      GoRoute(path: '/order-confirm/:id', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: OrderConfirmScreen(orderId: s.pathParameters['id']!))),
      GoRoute(path: '/order/:id', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: OrderTrackingScreen(orderId: s.pathParameters['id']!))),
      GoRoute(path: '/addresses', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const AddressesScreen())),
      GoRoute(path: '/wishlist', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const WishlistScreen())),
      GoRoute(path: '/loyalty', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const LoyaltyScreen())),
      GoRoute(path: '/offers', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const OffersScreen())),
      GoRoute(path: '/notifications', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const NotificationsScreen())),
      GoRoute(path: '/support', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const SupportScreen())),
      GoRoute(path: '/policies', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const PoliciesScreen())),
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
