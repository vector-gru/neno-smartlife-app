// ─────────────────────────────────────────────────────────────────────────────
// ProductBroadcastService
//
// When the admin saves or updates a product, they write a lightweight doc to
// the `product_broadcasts` collection. Every customer device streams this
// collection and shows a local push notification for each new doc.
//
// Firestore schema  (collection: product_broadcasts)
// ┌──────────────────────────────────────────────────────────────────────┐
// │  productId   : String   (Firestore product document ID)              │
// │  productName : String                                                │
// │  isNew       : bool     (true = new listing, false = updated)        │
// │  category    : String                                                │
// │  createdAt   : Timestamp                                             │
// └──────────────────────────────────────────────────────────────────────┘
//
// Docs older than 30 days are ignored on the client so the stream stays
// lightweight as the collection grows.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

class ProductBroadcast {
  final String id;
  final String productId;
  final String productName;
  final bool isNew; // true = newly listed, false = updated
  final String category;
  final DateTime createdAt;

  const ProductBroadcast({
    required this.id,
    required this.productId,
    required this.productName,
    required this.isNew,
    required this.category,
    required this.createdAt,
  });

  factory ProductBroadcast.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ProductBroadcast(
      id: doc.id,
      productId: d['productId'] as String? ?? '',
      productName: d['productName'] as String? ?? '',
      isNew: d['isNew'] as bool? ?? true,
      category: d['category'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ProductBroadcastService {
  ProductBroadcastService._();
  static final ProductBroadcastService instance = ProductBroadcastService._();

  final _db = FirebaseFirestore.instance;
  static const _col = 'product_broadcasts';

  // ── Admin: write a broadcast when a product is saved ──────────────────────

  Future<void> broadcastProduct({
    required String productId,
    required String productName,
    required String category,
    required bool isNew,
  }) async {
    try {
      await _db.collection(_col).add({
        'productId': productId,
        'productName': productName,
        'isNew': isNew,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Non-fatal — notification failure should never block the save flow.
      // ignore: avoid_print
      print('[ProductBroadcastService] broadcastProduct error: $e');
    }
  }

  // ── Customer: live stream of recent broadcasts ────────────────────────────

  /// Streams broadcast docs from the last 30 days, newest first.
  /// Customers listen to this to show a local push notification.
  Stream<List<ProductBroadcast>> watchRecent() {
    final since = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 30)),
    );
    return _db
        .collection(_col)
        .where('createdAt', isGreaterThan: since)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((e) {
      // ignore: avoid_print
      print('[ProductBroadcastService] watchRecent error: $e');
    }).map((snap) => snap.docs
            .map((doc) => ProductBroadcast.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }
}
