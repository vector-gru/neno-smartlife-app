class Product {
  final String id;
  final String name;
  final String description;
  final double price;
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

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
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
  });

  String get formattedPrice {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$formatted $currency';
  }

  bool get isInStock => stockStatus == 'in_stock';
  bool get isLimitedStock => stockStatus == 'limited';
  bool get isOutOfStock => stockStatus == 'out_of_stock';
}

// ─── Sample data ───────────────────────────────────────────────────────────────
class SampleProducts {
  static final List<Product> all = [
    const Product(
      id: '1',
      name: 'Samsung Galaxy S24 Ultra 512GB',
      description:
          'The latest flagship from Samsung featuring advanced AI capabilities, a titanium frame, and a pro-grade 200MP camera system. Experience the peak of mobile technology.',
      price: 850000,
      category: 'Phones',
      imageUrls: [
        'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=600',
        'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=600',
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600',
      ],
      stockStatus: 'in_stock',
      badge: 'NEW',
      addedAgo: 'Today',
      rating: 4.8,
      reviewCount: 124,
      colorOptions: ['#C0C0C0', '#1A1A1A', '#C68B2F'],
      selectedColor: '#C0C0C0',
      specifications: {
        'Brand': 'Samsung',
        'Storage': '512GB',
        'RAM': '12GB',
        'Network': '5G',
        'Battery': '5,000 mAh',
      },
    ),
    const Product(
      id: '2',
      name: 'Sony WH-1000XM5 Headphones',
      description:
          'Industry-leading noise cancellation, exceptional sound quality, and all-day comfort with up to 30-hour battery life.',
      price: 220000,
      category: 'Headphones',
      imageUrls: [
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600',
        'https://images.unsplash.com/photo-1484704849700-f032a568e944?w=600',
      ],
      stockStatus: 'in_stock',
      badge: '',
      addedAgo: 'Yesterday',
      rating: 4.7,
      reviewCount: 89,
      colorOptions: ['#1A1A1A', '#E8E0D4'],
      selectedColor: '#1A1A1A',
      specifications: {
        'Brand': 'Sony',
        'Type': 'Over-Ear',
        'Battery': '30 hours',
        'Connectivity': 'Bluetooth 5.2',
        'ANC': 'Yes',
      },
    ),
    const Product(
      id: '3',
      name: 'Apple Watch Ultra 2',
      description:
          'The ultimate sports and adventure watch. Now available in carbon neutral combinations with a brighter display.',
      price: 550000,
      category: 'Smart Watches',
      imageUrls: [
        'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=600',
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600',
      ],
      stockStatus: 'limited',
      badge: '',
      addedAgo: '2 days ago',
      rating: 4.9,
      reviewCount: 56,
      colorOptions: ['#C0C0C0', '#1A1A1A'],
      selectedColor: '#C0C0C0',
      specifications: {
        'Brand': 'Apple',
        'Display': '49mm LTPO OLED',
        'Battery': '60 hours',
        'GPS': 'Precision Dual-Frequency',
        'Water Resistance': '100m',
      },
    ),
    const Product(
      id: '4',
      name: 'Samsung 55" QLED 4K Smart TV',
      description:
          'Stunning QLED display with Quantum HDR and built-in Tizen OS. A cinematic home entertainment upgrade.',
      price: 680000,
      category: 'Televisions',
      imageUrls: [
        'https://images.unsplash.com/photo-1593784991095-a205069470b6?w=600',
      ],
      stockStatus: 'in_stock',
      badge: 'HOT',
      addedAgo: '3 days ago',
      rating: 4.6,
      reviewCount: 34,
      specifications: {
        'Brand': 'Samsung',
        'Size': '55 inches',
        'Resolution': '4K UHD',
        'HDR': 'Quantum HDR',
        'Smart OS': 'Tizen',
      },
    ),
    const Product(
      id: '5',
      name: 'JBL Charge 5 Bluetooth Speaker',
      description:
          'Powerful portable speaker with 20-hour battery, IP67 waterproof rating, and built-in power bank.',
      price: 115000,
      category: 'Bluetooth Speakers',
      imageUrls: [
        'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=600',
      ],
      stockStatus: 'in_stock',
      badge: '',
      addedAgo: '1 week ago',
      rating: 4.5,
      reviewCount: 210,
      colorOptions: ['#1A1A1A', '#C0392B', '#2980B9', '#27AE60'],
      selectedColor: '#1A1A1A',
      specifications: {
        'Brand': 'JBL',
        'Battery': '20 hours',
        'Water Resistance': 'IP67',
        'Connectivity': 'Bluetooth 5.1',
        'Power Bank': 'Yes',
      },
    ),
    const Product(
      id: '6',
      name: 'iPad Pro 12.9" M4 WiFi 256GB',
      description:
          'The most advanced iPad ever. Ultra Retina XDR OLED display, M4 chip, and Apple Pencil Pro support.',
      price: 920000,
      category: 'Tablets',
      imageUrls: [
        'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=600',
      ],
      stockStatus: 'limited',
      badge: 'NEW',
      addedAgo: '5 days ago',
      rating: 4.9,
      reviewCount: 41,
      colorOptions: ['#E0E0E0', '#1A1A1A'],
      selectedColor: '#E0E0E0',
      specifications: {
        'Brand': 'Apple',
        'Chip': 'M4',
        'Display': '12.9" OLED',
        'Storage': '256GB',
        'Connectivity': 'WiFi 6E',
      },
    ),
  ];

  static List<Product> byCategory(String category) {
    if (category == 'All') return all;
    return all.where((p) => p.category == category).toList();
  }

  static final List<String> categories = [
    'All',
    'Phones',
    'Accessories',
    'Televisions',
    'Headphones',
    'Smart Watches',
    'Bluetooth Speakers',
    'Tablets',
  ];
}
