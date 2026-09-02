import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';
import 'product.dart';

enum OrderStatus { pending, processing, completed }

/// Represents a submitted purchase request / order.
class AppOrder {
  final String id;
  final String customerId; // Firebase anonymous UID
  final String customerName;
  final String customerPhone;
  final List<CartItem> items;
  final DateTime purchasedAt;
  final OrderStatus status;
  final String currency;

  const AppOrder({
    required this.id,
    this.customerId = '',
    this.customerName = '',
    this.customerPhone = '',
    required this.items,
    required this.purchasedAt,
    this.status = OrderStatus.pending,
    this.currency = 'FCFA',
  });

  double get total => items.fold(0, (acc, item) => acc + item.lineTotal);

  String get formattedTotal {
    final formatted = total.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$formatted $currency';
  }

  /// Short human-readable date: "Sep 15, 2023"
  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = months[purchasedAt.month - 1];
    final d = purchasedAt.day.toString().padLeft(2, '0');
    return '$m $d, ${purchasedAt.year}';
  }

  /// Primary label — used as the order headline in the list.
  String get headline {
    if (items.isEmpty) return 'Order $id';
    if (items.length == 1) return items.first.product.name;
    return '${items.first.product.name} + ${items.length - 1} more';
  }

  bool get isPending => status == OrderStatus.pending;
  bool get isProcessing => status == OrderStatus.processing;
  bool get isCompleted => status == OrderStatus.completed;

  // ── Firestore serialisation ─────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items
          .map((i) => {
                'productId': i.product.id,
                'productName': i.product.name,
                'productImageUrl': i.product.imageUrls.isNotEmpty
                    ? i.product.imageUrls.first
                    : '',
                'price': i.product.price,
                'currency': i.product.currency,
                'quantity': i.quantity,
                'variant': i.variant,
              })
          .toList(),
      'total': total,
      'currency': currency,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppOrder.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    List<Product> liveProducts,
  ) {
    final d = doc.data()!;

    // Reconstruct items: prefer live product if still in catalogue,
    // otherwise use the snapshot values stored at order time.
    final rawItems = (d['items'] as List<dynamic>?) ?? [];
    final items = rawItems.map((raw) {
      final map = raw as Map<String, dynamic>;
      final productId = map['productId'] as String? ?? '';
      Product product;
      try {
        product = liveProducts.firstWhere((p) => p.id == productId);
      } catch (_) {
        // Product deleted — reconstruct a minimal Product from snapshot
        product = Product(
          id: productId,
          name: map['productName'] as String? ?? 'Deleted product',
          description: '',
          price: (map['price'] as num?)?.toDouble() ?? 0,
          currency: map['currency'] as String? ?? 'FCFA',
          category: '',
          imageUrls: [map['productImageUrl'] as String? ?? ''],
        );
      }
      return CartItem(
        product: product,
        quantity: map['quantity'] as int? ?? 1,
        variant: map['variant'] as String? ?? '',
      );
    }).toList();

    OrderStatus status;
    switch (d['status'] as String?) {
      case 'processing':
        status = OrderStatus.processing;
        break;
      case 'completed':
        status = OrderStatus.completed;
        break;
      default:
        status = OrderStatus.pending;
    }

    DateTime purchasedAt;
    final ts = d['createdAt'];
    if (ts is Timestamp) {
      purchasedAt = ts.toDate();
    } else {
      purchasedAt = DateTime.now();
    }

    return AppOrder(
      id: doc.id,
      customerId: d['customerId'] as String? ?? '',
      customerName: d['customerName'] as String? ?? '',
      customerPhone: d['customerPhone'] as String? ?? '',
      items: items,
      purchasedAt: purchasedAt,
      status: status,
      currency: d['currency'] as String? ?? 'FCFA',
    );
  }
}
