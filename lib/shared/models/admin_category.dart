import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A product category managed by the admin.
class AdminCategory {
  final String id;
  String name;
  String description;
  String? thumbnailUrl;
  final IconData icon;
  int productCount;

  AdminCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.productCount,
    this.thumbnailUrl,
  });

  // ── Icon name ↔ IconData mapping ───────────────────────────────────────────
  // We store icons by name string so Firestore doesn't need codePoints.

  static const _iconMap = <String, IconData>{
    'smartphone': Icons.smartphone_rounded,
    'cable': Icons.cable_rounded,
    'tv': Icons.tv_rounded,
    'watch': Icons.watch_rounded,
    'speaker': Icons.speaker_rounded,
    'headphones': Icons.headphones_rounded,
    'tablet': Icons.tablet_rounded,
    'gaming': Icons.sports_esports_rounded,
    'laptop': Icons.laptop_rounded,
    'camera': Icons.camera_alt_rounded,
    'widgets': Icons.widgets_rounded,
    'category': Icons.category_rounded,
  };

  static String _iconName(IconData icon) {
    return _iconMap.entries
        .firstWhere(
          (e) => e.value.codePoint == icon.codePoint,
          orElse: () => const MapEntry('category', Icons.category_rounded),
        )
        .key;
  }

  static IconData _iconFromName(String? name) {
    return _iconMap[name] ?? Icons.category_rounded;
  }

  // ── Firestore serialisation ─────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'thumbnailUrl': thumbnailUrl,
        'iconName': _iconName(icon),
        'productCount': productCount,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory AdminCategory.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AdminCategory(
      id: doc.id,
      name: d['name'] as String? ?? '',
      description: d['description'] as String? ?? '',
      thumbnailUrl: d['thumbnailUrl'] as String?,
      icon: _iconFromName(d['iconName'] as String?),
      productCount: d['productCount'] as int? ?? 0,
    );
  }
}
