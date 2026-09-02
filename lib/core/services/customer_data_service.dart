import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/cart_item.dart';
import '../../shared/models/order.dart';
import '../../shared/models/product.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CustomerDataService
//
// Handles all per-customer persistence:
//   • Favourites  → Firestore  customers/{uid}/favourites  (array of product IDs)
//   • Cart        → shared_preferences  (JSON, device-local)
//   • Orders      → Firestore  orders  collection
// ─────────────────────────────────────────────────────────────────────────────

class CustomerDataService {
  CustomerDataService._();
  static final CustomerDataService instance = CustomerDataService._();

  final _db = FirebaseFirestore.instance;
  static const _cartKey = 'cart_items_v1';

  // ── Favourites ─────────────────────────────────────────────────────────────

  /// Overwrites the stored favourite product IDs for [uid].
  Future<void> saveFavourites(String uid, List<String> productIds) async {
    await _db.collection('customers').doc(uid).set(
      {'favouriteIds': productIds},
      SetOptions(merge: true),
    );
  }

  /// Returns the list of favourite product IDs for [uid].
  /// Returns an empty list if no document exists yet.
  Future<List<String>> loadFavouriteIds(String uid) async {
    final doc = await _db.collection('customers').doc(uid).get();
    if (!doc.exists || doc.data() == null) return [];
    final raw = doc.data()!['favouriteIds'];
    if (raw == null) return [];
    return List<String>.from(raw as List);
  }

  // ── Cart ───────────────────────────────────────────────────────────────────

  /// Persists the cart to shared_preferences as a JSON string.
  Future<void> saveCart(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, CartItem.encodeList(items));
  }

  /// Restores the cart from shared_preferences.
  /// Cross-references stored product IDs against [liveProducts] so prices and
  /// names are always current. Items whose products no longer exist are dropped.
  Future<List<CartItem>> loadCart(List<Product> liveProducts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_cartKey);
    if (encoded == null || encoded.isEmpty) return [];
    try {
      return CartItem.decodeList(encoded, liveProducts);
    } catch (_) {
      // Corrupted data — clear and start fresh
      await prefs.remove(_cartKey);
      return [];
    }
  }

  /// Clears the stored cart from shared_preferences.
  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  // ── Orders ─────────────────────────────────────────────────────────────────

  /// Writes a new order document to Firestore. Returns the saved order with
  /// the Firestore-generated ID attached.
  Future<AppOrder> createOrder(AppOrder order) async {
    final ref = await _db.collection('orders').add(order.toFirestore());
    return AppOrder(
      id: ref.id,
      customerId: order.customerId,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      items: order.items,
      purchasedAt: order.purchasedAt,
      status: order.status,
      currency: order.currency,
    );
  }

  /// Live stream of orders for [customerId], newest first.
  Stream<List<AppOrder>> watchOrders(
    String customerId,
    List<Product> liveProducts,
  ) {
    return _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppOrder.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                  liveProducts,
                ))
            .toList());
  }

  /// Live stream of ALL orders for the admin dashboard, newest first.
  Stream<List<AppOrder>> watchAllOrders(List<Product> liveProducts) {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppOrder.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                  liveProducts,
                ))
            .toList());
  }
}
