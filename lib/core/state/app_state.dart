// Lightweight app-wide state manager using InheritedWidget + StatefulWidget.
// Holds cart items, favourites, orders, and auth state.
// Mirrors the same pattern already used by LocaleProvider in app_localizations.dart.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/auth_models.dart';
import '../auth/auth_service.dart';
import '../../shared/data/mock_products.dart';
import '../../shared/models/cart_item.dart';
import '../../shared/models/order.dart';
import '../../shared/models/product.dart';

// ─── AppState ──────────────────────────────────────────────────────────────────
class AppStateProvider extends StatefulWidget {
  final Widget child;
  const AppStateProvider({super.key, required this.child});

  @override
  State<AppStateProvider> createState() => AppStateProviderState();

  static AppStateProviderState of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_InheritedAppState>();
    assert(inherited != null, 'No AppStateProvider found in widget tree');
    return inherited!.state;
  }
}

class AppStateProviderState extends State<AppStateProvider> {
  // ── Auth ───────────────────────────────────────────────────────────────────
  final AuthService _authService = AuthService.instance;
  StreamSubscription<User?>? _authSub;

  AuthStatus _authStatus = AuthStatus.loading;
  CustomerIdentity? _customerIdentity;

  AuthStatus get authStatus => _authStatus;

  /// True when the signed-in Firebase user used email/password (admin).
  bool get isAdmin => _authStatus == AuthStatus.admin;

  /// True when a customer has provided their name + phone this session.
  bool get hasIdentity => _customerIdentity != null;

  CustomerIdentity? get customerIdentity => _customerIdentity;

  @override
  void initState() {
    super.initState();
    _authSub = _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      setState(() {
        _authStatus = AuthStatus.unauthenticated;
        _customerIdentity = null;
      });
      return;
    }

    if (_authService.isAdmin) {
      setState(() {
        _authStatus = AuthStatus.admin;
        _customerIdentity = null;
      });
    } else {
      // Anonymous session — try to restore a previously saved identity.
      final identity = await _authService.fetchCustomerIdentity();
      setState(() {
        _authStatus = AuthStatus.customer;
        _customerIdentity = identity;
      });
    }
  }

  /// Sign in as admin with email + password.
  /// Throws [FirebaseAuthException] on failure.
  Future<void> signInAdmin({
    required String email,
    required String password,
  }) =>
      _authService.signInAdmin(email: email, password: password);

  /// Save a customer identity (name + phone) to Firestore and update state.
  Future<void> saveCustomerIdentity({
    required String fullName,
    required String phone,
  }) async {
    final identity = await _authService.saveCustomerIdentity(
      fullName: fullName,
      phone: phone,
    );
    setState(() {
      _authStatus = AuthStatus.customer;
      _customerIdentity = identity;
    });
  }

  /// Sign out the current user (admin or anonymous customer).
  Future<void> signOut() async {
    await _authService.signOut();
    // _onAuthStateChanged will fire and update state.
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // ── Product Catalogue ──────────────────────────────────────────────────────
  // Mutable in-memory copy of the catalogue. Seeded from MockProducts at
  // startup and kept in sync across admin and customer views for the session.
  List<Product> _products = List.from(MockProducts.all);

  List<Product> get products => List.unmodifiable(_products);

  List<Product> productsByCategory(String category) {
    if (category == 'All') return List.unmodifiable(_products);
    return _products.where((p) => p.category == category).toList();
  }

  void addProduct(Product product) =>
      setState(() => _products.insert(0, product));

  void updateProduct(Product updated) {
    setState(() {
      final i = _products.indexWhere((p) => p.id == updated.id);
      if (i >= 0) _products[i] = updated;
    });
  }

  void deleteProduct(String id) =>
      setState(() => _products.removeWhere((p) => p.id == id));

  // ── Cart ───────────────────────────────────────────────────────────────────
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  int get cartCount => _cartItems.fold(0, (sum, i) => sum + i.quantity);

  double get cartTotal => _cartItems.fold(0.0, (sum, i) => sum + i.lineTotal);

  String get cartFormattedTotal {
    final formatted = cartTotal.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$formatted FCFA';
  }

  void addToCart(Product product, {int quantity = 1, String variant = ''}) {
    setState(() {
      final index = _cartItems.indexWhere((i) => i.product.id == product.id);
      if (index >= 0) {
        _cartItems[index] = _cartItems[index].copyWith(
          quantity: _cartItems[index].quantity + quantity,
        );
      } else {
        _cartItems.add(
          CartItem(product: product, quantity: quantity, variant: variant),
        );
      }
    });
  }

  void removeFromCart(String productId) {
    setState(() {
      _cartItems.removeWhere((i) => i.product.id == productId);
    });
  }

  void updateCartQuantity(String productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cartItems.removeWhere((i) => i.product.id == productId);
        return;
      }
      final index = _cartItems.indexWhere((i) => i.product.id == productId);
      if (index >= 0) {
        _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      }
    });
  }

  void clearCart() => setState(() => _cartItems.clear());

  bool isInCart(String productId) =>
      _cartItems.any((i) => i.product.id == productId);

  // ── Favourites ─────────────────────────────────────────────────────────────
  final List<Product> _favourites = [];

  List<Product> get favourites => List.unmodifiable(_favourites);

  bool isFavourite(String productId) =>
      _favourites.any((p) => p.id == productId);

  void toggleFavourite(Product product) {
    setState(() {
      final index = _favourites.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        _favourites.removeAt(index);
      } else {
        _favourites.add(product);
      }
    });
  }

  void removeFavourite(String productId) {
    setState(() => _favourites.removeWhere((p) => p.id == productId));
  }

  // ── Orders ─────────────────────────────────────────────────────────────────
  final List<AppOrder> _orders = List.from(MockOrders.all);

  List<AppOrder> get orders => List.unmodifiable(_orders);

  List<AppOrder> get pendingOrders =>
      _orders.where((o) => o.isPending || o.isProcessing).toList();

  List<AppOrder> get completedOrders =>
      _orders.where((o) => o.isCompleted).toList();

  /// Converts the current cart into a new pending order and clears the cart.
  void submitOrder() {
    if (_cartItems.isEmpty) return;
    setState(() {
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch % 100000}';
      _orders.insert(
        0,
        AppOrder(
          id: orderId,
          items: List.from(_cartItems),
          purchasedAt: DateTime.now(),
          status: OrderStatus.pending,
        ),
      );
      _cartItems.clear();
    });
  }

  /// Clears all orders, favourites, and cart — used from the Account screen.
  void clearHistory() {
    setState(() {
      _cartItems.clear();
      _favourites.clear();
      _orders.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedAppState(
      state: this,
      child: widget.child,
    );
  }
}

// ─── InheritedWidget shell ────────────────────────────────────────────────────
class _InheritedAppState extends InheritedWidget {
  final AppStateProviderState state;

  const _InheritedAppState({
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedAppState old) => true;
}

// ─── Extension shorthand ──────────────────────────────────────────────────────
extension BuildContextAppState on BuildContext {
  AppStateProviderState get appState => AppStateProvider.of(this);
}
