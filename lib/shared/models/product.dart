// Product domain model.
// Sample/mock data lives in lib/shared/data/mock_products.dart.

import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductCondition { newProduct, refurbished }

class Product {
  final String id;
  final String name;
  final String description;
  final double price;

  /// The original (before-discount) price. Null means no discount is active.
  final double? originalPrice;
  final String currency;
  final String category;
  final List<String> imageUrls;
  final String stockStatus; // 'in_stock' | 'limited' | 'out_of_stock'
  final String badge; // 'NEW' | 'HOT' | 'SALE' | ''
  final String addedAgo; // e.g. 'Today', 'Yesterday', '2 days ago'
  final double rating;
  final int reviewCount;
  final List<String> colorOptions;
  final String selectedColor;
  final Map<String, String> specifications;
  final List<Product> frequentlyBoughtWith;
  final ProductCondition condition;
  final int quantity;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.currency = 'FCFA',
    required this.category,
    required this.imageUrls,
    this.stockStatus = 'in_stock',
    this.badge = '',
    this.addedAgo = 'Today',
    this.rating = 4.5,
    this.reviewCount = 0,
    this.colorOptions = const [],
    this.selectedColor = '',
    this.specifications = const {},
    this.frequentlyBoughtWith = const [],
    this.condition = ProductCondition.newProduct,
    this.quantity = 0,
  });

  bool get isNew => condition == ProductCondition.newProduct;
  bool get isRefurbished => condition == ProductCondition.refurbished;

  bool get isInStock => stockStatus == 'in_stock';
  bool get isLimitedStock => stockStatus == 'limited';
  bool get isOutOfStock => stockStatus == 'out_of_stock';

  /// True when an original price is set and is actually higher than the sale price.
  bool get hasDiscount =>
      originalPrice != null && originalPrice! > price && price > 0;

  /// Rounded percentage drop, e.g. 18. Returns 0 when no discount.
  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  String get formattedPrice {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$formatted $currency';
  }

  String? get formattedOriginalPrice {
    if (!hasDiscount) return null;
    final formatted = originalPrice!.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$formatted $currency';
  }

  // ── Firestore serialisation ─────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'currency': currency,
      'category': category,
      'imageUrls': imageUrls,
      'stockStatus': stockStatus,
      'badge': badge,
      'rating': rating,
      'reviewCount': reviewCount,
      'colorOptions': colorOptions,
      'selectedColor': selectedColor,
      'specifications': specifications,
      'condition':
          condition == ProductCondition.refurbished ? 'refurbished' : 'new',
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Product(
      id: doc.id,
      name: d['name'] as String? ?? '',
      description: d['description'] as String? ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (d['originalPrice'] as num?)?.toDouble(),
      currency: d['currency'] as String? ?? 'FCFA',
      category: d['category'] as String? ?? '',
      imageUrls: List<String>.from(d['imageUrls'] as List? ?? []),
      stockStatus: d['stockStatus'] as String? ?? 'in_stock',
      badge: d['badge'] as String? ?? '',
      rating: (d['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: d['reviewCount'] as int? ?? 0,
      colorOptions: List<String>.from(d['colorOptions'] as List? ?? []),
      selectedColor: d['selectedColor'] as String? ?? '',
      specifications: Map<String, String>.from(
        (d['specifications'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            {},
      ),
      condition: d['condition'] == 'refurbished'
          ? ProductCondition.refurbished
          : ProductCondition.newProduct,
      quantity: d['quantity'] as int? ?? 0,
    );
  }

  /// Returns a new instance with updated fields — used during admin edits
  /// before the save reaches Firestore.
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    String? currency,
    String? category,
    List<String>? imageUrls,
    String? stockStatus,
    String? badge,
    String? addedAgo,
    double? rating,
    int? reviewCount,
    List<String>? colorOptions,
    String? selectedColor,
    Map<String, String>? specifications,
    ProductCondition? condition,
    int? quantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      stockStatus: stockStatus ?? this.stockStatus,
      badge: badge ?? this.badge,
      addedAgo: addedAgo ?? this.addedAgo,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      colorOptions: colorOptions ?? this.colorOptions,
      selectedColor: selectedColor ?? this.selectedColor,
      specifications: specifications ?? this.specifications,
      condition: condition ?? this.condition,
      quantity: quantity ?? this.quantity,
    );
  }
}
