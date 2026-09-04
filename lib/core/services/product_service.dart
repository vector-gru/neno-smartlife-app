import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/product.dart';
import 'product_broadcast_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProductService
//
// All Firestore reads and writes for the products collection.
// ─────────────────────────────────────────────────────────────────────────────

class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('products');

  // ── Streams ────────────────────────────────────────────────────────────────

  /// Live stream of all products ordered by creation time (newest first).
  Stream<List<Product>> watchProducts() {
    return _col.orderBy('updatedAt', descending: true).snapshots().map((snap) =>
        snap.docs
            .map((doc) => Product.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Creates a new product document. Firestore auto-generates the ID.
  /// Returns the saved product with the generated ID attached.
  Future<Product> createProduct(Product product) async {
    final data = product.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();

    final ref = await _col.add(data);
    final saved = product.copyWith(id: ref.id);

    // Broadcast to all customer devices (non-blocking).
    if (!product.hidden) {
      unawaited(ProductBroadcastService.instance.broadcastProduct(
        productId: saved.id,
        productName: saved.name,
        category: saved.category,
        isNew: true,
      ));
    }

    return saved;
  }

  /// Overwrites an existing product document (identified by [product.id]).
  Future<void> updateProduct(Product product) async {
    await _col
        .doc(product.id)
        .set(product.toFirestore(), SetOptions(merge: true));

    // Broadcast to all customer devices only if the product is visible.
    if (!product.hidden) {
      unawaited(ProductBroadcastService.instance.broadcastProduct(
        productId: product.id,
        productName: product.name,
        category: product.category,
        isNew: false,
      ));
    }
  }

  /// Deletes a product by ID.
  Future<void> deleteProduct(String id) async {
    await _col.doc(id).delete();
  }
}
