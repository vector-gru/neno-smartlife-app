import 'cart_item.dart';
import 'product.dart';

enum OrderStatus { pending, processing, completed }

/// Represents a submitted purchase request / order.
class AppOrder {
  final String id;
  final List<CartItem> items;
  final DateTime purchasedAt;
  final OrderStatus status;
  final String currency;

  const AppOrder({
    required this.id,
    required this.items,
    required this.purchasedAt,
    this.status = OrderStatus.pending,
    this.currency = 'FCFA',
  });

  double get total => items.fold(0, (sum, item) => sum + item.lineTotal);

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
}

// ─── Mock orders ──────────────────────────────────────────────────────────────
// Standalone stub products used only for order history display.
const _macbookPro = Product(
  id: 'mock-o1',
  name: 'MacBook Pro 16" M3 Max',
  description: '',
  price: 2100000,
  category: 'Laptops',
  imageUrls: [
    'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600',
  ],
);

const _appleWatchUltra = Product(
  id: 'mock-o2',
  name: 'Apple Watch Ultra 2',
  description: '',
  price: 550000,
  category: 'Smart Watches',
  imageUrls: [
    'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=600',
  ],
);

const _galaxyS24 = Product(
  id: 'mock-o3',
  name: 'Samsung Galaxy S24 Ultra',
  description: '',
  price: 850000,
  category: 'Phones',
  imageUrls: [
    'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=600',
  ],
);

const _sonyHeadphones = Product(
  id: 'mock-o4',
  name: 'Sony WH-1000XM5 Headphones',
  description: '',
  price: 220000,
  category: 'Headphones',
  imageUrls: [
    'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600',
  ],
);

class MockOrders {
  MockOrders._();

  static final List<AppOrder> all = [
    AppOrder(
      id: 'ORD-7721',
      items: [const CartItem(product: _macbookPro, quantity: 1)],
      purchasedAt: DateTime(2023, 9, 15),
      status: OrderStatus.completed,
    ),
    AppOrder(
      id: 'ORD-6504',
      items: [const CartItem(product: _appleWatchUltra, quantity: 1)],
      purchasedAt: DateTime(2023, 8, 2),
      status: OrderStatus.completed,
    ),
    AppOrder(
      id: 'ORD-8812',
      items: [const CartItem(product: _galaxyS24, quantity: 1)],
      purchasedAt: DateTime(2024, 3, 10),
      status: OrderStatus.pending,
    ),
    AppOrder(
      id: 'ORD-9001',
      items: [const CartItem(product: _sonyHeadphones, quantity: 2)],
      purchasedAt: DateTime(2024, 5, 22),
      status: OrderStatus.processing,
    ),
  ];
}
