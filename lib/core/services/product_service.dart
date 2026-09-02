import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/product.dart';

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
    return _col
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
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
    return product.copyWith(id: ref.id);
  }

  /// Overwrites an existing product document (identified by [product.id]).
  Future<void> updateProduct(Product product) async {
    await _col.doc(product.id).set(product.toFirestore(), SetOptions(merge: true));
  }

  /// Deletes a product by ID.
  Future<void> deleteProduct(String id) async {
    await _col.doc(id).delete();
  }
}
