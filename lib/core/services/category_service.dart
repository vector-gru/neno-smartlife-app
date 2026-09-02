import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/admin_category.dart';

class CategoryService {
  CategoryService._();
  static final CategoryService instance = CategoryService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('categories');

  /// Live stream of all categories ordered by name.
  Stream<List<AdminCategory>> watchCategories() {
    return _col.orderBy('name').snapshots().map((snap) => snap.docs
        .map((doc) => AdminCategory.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  Future<AdminCategory> createCategory(AdminCategory category) async {
    final data = category.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    final ref = await _col.add(data);
    category.name; // force non-null
    return AdminCategory(
      id: ref.id,
      name: category.name,
      description: category.description,
      icon: category.icon,
      productCount: category.productCount,
      thumbnailUrl: category.thumbnailUrl,
    );
  }

  Future<void> updateCategory(AdminCategory category) async {
    await _col.doc(category.id).set(
          category.toFirestore(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteCategory(String id) async {
    await _col.doc(id).delete();
  }
}
