import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/state/app_state.dart';
import '../../features/auth/customer_identity_sheet.dart';
import '../../shared/models/product.dart';
import '../../shared/widgets/condition_badge.dart';
import '../../shared/widgets/product_badge.dart';
import '../../shared/widgets/product_image.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.product.selectedColor;
    _startZoomHintTimer();
  }

  Future<void> _handleFavouriteTap() async {
    final state = context.appState;
    // If already a favourite, just untoggle — no identity needed to remove.
    if (state.isFavourite(widget.product.id)) {
      state.toggleFavourite(widget.product);
      return;
    }
    // Adding: require identity first.
    if (!state.hasIdentity) {
      final saved = await CustomerIdentitySheet.show(context);
      if (!saved) return;
    }
    state.toggleFavourite(widget.product);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final l10n = context.l10n;
    final isFavourite = context.appState.isFavourite(p.id);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: Colors.white,
      // ── Plain app bar — fully above the image, always visible ──────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
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
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppColors.textPrimary),
          ),
        ),
        title: Text(
          '← ${l10n.backTo} ${p.category}',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        // Favourite lives in the app bar — no longer floating over the image
        actions: [
          GestureDetector(
            onTap: _handleFavouriteTap,
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
                  ),
                ],
              ),
              child: Icon(
                isFavourite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 19,
                color: isFavourite ? AppColors.error : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Scrollable content ────────────────────────────────────────
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(p),
                  if (p.imageUrls.length > 1) _buildThumbnailStrip(p),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  _buildDetails(p, l10n),
                  _buildFrequentlyBought(p, l10n),
                ],
              ),
            ),
          ),
          // ── Sticky bottom bar ─────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(p, l10n),
          ),
        ],
      ),
    );
  }

  // ─── Image section (sits cleanly below the app bar) ─────────────────────────
  bool _zoomHintVisible = true;

  void _startZoomHintTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _zoomHintVisible = false);
    });
  }

  Widget _buildImageSection(Product p) {
    return Stack(
      children: [
        // Main image — cover fills the frame; InteractiveViewer handles zoom
        SizedBox(
          height: 300,
          width: double.infinity,
          child: ClipRect(
            child: InteractiveViewer(
              clipBehavior: Clip.hardEdge,
              minScale: 1.0,
              maxScale: 4.0,
              child: p.imageUrls.isNotEmpty
                  ? ProductImage(
                      url: p.imageUrls[_selectedImageIndex],
                      fit: BoxFit.contain,
                      errorWidget: const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            size: 60, color: AppColors.textMuted),
                      ),
                    )
                  : Container(color: const Color(0xFFF8F8F8)),
            ),
          ),
        ),
        // NEW / HOT / SALE badge — top-left
        if (p.badge.isNotEmpty)
          Positioned(
            top: 12,
            left: 12,
            child: ProductBadge(label: p.badge),
          ),
        // Zoom hint — bottom-right, fades out after 2 s
        Positioned(
          bottom: 10,
          right: 10,
          child: AnimatedOpacity(
            opacity: _zoomHintVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.zoom_in_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    'Pinch to zoom',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Thumbnail strip ─────────────────────────────────────────────────────────
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
            onTap: () => setState(() {
              _selectedImageIndex = i;
              _zoomHintVisible = true;
              _startZoomHintTimer();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: ProductImage(
                  url: p.imageUrls[i],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Details section ─────────────────────────────────────────────────────────
  Widget _buildDetails(Product p, AppLocalizations l10n) {
    return Padding(
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
          // Price + condition
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.formattedPrice,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  if (p.hasDiscount)
                    Row(
                      children: [
                        Text(
                          p.formattedOriginalPrice!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${p.discountPercent}%',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(width: 10),
              ConditionBadge(condition: p.condition),
            ],
          ),
          const SizedBox(height: 10),
          _buildRatingRow(p, l10n),
          const SizedBox(height: 14),
          Text(
            p.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          ),
          if (p.colorOptions.isNotEmpty) ...[
            const SizedBox(height: 18),
            _buildColorSelector(p, l10n),
          ],
          const SizedBox(height: 20),
          if (p.specifications.isNotEmpty) _buildSpecifications(p, l10n),
        ],
      ),
    );
  }

  Widget _buildRatingRow(Product p, AppLocalizations l10n) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (i) {
            final filled = i < p.rating.floor();
            final half = !filled && i < p.rating && p.rating - i >= 0.5;
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
          '(${p.reviewCount} ${l10n.reviews})',
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
        ),
        const Spacer(),
        StockChip(stockStatus: p.stockStatus),
      ],
    );
  }

  Widget _buildColorSelector(Product p, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.color,
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
              color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
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
                    color: isSelected ? AppColors.primary : Colors.transparent,
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

  Widget _buildSpecifications(Product p, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.keySpecs,
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

  // ─── Frequently bought together ───────────────────────────────────────────────
  Widget _buildFrequentlyBought(Product p, AppLocalizations l10n) {
    final others = context.appState.products
        .where((o) => o.id != p.id && o.category == p.category)
        .take(3)
        .toList();
    if (others.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
          child: Text(
            l10n.frequentlyBought,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 200,
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

  // ─── Sticky bottom bar ────────────────────────────────────────────────────────
  Widget _buildBottomBar(Product p, AppLocalizations l10n) {
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
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.thumb_up_alt_outlined,
                    size: 18, color: AppColors.background),
                label: Text(
                  l10n.imInterested,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.background,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.shopping_cart_outlined,
                    size: 18, color: AppColors.textPrimary),
                label: Text(
                  l10n.addToCart,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 88,
                width: double.infinity,
                child: product.imageUrls.isNotEmpty
                    ? ProductImage(
                        url: product.imageUrls.first,
                        fit: BoxFit.cover,
                      )
                    : Container(color: const Color(0xFFEEEEEE)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 3),
                  Text(
                    product.formattedPrice,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  if (product.hasDiscount)
                    Text(
                      product.formattedOriginalPrice!,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.textMuted,
                      ),
                    ),
                  const SizedBox(height: 5),
                  ConditionBadge(condition: product.condition, compact: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
