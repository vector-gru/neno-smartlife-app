import 'package:flutter/material.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/product_detail/product_detail_screen.dart';
import '../shared/models/product.dart';

/// Simple imperative router — keeps it lightweight at this stage.
/// Can be migrated to go_router once more screens are built.
class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String productDetail = '/product-detail';

  /// Called from SplashScreen after animation completes.
  /// In real app, check SharedPreferences for onboarding-seen flag.
  static void navigateFromSplash(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(onboarding);
  }

  /// Called when user completes or skips onboarding.
  static void completeOnboarding(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(home);
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

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
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
