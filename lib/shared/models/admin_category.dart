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
}
