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
}
