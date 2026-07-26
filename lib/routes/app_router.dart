import 'package:flutter/material.dart';
import '../features/cart/cart_screen.dart';
import '../features/favorites/favourites_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/product_detail/product_detail_screen.dart';
import '../shared/models/product.dart';

/// Simple imperative router — keeps it lightweight at this stage.
/// Can be migrated to go_router once more screens are built.
class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String productDetail = '/product-detail';
  static const String cart = '/cart';
  static const String favourites = '/favourites';
  static const String orders = '/orders';

  // ── Navigation helpers ─────────────────────────────────────────────────────

  /// Called from SplashScreen after animation completes.
  static void navigateFromSplash(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(onboarding);
  }

  /// Called when user completes or skips onboarding.
  static void completeOnboarding(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(home);
  }

  /// Pop back to home (used from deep screens that want to return to tab 0).
  static void goToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Navigate to product detail.
  static void goToProduct(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
        settings: RouteSettings(name: productDetail, arguments: product),
      ),
    );
  }

  /// Navigate to cart.
  static void goToCart(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CartScreen(),
        settings: const RouteSettings(name: cart),
      ),
    );
  }

  /// Navigate to favourites.
  static void goToFavourites(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FavouritesScreen(),
        settings: const RouteSettings(name: favourites),
      ),
    );
  }

  /// Navigate to orders & purchase history.
  static void goToOrders(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const OrdersScreen(),
        settings: const RouteSettings(name: orders),
      ),
    );
  }

  // ── Named route generator ──────────────────────────────────────────────────
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case favourites:
        return MaterialPageRoute(builder: (_) => const FavouritesScreen());
      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
    }
  }
}
