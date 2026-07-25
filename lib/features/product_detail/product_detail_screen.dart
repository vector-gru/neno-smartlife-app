import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/models/product.dart';
import '../../shared/widgets/product_badge.dart';
import '../../shared/widgets/stock_chip.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  String _selectedColor = '';
  bool _isFavourite = false;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.product.selectedColor;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(p),
              SliverToBoxAdapter(
                child: _buildContent(p),
              ),
            ],
          ),
          // Bottom sticky buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(p),
          ),
        ],
      ),
    );
  }

  // ─── Sliver App Bar with image gallery ──────────────────────────────────────
  Widget _buildSliverAppBar(Product p) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
              )
            ],
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
        ),
      ),
      title: Text(
        '← Back to ${p.category}',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => setState(() => _isFavourite = !_isFavourite),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                )
              ],
            ),
            child: Icon(
              _isFavourite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 19,
              color: _isFavourite ? AppColors.error : AppColors.textMuted,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Main image
            if (p.imageUrls.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: p.imageUrls[_selectedImageIndex],
                  fit: BoxFit.contain,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: AppColors.shimmerBase,
                    highlightColor: AppColors.shimmerHighlight,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        size: 60, color: AppColors.textMuted),
                  ),
                ),
              ),
            // Badge
            if (p.badge.isNotEmpty)
              Positioned(
                top: 70,
                left: 16,
                child: ProductBadge(label: p.badge),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Content below app bar ──────────────────────────────────────────────────
  Widget _buildContent(Product p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail strip
          if (p.imageUrls.length > 1) _buildThumbnailStrip(p),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  p.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                // Price
                Text(
                  p.formattedPrice,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                // Rating row
                _buildRatingRow(p),
                const SizedBox(height: 14),
                // Description
                Text(
                  p.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.65,
                  ),
                ),
                // Color selector
                if (p.colorOptions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _buildColorSelector(p),
                ],
                const SizedBox(height: 20),
                // Specifications
                if (p.specifications.isNotEmpty) _buildSpecifications(p),
              ],
            ),
          ),

          // Frequently bought together
          _buildFrequentlyBought(p),
        ],
      ),
    );
  }

  Widget _buildThumbnailStrip(Product p) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: p.imageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = i == _selectedImageIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedImageIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFE0E0E0),
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: p.imageUrls[i],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: AppColors.shimmerBase,
                    highlightColor: AppColors.shimmerHighlight,
                    child: Container(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingRow(Product p) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (i) {
            final filled = i < p.rating.floor();
            final half =
                !filled && i < p.rating && p.rating - i >= 0.5;
            return Icon(
              half
                  ? Icons.star_half_rounded
                  : filled
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
              size: 18,
              color: AppColors.starRating,
            );
          }),
        ),
        const SizedBox(width: 6),
        Text(
          p.rating.toStringAsFixed(1),
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${p.reviewCount} ${AppStrings.reviews})',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const Spacer(),
        StockChip(stockStatus: p.stockStatus),
      ],
    );
  }

  Widget _buildColorSelector(Product p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.color,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: p.colorOptions.map((hex) {
            final isSelected = _selectedColor == hex;
            Color color;
            try {
              color = Color(
                  int.parse(hex.replaceFirst('#', '0xFF')));
            } catch (_) {
              color = Colors.grey;
            }
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = hex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 10),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpecifications(Product p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.keySpecs,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          child: Column(
            children: p.specifications.entries.map((e) {
              final isLast = e.key == p.specifications.keys.last;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            e.key,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.value,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequentlyBought(Product p) {
    // Show a couple of other products as "frequently bought together"
    final others = SampleProducts.all
        .where((other) => other.id != p.id)
        .take(3)
        .toList();

    if (others.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
          child: Text(
            AppStrings.frequentlyBought,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: others.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                _FrequentlyBoughtCard(product: others[i]),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBottomBar(Product p) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // I'm Interested
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.thumb_up_alt_outlined,
                  size: 18, color: AppColors.background),
              label: Text(
                AppStrings.imInterested,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Add to cart
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.shopping_cart_outlined,
                  size: 18, color: AppColors.textPrimary),
              label: Text(
                AppStrings.addToCart,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Frequently bought card ────────────────────────────────────────────────────
class _FrequentlyBoughtCard extends StatelessWidget {
  final Product product;
  const _FrequentlyBoughtCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: product.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: AppColors.shimmerBase,
                          highlightColor: AppColors.shimmerHighlight,
                          child: Container(color: Colors.white),
                        ),
                      )
                    : Container(color: const Color(0xFFEEEEEE)),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.formattedPrice,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
