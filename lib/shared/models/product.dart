// Product domain model.
// Sample/mock data lives in lib/shared/data/mock_products.dart.

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
}
