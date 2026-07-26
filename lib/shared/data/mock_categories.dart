import 'package:flutter/material.dart';
import '../models/admin_category.dart';

class MockCategories {
  MockCategories._();

  static List<AdminCategory> all = [
    AdminCategory(
      id: 'cat_1',
      name: 'Phones',
      description: 'Smartphones, feature phones and mobile accessories.',
      icon: Icons.smartphone_rounded,
      productCount: 142,
      thumbnailUrl:
          'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=400',
    ),
    AdminCategory(
      id: 'cat_2',
      name: 'Accessories',
      description: 'Cases, cables, chargers and wearable add-ons.',
      icon: Icons.cable_rounded,
      productCount: 534,
    ),
    AdminCategory(
      id: 'cat_3',
      name: 'Televisions',
      description: 'Smart TVs, QLED, OLED and home theatre systems.',
      icon: Icons.tv_rounded,
      productCount: 87,
      thumbnailUrl:
          'https://images.unsplash.com/photo-1593784991095-a205069470b6?w=400',
    ),
    AdminCategory(
      id: 'cat_4',
      name: 'Smart Watches',
      description: 'Premium wearable technology and fitness trackers.',
      icon: Icons.watch_rounded,
      productCount: 112,
      thumbnailUrl:
          'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=400',
    ),
    AdminCategory(
      id: 'cat_5',
      name: 'Bluetooth Speakers',
      description: 'Portable and home Bluetooth audio speakers.',
      icon: Icons.speaker_rounded,
      productCount: 64,
      thumbnailUrl:
          'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=400',
    ),
    AdminCategory(
      id: 'cat_6',
      name: 'Headphones',
      description: 'Over-ear, on-ear and in-ear headphones and earbuds.',
      icon: Icons.headphones_rounded,
      productCount: 205,
      thumbnailUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400',
    ),
    AdminCategory(
      id: 'cat_7',
      name: 'Tablets',
      description: 'Android tablets, iPads and e-readers.',
      icon: Icons.tablet_rounded,
      productCount: 318,
      thumbnailUrl:
          'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=400',
    ),
    AdminCategory(
      id: 'cat_8',
      name: 'Gaming',
      description: 'Consoles, controllers and gaming peripherals.',
      icon: Icons.sports_esports_rounded,
      productCount: 318,
    ),
    AdminCategory(
      id: 'cat_9',
      name: 'Others',
      description: 'Miscellaneous electronics and gadgets.',
      icon: Icons.widgets_rounded,
      productCount: 45,
    ),
  ];
}
