// App-wide state manager using InheritedWidget + StatefulWidget.
// Holds products (Firestore stream), cart (shared_preferences),
// favourites (Firestore), orders (Firestore), and auth state.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/auth_models.dart';
import '../auth/auth_service.dart';
import '../services/category_service.dart';
import '../services/customer_data_service.dart';
import '../services/product_service.dart';
import '../../shared/models/admin_category.dart';
import '../../shared/models/cart_item.dart';
import '../../shared/models/order.dart';
import '../../shared/models/product.dart';

// ─── AppStateProvider ──────────────────────────────────────────────────────────
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
  // ── Services ───────────────────────────────────────────────────────────────
  final _authService = AuthService.instance;
  final _productService = ProductService.instance;
  final _categoryService = CategoryService.instance;
  final _customerDataService = CustomerDataService.instance;

  // ── Subscriptions ──────────────────────────────────────────────────────────
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<Product>>? _productSub;
  StreamSubscription<List<AdminCategory>>? _categorySub;
  StreamSubscription<List<AppOrder>>? _orderSub;

  // ── Auth ───────────────────────────────────────────────────────────────────
  AuthStatus _authStatus = AuthStatus.loading;
  CustomerIdentity? _customerIdentity;

  AuthStatus get authStatus => _authStatus;
  bool get isAdmin => _authStatus == AuthStatus.admin;
  bool get hasIdentity => _customerIdentity != null;
  CustomerIdentity? get customerIdentity => _customerIdentity;

  // ── Products ───────────────────────────────────────────────────────────────
  List<Product> _products = [];

  List<Product> get products => List.unmodifiable(_products);

  List<Product> productsByCategory(String category) {
    if (category == 'All') return List.unmodifiable(_products);
    return _products.where((p) => p.category == category).toList();
  }

  // Optimistic update helpers (stream confirms shortly after)
  void addProduct(Product p) => setState(() => _products.insert(0, p));
  void updateProduct(Product u) {
    setState(() {
      final i = _products.indexWhere((p) => p.id == u.id);
      if (i >= 0) _products[i] = u;
    });
  }

  void deleteProduct(String id) =>
      setState(() => _products.removeWhere((p) => p.id == id));

  // ── Categories ─────────────────────────────────────────────────────────────
  List<AdminCategory> _categories = [];
  List<AdminCategory> get categories => List.unmodifiable(_categories);

  /// Category names prefixed with 'All' — used by filter chips.
  List<String> get categoryNames => ['All', ..._categories.map((c) => c.name)];

  // ── Cart ───────────────────────────────────────────────────────────────────
  final List<CartItem> _cartItems = [];
  bool _cartLoaded = false;

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get cartCount => _cartItems.fold(0, (s, i) => s + i.quantity);
  double get cartTotal => _cartItems.fold(0.0, (s, i) => s + i.lineTotal);

  String get cartFormattedTotal {
    final f = cartTotal.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$f FCFA';
  }

  void addToCart(Product product, {int quantity = 1, String variant = ''}) {
    setState(() {
      final index = _cartItems.indexWhere((i) => i.product.id == product.id);
      if (index >= 0) {
        _cartItems[index] = _cartItems[index]
            .copyWith(quantity: _cartItems[index].quantity + quantity);
      } else {
        _cartItems.add(
            CartItem(product: product, quantity: quantity, variant: variant));
      }
    });
    _persistCart();
  }

  void removeFromCart(String productId) {
    setState(() => _cartItems.removeWhere((i) => i.product.id == productId));
    _persistCart();
  }

  void updateCartQuantity(String productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cartItems.removeWhere((i) => i.product.id == productId);
      } else {
        final index = _cartItems.indexWhere((i) => i.product.id == productId);
        if (index >= 0) {
          _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
        }
      }
    });
    _persistCart();
  }

  void clearCart() {
    setState(() => _cartItems.clear());
    _customerDataService.clearCart();
  }

  bool isInCart(String productId) =>
      _cartItems.any((i) => i.product.id == productId);

  void _persistCart() {
    _customerDataService.saveCart(List.from(_cartItems));
  }

  Future<void> _loadCart() async {
    if (_cartLoaded) return;
    final restored = await _customerDataService.loadCart(_products);
    if (!mounted) return;
    setState(() {
      _cartItems
        ..clear()
        ..addAll(restored);
      _cartLoaded = true;
    });
  }

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
    _persistFavourites();
  }

  void removeFavourite(String productId) {
    setState(() => _favourites.removeWhere((p) => p.id == productId));
    _persistFavourites();
  }

  void _persistFavourites() {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    _customerDataService.saveFavourites(
      uid,
      _favourites.map((p) => p.id).toList(),
    );
  }

  Future<void> _loadFavourites() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    final ids = await _customerDataService.loadFavouriteIds(uid);
    if (!mounted) return;
    final resolved = _products.where((p) => ids.contains(p.id)).toList();
    setState(() {
      _favourites
        ..clear()
        ..addAll(resolved);
    });
  }

  // ── Orders ─────────────────────────────────────────────────────────────────
  List<AppOrder> _orders = [];

  List<AppOrder> get orders => List.unmodifiable(_orders);
  List<AppOrder> get pendingOrders =>
      _orders.where((o) => o.isPending || o.isProcessing).toList();
  List<AppOrder> get completedOrders =>
      _orders.where((o) => o.isCompleted).toList();

  void _subscribeToOrders(String uid) {
    _orderSub?.cancel();
    _orderSub = _customerDataService.watchOrders(uid, _products).listen(
          (orders) => setState(() => _orders = orders),
          onError: (_) {},
        );
  }

  /// Converts the current cart into a new pending order, saves to Firestore,
  /// and clears the cart.
  Future<void> submitOrder() async {
    if (_cartItems.isEmpty) return;
    final uid = _authService.currentUser?.uid ?? '';
    final order = AppOrder(
      id: '',
      customerId: uid,
      customerName: _customerIdentity?.fullName ?? '',
      customerPhone: _customerIdentity?.phone ?? '',
      items: List.from(_cartItems),
      purchasedAt: DateTime.now(),
      status: OrderStatus.pending,
    );
    await _customerDataService.createOrder(order);
    clearCart();
    // _orderSub stream will update _orders automatically
  }

  /// Clears all local state — called from the Account screen.
  void clearHistory() {
    setState(() {
      _cartItems.clear();
      _favourites.clear();
      _orders.clear();
      _cartLoaded = false;
    });
    _customerDataService.clearCart();
    _orderSub?.cancel();
    _orderSub = null;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _authSub = _authService.authStateChanges.listen(_onAuthStateChanged);
    _subscribeToProducts();
    _subscribeToCategories();
  }

  void _subscribeToCategories() {
    _categorySub?.cancel();
    _categorySub = _categoryService.watchCategories().listen(
          (cats) => setState(() => _categories = cats),
          onError: (_) {},
        );
  }

  void _subscribeToProducts() {
    _productSub?.cancel();
    _productSub = _productService.watchProducts().listen(
      (products) {
        setState(() => _products = products);
        // Once products are loaded, restore cart and favourites
        _loadCart();
        _loadFavourites();
      },
      onError: (_) {},
    );
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      setState(() {
        _authStatus = AuthStatus.unauthenticated;
        _customerIdentity = null;
        _orders = [];
        _favourites.clear();
        _cartItems.clear();
        _cartLoaded = false;
      });
      _orderSub?.cancel();
      _orderSub = null;
      await _customerDataService.clearCart();
      return;
    }

    if (_authService.isAdmin) {
      setState(() {
        _authStatus = AuthStatus.admin;
        _customerIdentity = null;
      });
    } else {
      final identity = await _authService.fetchCustomerIdentity();
      if (!mounted) return;
      setState(() {
        _authStatus = AuthStatus.customer;
        _customerIdentity = identity;
      });
      // Restore per-customer data
      _subscribeToOrders(user.uid);
      await _loadFavourites();
      await _loadCart();
    }
  }

  Future<void> signInAdmin({required String email, required String password}) =>
      _authService.signInAdmin(email: email, password: password);

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
    // Start order subscription now that we have identity
    final uid = _authService.currentUser?.uid;
    if (uid != null) _subscribeToOrders(uid);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _productSub?.cancel();
    _categorySub?.cancel();
    _orderSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedAppState(state: this, child: widget.child);
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
