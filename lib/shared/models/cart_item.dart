import 'dart:convert';
import 'product.dart';

/// Represents a single line-item in the shopping cart.
class CartItem {
  final Product product;
  final int quantity;

  /// Optional variant label shown below the product name (e.g. "White, 128GB").
  final String variant;

  const CartItem({
    required this.product,
    this.quantity = 1,
    this.variant = '',
  });

  CartItem copyWith({int? quantity, String? variant}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      variant: variant ?? this.variant,
    );
  }

  double get lineTotal => product.price * quantity;

  String get formattedLineTotal {
    final formatted = lineTotal.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$formatted ${product.currency}';
  }

  // ── shared_preferences serialisation ───────────────────────────────────────
  // Cart items are stored locally as a JSON array.
  // We only persist the product ID + price snapshot so cart lines are
  // always re-validated against live Firestore products on restore.

  Map<String, dynamic> toJson() => {
        'productId': product.id,
        'quantity': quantity,
        'variant': variant,
      };

  /// Reconstructs a CartItem by matching the stored productId against the
  /// provided [liveProducts] list. Returns null if the product no longer exists.
  static CartItem? fromJson(
    Map<String, dynamic> json,
    List<Product> liveProducts,
  ) {
    final id = json['productId'] as String?;
    if (id == null) return null;
    try {
      final product = liveProducts.firstWhere((p) => p.id == id);
      return CartItem(
        product: product,
        quantity: json['quantity'] as int? ?? 1,
        variant: json['variant'] as String? ?? '',
      );
    } catch (_) {
      return null; // product was deleted — drop the cart line silently
    }
  }

  static String encodeList(List<CartItem> items) =>
      jsonEncode(items.map((i) => i.toJson()).toList());

  static List<CartItem> decodeList(
    String encoded,
    List<Product> liveProducts,
  ) {
    final list = jsonDecode(encoded) as List<dynamic>;
    return list
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>, liveProducts))
        .whereType<CartItem>()
        .toList();
  }
}
