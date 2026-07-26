import '../models/product.dart';

/// Mock product catalogue for development / UI prototyping.
/// Replace with real API/Firestore data when the backend is ready.
class MockProducts {
  MockProducts._();

  static const List<Product> all = [
    // ── New products ────────────────────────────────────────────────────────
    Product(
      id: '1',
      name: 'Samsung Galaxy S24 Ultra 512GB',
      description:
          'The latest flagship from Samsung featuring advanced AI capabilities, '
          'a titanium frame, and a pro-grade 200MP camera system. Experience the '
          'peak of mobile technology.',
      price: 850000,
      originalPrice: 1050000,
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
      condition: ProductCondition.newProduct,
      specifications: {
        'Brand': 'Samsung',
        'Storage': '512GB',
        'RAM': '12GB',
        'Network': '5G',
        'Battery': '5,000 mAh',
      },
    ),
    Product(
      id: '2',
      name: 'Sony WH-1000XM5 Headphones',
      description:
          'Industry-leading noise cancellation, exceptional sound quality, '
          'and all-day comfort with up to 30-hour battery life.',
      price: 220000,
      originalPrice: 275000,
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
      condition: ProductCondition.newProduct,
      specifications: {
        'Brand': 'Sony',
        'Type': 'Over-Ear',
        'Battery': '30 hours',
        'Connectivity': 'Bluetooth 5.2',
        'ANC': 'Yes',
      },
    ),
    Product(
      id: '3',
      name: 'Apple Watch Ultra 2',
      description:
          'The ultimate sports and adventure watch. Now available in carbon '
          'neutral combinations with a brighter display.',
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
      condition: ProductCondition.newProduct,
      specifications: {
        'Brand': 'Apple',
        'Display': '49mm LTPO OLED',
        'Battery': '60 hours',
        'GPS': 'Precision Dual-Frequency',
        'Water Resistance': '100m',
      },
    ),
    Product(
      id: '4',
      name: 'Samsung 55" QLED 4K Smart TV',
      description:
          'Stunning QLED display with Quantum HDR and built-in Tizen OS. '
          'A cinematic home entertainment upgrade.',
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
      condition: ProductCondition.newProduct,
      specifications: {
        'Brand': 'Samsung',
        'Size': '55 inches',
        'Resolution': '4K UHD',
        'HDR': 'Quantum HDR',
        'Smart OS': 'Tizen',
      },
    ),
    Product(
      id: '5',
      name: 'JBL Charge 5 Bluetooth Speaker',
      description:
          'Powerful portable speaker with 20-hour battery, IP67 waterproof '
          'rating, and built-in power bank.',
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
      condition: ProductCondition.newProduct,
      specifications: {
        'Brand': 'JBL',
        'Battery': '20 hours',
        'Water Resistance': 'IP67',
        'Connectivity': 'Bluetooth 5.1',
        'Power Bank': 'Yes',
      },
    ),
    Product(
      id: '6',
      name: 'iPad Pro 12.9" M4 WiFi 256GB',
      description:
          'The most advanced iPad ever. Ultra Retina XDR OLED display, M4 chip, '
          'and Apple Pencil Pro support.',
      price: 920000,
      originalPrice: 1100000,
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
      condition: ProductCondition.newProduct,
      specifications: {
        'Brand': 'Apple',
        'Chip': 'M4',
        'Display': '12.9" OLED',
        'Storage': '256GB',
        'Connectivity': 'WiFi 6E',
      },
    ),

    // ── Refurbished products ────────────────────────────────────────────────
    Product(
      id: '7',
      name: 'iPhone 13 Pro 256GB',
      description:
          'Certified refurbished iPhone 13 Pro in excellent condition. '
          'ProMotion display, Triple camera system and 5G. Battery health ≥ 90%.',
      price: 340000,
      category: 'Phones',
      imageUrls: [
        'https://images.unsplash.com/photo-1632661674596-df8be070a5c5?w=600',
      ],
      stockStatus: 'in_stock',
      badge: '',
      addedAgo: '2 days ago',
      rating: 4.5,
      reviewCount: 67,
      colorOptions: ['#1A1A1A', '#C0C0C0', '#1B4332'],
      selectedColor: '#1A1A1A',
      condition: ProductCondition.refurbished,
      specifications: {
        'Brand': 'Apple',
        'Storage': '256GB',
        'Battery Health': '≥ 90%',
        'Network': '5G',
        'Grade': 'Grade A',
      },
    ),
    Product(
      id: '8',
      name: 'Samsung Galaxy Tab S7 WiFi',
      description:
          'Refurbished Galaxy Tab S7 with S Pen included. 11" 120Hz display, '
          'Snapdragon 865+ and DeX support. Fully tested and reset.',
      price: 195000,
      category: 'Tablets',
      imageUrls: [
        'https://images.unsplash.com/photo-1561154464-82e9adf32764?w=600',
      ],
      stockStatus: 'in_stock',
      badge: '',
      addedAgo: '4 days ago',
      rating: 4.3,
      reviewCount: 29,
      colorOptions: ['#1A1A1A', '#C0C0C0'],
      selectedColor: '#1A1A1A',
      condition: ProductCondition.refurbished,
      specifications: {
        'Brand': 'Samsung',
        'Display': '11" 120Hz',
        'Processor': 'Snapdragon 865+',
        'Storage': '128GB',
        'S Pen': 'Included',
        'Grade': 'Grade B',
      },
    ),
    Product(
      id: '9',
      name: 'Bose QuietComfort 45',
      description:
          'Refurbished Bose QC45 headphones with world-class noise cancellation. '
          'Lightly used, fully functional, cleaned and tested.',
      price: 98000,
      category: 'Headphones',
      imageUrls: [
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600',
      ],
      stockStatus: 'limited',
      badge: '',
      addedAgo: '1 week ago',
      rating: 4.4,
      reviewCount: 18,
      colorOptions: ['#1A1A1A', '#F5F0EB'],
      selectedColor: '#1A1A1A',
      condition: ProductCondition.refurbished,
      specifications: {
        'Brand': 'Bose',
        'Type': 'Over-Ear',
        'Battery': '24 hours',
        'ANC': 'Yes',
        'Grade': 'Grade A',
      },
    ),
  ];

  static List<Product> byCategory(String category) {
    if (category == 'All') return all;
    return all.where((p) => p.category == category).toList();
  }

  static const List<String> categories = [
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
