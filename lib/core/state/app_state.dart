// App-wide state manager using InheritedWidget + StatefulWidget.
// Holds products (Firestore stream), cart (shared_preferences),
// favourites (Firestore), orders (Firestore), and auth state.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/auth_models.dart';
import '../auth/auth_service.dart';
import '../services/category_service.dart';
import '../services/chat_service.dart';
import '../services/customer_data_service.dart';
import '../services/interest_request_service.dart';
import '../services/notification_service.dart';
import '../services/order_notification_service.dart';
import '../services/product_service.dart';
import '../services/purchase_request_service.dart';
import '../../shared/models/admin_category.dart';
import '../../shared/models/admin_request.dart';
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
  final _notificationService = NotificationService.instance;
  final _interestService = InterestRequestService.instance;
  final _purchaseRequestService = PurchaseRequestService.instance;
  final _orderNotificationService = OrderNotificationService.instance;

  // ── Subscriptions ──────────────────────────────────────────────────────────
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<Product>>? _productSub;
  StreamSubscription<List<AdminCategory>>? _categorySub;
  StreamSubscription<List<AppOrder>>? _orderSub;
  StreamSubscription<List<InterestRequest>>? _interestSub;
  StreamSubscription<List<OrderNotification>>? _orderNotifSub;
  StreamSubscription<List<AdminRequest>>? _purchaseRequestSub;
  StreamSubscription? _chatSub;

  // ── Session bridging ───────────────────────────────────────────────────────
  // When admin logs in we snapshot the anonymous customer UID that was active
  // so we can restore the customer session cleanly after admin logs out.
  String? _preAdminAnonymousUid;
  // Tracks the last UID that was active as a customer session.
  String? _lastCustomerUid;

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
      (orders) {
        // ignore: avoid_print
        print(
            '[AppState] watchOrders(uid) emitted ${orders.length} orders: ${orders.map((o) => '${o.id}:${o.status.name}').join(', ')}');
        setState(() => _orders = orders);
      },
      // ignore: avoid_print
      onError: (e) => print('[AppState] watchOrders error: $e'),
    );
  }

  void _subscribeToOrdersByPhone(String phone) {
    _orderSub?.cancel();
    _orderSub =
        _customerDataService.watchOrdersByPhone(phone, _products).listen(
      (orders) {
        // ignore: avoid_print
        print(
            '[AppState] watchOrdersByPhone emitted ${orders.length} orders: ${orders.map((o) => '${o.id}:${o.status.name}').join(', ')}');
        setState(() => _orders = orders);
      },
      // ignore: avoid_print
      onError: (e) => print('[AppState] watchOrdersByPhone error: $e'),
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
    final saved = await _customerDataService.createOrder(order);
    // Also write a purchase_requests document so the admin sees it on the
    // Requests screen immediately. Pass the order ID so status changes
    // made by the admin are reflected back on the customer's orders screen.
    await _purchaseRequestService.submitRequest(
      customerId: uid,
      customerName: _customerIdentity?.fullName ?? '',
      customerPhone: _customerIdentity?.phone ?? '',
      items: List.from(_cartItems),
      orderId: saved.id,
    );
    clearCart();
    // _orderSub stream will update _orders automatically
  }

  /// Clears the customer's activity history from Firestore and local storage,
  /// but keeps their account (name, phone) intact.
  ///
  /// Deletes from Firestore (matched by phone + uid so nothing is missed):
  ///   • orders
  ///   • purchase_requests
  ///   • interest_requests
  ///   • chat threads and all their messages
  ///
  /// Also clears local cart (SharedPreferences) and wipes the Firestore
  /// favourites array so nothing re-appears on the next launch.
  Future<void> clearHistory() async {
    final uid = _authService.currentUser?.uid;
    final phone = _customerIdentity?.phone ?? '';

    // 1. Stop the order stream before deleting so it doesn't try to reconcile
    //    docs that no longer exist.
    _orderSub?.cancel();
    _orderSub = null;
    _chatSub?.cancel();
    _chatSub = null;
    _orderNotifSub?.cancel();
    _orderNotifSub = null;

    // 2. Wipe local state immediately so the UI reflects the change at once.
    setState(() {
      _cartItems.clear();
      _favourites.clear();
      _orders.clear();
      _cartLoaded = false;
    });

    // 3. Clear local cart from SharedPreferences.
    await _customerDataService.clearCart();

    // 4. Clear Firestore favourites so they don't restore on next launch.
    if (uid != null) {
      await _customerDataService.saveFavourites(uid, []);
    }

    // 5. Delete all Firestore records linked to this customer.
    //    We run phone-based and uid-based deletes in parallel so records
    //    written under either key are fully removed.
    final futures = <Future<void>>[];

    if (phone.isNotEmpty) {
      futures.addAll([
        _customerDataService.deleteOrdersByPhone(phone),
        _purchaseRequestService.deleteRequestsByPhone(phone),
        _interestService.deleteRequestsByPhone(phone),
        ChatService.instance.deleteThreadsByPhone(phone),
        _orderNotificationService.deleteByPhone(phone),
      ]);
    }
    if (uid != null) {
      futures.addAll([
        _customerDataService.deleteOrdersByUid(uid),
        _purchaseRequestService.deleteRequestsByUid(uid),
        _interestService.deleteRequestsByUid(uid),
        ChatService.instance.deleteThreadsByUid(uid),
        _orderNotificationService.deleteByUid(uid),
      ]);
    }
    await Future.wait(futures);

    // 6. Re-subscribe to the order stream (will be empty now, but keeps
    //    the UI reactive for any new orders the customer places).
    if (uid != null) {
      if (phone.isNotEmpty) {
        _subscribeToOrdersByPhone(phone);
      } else {
        _subscribeToOrders(uid);
      }
      _subscribeToChatNotifications(uid);
    }
  }

  /// Permanently deletes the customer's account AND every piece of data
  /// linked to them. Irreversible.
  ///
  /// After this call:
  ///   • All Firestore records are gone (orders, purchase_requests,
  ///     interest_requests, chats + messages, customers/{uid} identity doc).
  ///   • The Firebase Auth account is deleted.
  ///   • Local state is cleared.
  ///   • If the same phone number is used to join again, it will be treated
  ///     as a completely new account.
  Future<void> deleteAccount() async {
    final uid = _authService.currentUser?.uid;
    final phone = _customerIdentity?.phone ?? '';

    // 1. Stop all live subscriptions before we nuke the data.
    _orderSub?.cancel();
    _orderSub = null;
    _chatSub?.cancel();
    _chatSub = null;
    _orderNotifSub?.cancel();
    _orderNotifSub = null;

    // 2. Clear local state immediately.
    setState(() {
      _cartItems.clear();
      _favourites.clear();
      _orders.clear();
      _cartLoaded = false;
    });

    // 3. Clear local cart from SharedPreferences.
    await _customerDataService.clearCart();

    // 4. Delete all Firestore records linked to this customer.
    //    Run phone-based and uid-based deletes in parallel so nothing is left
    //    behind regardless of which key a document was indexed under.
    final futures = <Future<void>>[];

    if (phone.isNotEmpty) {
      futures.addAll([
        _customerDataService.deleteOrdersByPhone(phone),
        _purchaseRequestService.deleteRequestsByPhone(phone),
        _interestService.deleteRequestsByPhone(phone),
        ChatService.instance.deleteThreadsByPhone(phone),
        _orderNotificationService.deleteByPhone(phone),
      ]);
    }
    if (uid != null) {
      futures.addAll([
        _customerDataService.deleteOrdersByUid(uid),
        _purchaseRequestService.deleteRequestsByUid(uid),
        _interestService.deleteRequestsByUid(uid),
        ChatService.instance.deleteThreadsByUid(uid),
        _orderNotificationService.deleteByUid(uid),
      ]);
    }
    await Future.wait(futures);

    // 5. Delete the customers/{uid} identity document + Firebase Auth account.
    //    This is done last so Firestore security rules (which check auth.uid)
    //    are still valid for all the deletes above.
    await _authService.deleteCurrentCustomerAccount();
    // _onAuthStateChanged fires → transitions to unauthenticated / fresh guest.
  }

  // ── Interest requests ──────────────────────────────────────────────────────

  /// Called by the "I'm Interested" button. Writes an interest_request
  /// document to Firestore, which the admin device picks up via
  /// [_subscribeToInterestRequests] and turns into a local push notification.
  ///
  /// No-op when the admin is the current user — the admin browsing their
  /// own store should not generate interest requests.
  Future<void> recordInterest({
    required String productId,
    required String productName,
  }) async {
    // Never let an admin session generate an interest request — this would
    // write to customers/{adminUid} and corrupt the admin Firestore document.
    if (isAdmin) return;
    // Ensure we have an anonymous session first.
    final user = await _authService.ensureAnonymousSession();
    await _interestService.recordInterest(
      customerId: user.uid,
      customerName: _customerIdentity?.fullName ?? 'Unknown',
      customerPhone: _customerIdentity?.phone ?? '',
      productId: productId,
      productName: productName,
    );
  }

  // ── Admin: FCM token management ────────────────────────────────────────────

  /// Fetches this device's FCM token and stores it in
  /// `config/admin_device` so it survives app restarts and is accessible
  /// even when the admin is offline.
  Future<void> _saveAdminFcmToken(String adminUid) async {
    final token = await _notificationService.getToken();
    if (token == null) return;
    try {
      await _customerDataService.saveAdminFcmToken(adminUid, token);
    } catch (_) {}

    // Refresh token when FCM rotates it — only while still admin.
    _notificationService.onTokenRefresh.listen((newToken) async {
      if (!mounted || !_authService.isAdmin) return;
      try {
        await _customerDataService.saveAdminFcmToken(adminUid, newToken);
      } catch (_) {}
    });
  }

  Future<void> _clearAdminFcmToken(String adminUid) async {
    try {
      await _customerDataService.clearAdminFcmToken(adminUid);
    } catch (_) {}
  }

  // ── Admin: interest request listener ──────────────────────────────────────

  /// Subscribes to new interest_requests from Firestore.
  /// Each newly added document triggers a local push notification.
  // ── Admin: interest request listener ──────────────────────────────────────

  // IDs we've already shown a push notification for this session.
  // Prevents re-notifying when the stream re-emits on reconnect.
  final Set<String> _notifiedRequestIds = {};

  void _subscribeToInterestRequests() {
    _interestSub?.cancel();
    _interestSub = _interestService.watchNewRequests().listen(
      (requests) async {
        for (final req in requests) {
          // Skip if we already notified for this request in this session.
          if (_notifiedRequestIds.contains(req.id)) continue;
          _notifiedRequestIds.add(req.id);
          // Show the local push notification.
          await _notificationService.showInterestNotification(
            customerName: req.customerName,
            customerPhone: req.customerPhone,
            productName: req.productName,
          );
          // Do NOT mark seen here — leaving seenByAdmin=false keeps the
          // badge count accurate until the admin opens the notification screen.
          // markSeen() is called when the admin taps the card.
        }
      },
      onError: (_) {},
    );
  }

  // IDs we've already notified for purchase requests this session.
  final Set<String> _notifiedPurchaseRequestIds = {};

  void _subscribeToPurchaseRequests() {
    _purchaseRequestSub?.cancel();
    _purchaseRequestSub =
        _purchaseRequestService.watchNewPurchaseRequests().listen(
      (requests) async {
        for (final req in requests) {
          if (_notifiedPurchaseRequestIds.contains(req.id)) continue;
          _notifiedPurchaseRequestIds.add(req.id);
          await _notificationService.showPurchaseRequestNotification(
            customerName: req.customerName,
            customerPhone: req.phone,
            productNames: req.products.map((p) => p.name).toList(),
          );
        }
      },
      onError: (_) {},
    );
  }

  // ── Customer: order status notifications ──────────────────────────────────

  /// Dedup set — prevents re-notifying if the stream re-emits on reconnect.
  final Set<String> _notifiedOrderNotifIds = {};

  void _subscribeToOrderNotifications(String customerId) {
    _orderNotifSub?.cancel();
    final phone = _customerIdentity?.phone;
    if (phone == null || phone.isEmpty) return; // no phone → no stream yet

    _orderNotifSub = _orderNotificationService.watchNewByPhone(phone).listen(
      (notifications) async {
        for (final n in notifications) {
          if (_notifiedOrderNotifIds.contains(n.id)) continue;
          _notifiedOrderNotifIds.add(n.id);
          await _notificationService.showOrderStatusNotification(
            productName: n.productName,
            status: n.status,
          );
        }
      },
      onError: (_) {},
    );
  }

  // ── Customer: chat message notifications ──────────────────────────────────

  /// Watches the customer's chat threads for new messages from admin.
  /// Only fires a notification when a thread's customerUnread count *increases*
  /// — not on first load or when the customer themselves sends a message.
  final Map<String, int> _lastKnownCustomerUnread = {};
  bool _chatSubInitialized = false;

  void _subscribeToChatNotifications(String customerId) {
    _chatSub?.cancel();
    _chatSubInitialized = false;
    _lastKnownCustomerUnread.clear();

    // Watch by phone if we have identity — phone never drifts across sessions.
    // Fall back to UID-based watch if phone isn't available yet.
    final phone = _customerIdentity?.phone;
    final stream = phone != null && phone.isNotEmpty
        ? ChatService.instance.watchCustomerThreadsByPhone(phone)
        : ChatService.instance.watchCustomerThreads(customerId);

    _chatSub = stream.listen((threads) async {
      // First emission: seed baseline counts, don't notify
      if (!_chatSubInitialized) {
        for (final t in threads) {
          _lastKnownCustomerUnread[t.id] = t.customerUnread;
        }
        _chatSubInitialized = true;
        return;
      }

      for (final thread in threads) {
        final previous = _lastKnownCustomerUnread[thread.id] ?? 0;
        if (thread.customerUnread > previous) {
          await _notificationService.showChatNotification(
            senderName: 'Neno SmartLife',
            productName: thread.productName,
            preview: thread.lastMessage,
          );
        }
        _lastKnownCustomerUnread[thread.id] = thread.customerUnread;
      }
    }, onError: (_) {});
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
      _chatSub?.cancel();
      _chatSub = null;
      _orderNotifSub?.cancel();
      _orderNotifSub = null;
      await _customerDataService.clearCart();
      return;
    }

    if (_authService.isAdmin) {
      // Snapshot the anonymous UID so we can restore the customer session
      // after the admin logs out, without creating a brand-new anonymous user.
      if (_lastCustomerUid != null) {
        _preAdminAnonymousUid = _lastCustomerUid;
      }
      setState(() {
        _authStatus = AuthStatus.admin;
        _customerIdentity = null;
      });
      // Save this device's FCM token so interest notifications reach the admin.
      _saveAdminFcmToken(user.uid);
      // Start listening for new customer interest requests.
      _subscribeToInterestRequests();
      // Start listening for new purchase requests.
      _subscribeToPurchaseRequests();
    } else {
      final identity = await _authService.fetchCustomerIdentity();
      if (!mounted) return;
      // Remember this anonymous UID so we can restore it after admin logout.
      _lastCustomerUid = user.uid;
      setState(() {
        _authStatus = AuthStatus.customer;
        _customerIdentity = identity;
      });
      // Restore per-customer data
      _subscribeToOrders(user.uid);
      if (identity != null) {
        // If we know the phone, subscribe by phone for cross-device order history
        _subscribeToOrdersByPhone(identity.phone);
        // Refresh FCM token on every login so it stays current
        final token = await _notificationService.getToken();
        if (token != null && mounted) {
          _customerDataService.saveCustomerFcmToken(user.uid, token);
        }
      }
      await _loadFavourites();
      await _loadCart();
      // Listen for admin messages and show local notifications
      _subscribeToChatNotifications(user.uid);
      // Listen for order status updates (confirmed / inDiscussion)
      _subscribeToOrderNotifications(user.uid);
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
    // Start order subscription now that we have identity — use phone so
    // orders from previous devices are also visible.
    _subscribeToOrdersByPhone(identity.phone);
    // Now that we have a phone, start listening for order status notifications.
    _subscribeToOrderNotifications(identity.uid);
    // Save this device's FCM token so admin messages can trigger notifications.
    final token = await _notificationService.getToken();
    if (token != null) {
      await _customerDataService.saveCustomerFcmToken(identity.uid, token);
    }
  }

  Future<void> signOut() async {
    // If signing out as admin, clear the stored FCM token so stale devices
    // don't receive notifications after logout.
    if (_authService.isAdmin) {
      final uid = _authService.currentUser?.uid;
      if (uid != null) await _clearAdminFcmToken(uid);
    }
    _interestSub?.cancel();
    _interestSub = null;
    _notifiedRequestIds.clear();
    _purchaseRequestSub?.cancel();
    _purchaseRequestSub = null;
    _notifiedPurchaseRequestIds.clear();
    _chatSub?.cancel();
    _chatSub = null;
    _orderNotifSub?.cancel();
    _orderNotifSub = null;
    _notifiedOrderNotifIds.clear();
    await _authService.signOut();
    // After admin signs out Firebase Auth has no current user. Re-establish
    // the anonymous customer session so the customer side of the app works
    // without creating a brand-new UID each time.
    await _authService.restoreAnonymousSession(_preAdminAnonymousUid);
    _preAdminAnonymousUid = null;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _productSub?.cancel();
    _categorySub?.cancel();
    _orderSub?.cancel();
    _interestSub?.cancel();
    _purchaseRequestSub?.cancel();
    _orderNotifSub?.cancel();
    _chatSub?.cancel();
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
