import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/data/mock_products.dart';
import '../../shared/models/product.dart';
import 'admin_edit_product_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin – Manage Products Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All Products';

  static const _filters = [
    'All Products',
    'Electronics',
    'Accessories',
  ];

  // Mutable local product list so edits are reflected immediately
  late final List<Product> _products = List.from(MockProducts.all);

  List<Product> get _filtered {
    var list = _products;
    if (_selectedFilter != 'All Products') {
      list = list.where((p) {
        switch (_selectedFilter) {
          case 'Electronics':
            return ['Phones', 'Tablets', 'Televisions', 'Smart Watches']
                .contains(p.category);
          case 'Accessories':
            return ['Headphones', 'Bluetooth Speakers'].contains(p.category);
          default:
            return true;
        }
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  void _openEdit(Product product) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminEditProductScreen(
          product: product,
          onSave: (updated) {
            setState(() {
              final i = _products.indexWhere((p) => p.id == updated.id);
              if (i >= 0) _products[i] = updated;
            });
          },
          onDelete: (id) {
            setState(() => _products.removeWhere((p) => p.id == id));
          },
        ),
      ),
    );
  }

  void _openAdd() async {
    final newProduct = Product(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      name: '',
      description: '',
      price: 0,
      category: 'Phones',
      imageUrls: [],
      stockStatus: 'in_stock',
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminEditProductScreen(
          product: newProduct,
          isNew: true,
          onSave: (created) {
            setState(() => _products.insert(0, created));
          },
          onDelete: (_) {},
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final products = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // ── App bar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child:
              Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 26),
        ),
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1511367461989-f85a21fda167?w=100',
              ),
              backgroundColor: AppColors.border,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search ───────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search products, SKUs, or categories...',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF4F4F4),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Filter chips ─────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final selected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          f,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.textOnPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 1),

          // ── Product list ─────────────────────────────────────────────────
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 52, color: AppColors.border),
                        const SizedBox(height: 12),
                        Text(
                          'No products found',
                          style: GoogleFonts.poppins(
                              fontSize: 15, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                    itemCount: products.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ProductAdminCard(
                        product: products[index],
                        onEdit: () => _openEdit(products[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Admin Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProductAdminCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;

  const _ProductAdminCard({required this.product, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final stockLabel = product.isInStock
        ? 'In Stock'
        : product.isLimitedStock
            ? 'Low Stock'
            : 'Out of Stock';
    final stockColor = product.isInStock
        ? AppColors.success
        : product.isLimitedStock
            ? AppColors.warning
            : AppColors.error;
    final stockBg = product.isInStock
        ? const Color(0xFFECFDF5)
        : product.isLimitedStock
            ? const Color(0xFFFEF9EC)
            : const Color(0xFFFEF2F2);

    final qty = product.specifications['Storage'] != null ? 142 : 56;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ────────────────────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrls.first,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _imagePlaceholder(),
                        errorWidget: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              // Stock badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: stockBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stockLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: stockColor,
                    ),
                  ),
                ),
              ),
              // Discount badge (top-right)
              if (product.hasDiscount)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '-${product.discountPercent}%',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Info ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Price row — sale + optional strikethrough
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: 6),
                            Text(
                              '\$${product.originalPrice!.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${product.discountPercent}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  'Qty: $qty',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: product.isLimitedStock
                        ? AppColors.warning
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // ── Edit button ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                height: 38,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 1.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Edit Product',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        height: 180,
        width: double.infinity,
        color: const Color(0xFFF4F4F4),
        child:
            const Icon(Icons.image_outlined, color: AppColors.border, size: 40),
      );
}
