import 'package:flutter/material.dart';
import '../core/auth/auth_models.dart';
import '../core/state/app_state.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/admin_notifications_screen.dart';
import '../features/auth/admin_login_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/customer_chats_screen.dart';
import '../features/chat/customer_notifications_screen.dart';
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
  static const String adminLogin = '/admin-login';
  static const String adminDashboard = '/admin';
  static const String adminNotifications = '/admin/notifications';
  static const String chat = '/chat';
  static const String customerChats = '/chats';
  static const String customerNotifications = '/notifications';

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

  /// Auth-aware entry point for the admin area.
  ///
  /// - Already signed in as admin → goes straight to the dashboard.
  /// - Not an admin → shows the login screen; the login screen itself
  ///   does pushReplacement to the dashboard on success.
  static void goToAdminArea(BuildContext context) {
    final isAdmin = AppStateProvider.of(context).authStatus == AuthStatus.admin;

    if (isAdmin) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AdminDashboardScreen(),
          settings: const RouteSettings(name: adminDashboard),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AdminLoginScreen(),
          settings: const RouteSettings(name: adminLogin),
        ),
      );
    }
  }

  /// Navigate to admin notification / interest requests screen.
  static void goToAdminNotifications(
    BuildContext context, {
    VoidCallback? onGoToRequests,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AdminNotificationsScreen(onGoToRequests: onGoToRequests),
        settings: const RouteSettings(name: adminNotifications),
      ),
    );
  }

  /// Navigate to the chat screen.
  /// [isAdmin] controls bubble alignment and unread tracking.
  /// [senderId] should be 'admin' or the customer's anonymous UID.
  /// [senderName] is the display name used on outgoing messages.
  static void goToChat(
    BuildContext context, {
    required String chatId,
    required String peerName,
    required String productName,
    required bool isAdmin,
    String senderId = 'admin',
    String senderName = 'Admin',
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          senderId: senderId,
          senderName: senderName,
          peerName: peerName,
          productName: productName,
          isAdmin: isAdmin,
        ),
        settings: const RouteSettings(name: chat),
      ),
    );
  }

  /// Navigate to the customer's chat threads list.
  static void goToCustomerChats(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CustomerChatsScreen(),
        settings: const RouteSettings(name: customerChats),
      ),
    );
  }

  /// Navigate to the customer notifications screen (admin chat messages).
  static void goToCustomerNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CustomerNotificationsScreen(),
        settings: const RouteSettings(name: customerNotifications),
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
      case adminLogin:
        return MaterialPageRoute(builder: (_) => const AdminLoginScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
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
