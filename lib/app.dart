import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_motion.dart';
import 'core/theme/app_theme.dart';
import 'features/addresses/addresses_screen.dart';
import 'features/addresses/detect_address_screen.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/cart/cart_screen.dart';
import 'features/checkout/checkout_screen.dart';
import 'features/checkout/payment_screen.dart';
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
  ref.listen(locationControllerProvider, (prev, next) {
    if (prev?.restoring != next.restoring || prev?.outlet?.id != next.outlet?.id) {
      refresh.ping();
    }
  });
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
      // Routes that a signed-out user must be able to reach (mobile OTP flow).
      const publicPaths = {'/login', '/otp'};

      if ((restore.isLoading && user == null) || loc.restoring) {
        return path == '/' ? null : '/';
      }
      if (user == null) {
        return publicPaths.contains(path) ? null : '/login';
      }
      if (restore.isLoading && (path == '/' || path == '/login')) {
        return '/';
      }
      if (path == '/login') return '/location';
      if (path == '/otp') return null;
      if (path == '/') {
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
      GoRoute(
        path: '/otp',
        pageBuilder: (_, s) => fadeSlidePage(
          key: s.pageKey,
          child: OtpScreen(mobile: s.uri.queryParameters['mobile'] ?? ''),
        ),
      ),
      GoRoute(path: '/location', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const LocationScreen())),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => ShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/menu', builder: (_, __) => const MenuScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: '/cart', pageBuilder: (_, s) => modalUpPage(key: s.pageKey, child: const _OverlayBack(child: CartScreen()))),
      GoRoute(path: '/search', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const _OverlayBack(child: SearchScreen()))),
      GoRoute(path: '/product/:id', pageBuilder: (_, s) => modalUpPage(key: s.pageKey, child: _OverlayBack(child: ProductDetailScreen(productId: s.pathParameters['id']!)))),
      GoRoute(path: '/checkout', pageBuilder: (_, s) => modalUpPage(key: s.pageKey, child: const _OverlayBack(child: CheckoutScreen()))),
      GoRoute(
        path: '/payment',
        pageBuilder: (_, s) {
          final args = s.extra;
          if (args is! OnlinePaymentArgs) {
            return modalUpPage(key: s.pageKey, child: const _OverlayBack(child: CheckoutScreen()));
          }
          return modalUpPage(key: s.pageKey, child: _OverlayBack(child: PaymentScreen(args: args)));
        },
      ),
      GoRoute(path: '/order-confirm/:id', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: _OverlayBack(child: OrderConfirmScreen(orderId: s.pathParameters['id']!)))),
      GoRoute(path: '/order/:id', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: _OverlayBack(child: OrderTrackingScreen(orderId: s.pathParameters['id']!)))),
      GoRoute(path: '/addresses', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const _OverlayBack(child: AddressesScreen()))),
      GoRoute(path: '/detect-address', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const _OverlayBack(child: DetectAddressScreen()))),
      GoRoute(path: '/wishlist', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const _OverlayBack(child: WishlistScreen()))),
      GoRoute(path: '/loyalty', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const _OverlayBack(child: LoyaltyScreen()))),
      GoRoute(path: '/offers', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const _OverlayBack(child: OffersScreen()))),
      GoRoute(path: '/notifications', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const _OverlayBack(child: NotificationsScreen()))),
      GoRoute(path: '/support', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const _OverlayBack(child: SupportScreen()))),
      GoRoute(path: '/policies', pageBuilder: (_, s) => fadeSlidePage(key: s.pageKey, child: const _OverlayBack(child: PoliciesScreen()))),
    ],
  );
});

class _OverlayBack extends StatelessWidget {
  final Widget child;
  const _OverlayBack({required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _rootKey.currentState;
        if (nav != null) {
          var poppedOverlay = false;
          nav.popUntil((route) {
            if (poppedOverlay) return true;
            if (route is PopupRoute) {
              poppedOverlay = true;
              return false;
            }
            return true;
          });
          if (poppedOverlay) return;
        }
        context.go('/home');
      },
      child: child,
    );
  }
}

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