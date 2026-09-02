import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../routes/app_router.dart';
import '../../shared/models/admin_category.dart';
import '../../shared/models/product.dart';
import '../../shared/widgets/app_search_bar.dart';
import '../../shared/widgets/condition_badge.dart';
import '../../shared/widgets/filter_chip_row.dart';
import '../../shared/widgets/product_image.dart';
import '../../shared/widgets/product_badge.dart';
import '../../shared/widgets/stock_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CategoriesScreen — customer-facing category browser
// ─────────────────────────────────────────────────────────────────────────────

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<AdminCategory> get _filtered {
    final all = context.appState.categories;
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openCategory(AdminCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final cats = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leadingWidth: 48,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text(
                  'N',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.background,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Categories',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ─────────────────────────────────────────────────
          _buildSearchBar(),
          // ── Grid ───────────────────────────────────────────────────────
          Expanded(
            child: cats.isEmpty
                ? _buildEmpty()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: cats.length,
                    itemBuilder: (context, i) => _CategoryCard(
                      category: cats[i],
                      productCount: context.appState
                          .productsByCategory(cats[i].name)
                          .length,
                      onTap: () => _openCategory(cats[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return ColoredBox(
      color: const Color(0xFFF8F8F8),
      child: AppSearchBar(
        controller: _searchCtrl,
        hintText: 'Search categories…',
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined,
              size: 52, color: AppColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'No categories yet',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back soon.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category card — grid tile
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final AdminCategory category;
  final int productCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.productCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail / icon ───────────────────────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  category.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: category.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _iconFallback(),
                          errorWidget: (_, __, ___) => _iconFallback(),
                        )
                      : _iconFallback(),
                  // Subtle gradient overlay for readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Info ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$productCount products',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconFallback() => Container(
        color: AppColors.primary.withValues(alpha: 0.08),
        child: Center(
          child: Icon(category.icon, color: AppColors.primary, size: 40),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CategoryProductsScreen — products within a specific category
// ─────────────────────────────────────────────────────────────────────────────

class CategoryProductsScreen extends StatefulWidget {
  final AdminCategory category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  String _sortBy = 'Newest';

  static const _sortOptions = <String, String>{
    'Newest': 'Newest',
    'Price ↑': 'Price ↑',
    'Price ↓': 'Price ↓',
    'Rating': 'Rating',
  };

  List<Product> get _products {
    var list = context.appState.productsByCategory(widget.category.name);
    switch (_sortBy) {
      case 'Price ↑':
        list = [...list]..sort((a, b) => a.price.compareTo(b.price));
      case 'Price ↓':
        list = [...list]..sort((a, b) => b.price.compareTo(a.price));
      case 'Rating':
        list = [...list]..sort((a, b) => b.rating.compareTo(a.rating));
      default:
        break; // 'Newest' — keep insertion order (mock default)
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final products = _products;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: CustomScrollView(
        slivers: [
          // ── Collapsible app bar with category hero ──────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            leading: IconButton(
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary, size: 18),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHero(),
              title: Text(
                widget.category.name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
              collapseMode: CollapseMode.parallax,
            ),
          ),

          // ── Sort chips ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FilterChipRow<String>(
              items: _sortOptions,
              selected: _sortBy,
              onSelected: (v) => setState(() => _sortBy = v),
              paddingTop: 14,
              paddingBottom: 8,
            ),
          ),

          // ── Product count label ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                '${products.length} product${products.length == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),

          // ── Products list ─────────────────────────────────────────────
          products.isEmpty
              ? SliverFillRemaining(child: _buildEmpty())
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ProductCard(product: products[i]),
                      ),
                      childCount: products.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final cat = widget.category;
    return Stack(
      fit: StackFit.expand,
      children: [
        cat.thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: cat.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _iconBg(),
                errorWidget: (_, __, ___) => _iconBg(),
              )
            : _iconBg(),
        // Gradient so the pinned title remains legible
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
        ),
        // Category description in the hero
        Positioned(
          left: 16,
          right: 16,
          bottom: 48,
          child: Text(
            cat.description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _iconBg() => Container(
        color: AppColors.primary.withValues(alpha: 0.08),
        child: Center(
          child: Icon(
            widget.category.icon,
            color: AppColors.primary,
            size: 64,
          ),
        ),
      );

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.category.icon,
              size: 56, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 14),
          Text(
            'No products yet',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back soon for new arrivals.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product card — re-used inside CategoryProductsScreen
// (mirrors the card in home_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;

    return GestureDetector(
      onTap: () => AppRouter.goToProduct(context, p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Thumbnail ────────────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(14)),
              child: SizedBox(
                width: 110,
                height: 110,
                child: p.imageUrls.isNotEmpty
                    ? ProductImage(
                        url: p.imageUrls.first,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: const Color(0xFFF5F5F5),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 32,
                          color: AppColors.textMuted,
                        ),
                      ),
              ),
            ),
            // ── Details ──────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    Row(
                      children: [
                        if (p.badge.isNotEmpty) ...[
                          ProductBadge(label: p.badge),
                          const SizedBox(width: 6),
                        ],
                        ConditionBadge(condition: p.condition),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Name
                    Text(
                      p.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'FCFA ${_formatPrice(p.price)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (p.originalPrice != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            'FCFA ${_formatPrice(p.originalPrice!)}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Rating + stock
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: AppColors.starRating),
                        const SizedBox(width: 2),
                        Text(
                          p.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          ' (${p.reviewCount})',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        StockChip(stockStatus: p.stockStatus),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    // Thousands separator
    final s = price.toInt().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
